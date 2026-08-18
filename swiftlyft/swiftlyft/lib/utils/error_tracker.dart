import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Error Tracker - Structured error logging with context using dictionaries
/// 
/// This utility uses dictionaries (Map<String, dynamic>) to store comprehensive
/// error information including context, stack traces, user actions, and metadata.
class ErrorTracker {
  // Dictionary to store all tracked errors
  static final Map<String, Map<String, dynamic>> _errorLog = {};
  
  // Maximum number of errors to keep in memory
  static const int _maxErrorCount = 100;
  
  // Error statistics dictionary
  static final Map<String, int> _errorStats = {};
  
  /// Track an error with comprehensive context
  /// 
  /// Returns a unique error ID for reference
  static String logError({
    required String errorType,
    required String message,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
    String? screenName,
    String? userAction,
    int? statusCode,
    String? endpoint,
    dynamic originalError,
  }) {
    final errorId = _generateErrorId();
    final timestamp = DateTime.now();
    
    // Build comprehensive error dictionary
    final errorData = <String, dynamic>{
      'errorId': errorId,
      'errorType': errorType,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'timestampMs': timestamp.millisecondsSinceEpoch,
      'context': context ?? {},
      'userId': userId,
      'screenName': screenName,
      'userAction': userAction,
      'statusCode': statusCode,
      'endpoint': endpoint,
      'stackTrace': stackTrace?.toString(),
      'originalError': originalError?.toString(),
      'platform': defaultTargetPlatform.toString(),
      'occurrenceCount': 1,
      'firstOccurrence': timestamp.toIso8601String(),
      'lastOccurrence': timestamp.toIso8601String(),
    };
    
    // Check if similar error exists (same type and message)
    final similarError = _findSimilarError(errorType, message);
    if (similarError != null) {
      // Increment occurrence count
      similarError['occurrenceCount'] = (similarError['occurrenceCount'] as int) + 1;
      similarError['lastOccurrence'] = timestamp.toIso8601String();
      
      // Merge context if provided
      if (context != null && context.isNotEmpty) {
        final existingContext = similarError['context'] as Map<String, dynamic>? ?? {};
        existingContext.addAll(context);
        similarError['context'] = existingContext;
      }
      
      // Track statistics
      _errorStats[errorType] = (_errorStats[errorType] ?? 0) + 1;
      
      debugPrint('⚠️ Error tracked (duplicate): ${similarError['errorId']} - $errorType: $message');
      return similarError['errorId'] as String;
    }
    
    // Store new error
    _errorLog[errorId] = errorData;
    
    // Update statistics
    _errorStats[errorType] = (_errorStats[errorType] ?? 0) + 1;
    
    // Limit error log size
    if (_errorLog.length > _maxErrorCount) {
      _removeOldestErrors(_errorLog.length - _maxErrorCount);
    }
    
    debugPrint('❌ Error tracked: $errorId - $errorType: $message');
    
    return errorId;
  }
  
  /// Track a network-related error
  static String logNetworkError({
    required String message,
    String? endpoint,
    String? method,
    int? statusCode,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    StackTrace? stackTrace,
    String? userId,
  }) {
    return logError(
      errorType: 'NetworkError',
      message: message,
      stackTrace: stackTrace,
      context: {
        'endpoint': endpoint,
        'method': method,
        'requestData': requestData,
        'responseData': responseData,
      },
      userId: userId,
      statusCode: statusCode,
      endpoint: endpoint,
    );
  }
  
  /// Track an API error
  static String logApiError({
    required String message,
    required String endpoint,
    required String method,
    int? statusCode,
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? responseBody,
    StackTrace? stackTrace,
    String? userId,
  }) {
    return logError(
      errorType: 'ApiError',
      message: message,
      stackTrace: stackTrace,
      context: {
        'endpoint': endpoint,
        'method': method,
        'requestBody': requestBody,
        'responseBody': responseBody,
      },
      userId: userId,
      statusCode: statusCode,
      endpoint: endpoint,
    );
  }
  
  /// Track a validation error
  static String logValidationError({
    required String message,
    Map<String, dynamic>? validationErrors,
    String? screenName,
    String? formField,
    String? userId,
  }) {
    return logError(
      errorType: 'ValidationError',
      message: message,
      context: {
        'validationErrors': validationErrors,
        'formField': formField,
      },
      userId: userId,
      screenName: screenName,
    );
  }
  
  /// Track a state management error
  static String logStateError({
    required String message,
    String? providerName,
    String? stateProperty,
    StackTrace? stackTrace,
    Map<String, dynamic>? stateSnapshot,
  }) {
    return logError(
      errorType: 'StateError',
      message: message,
      stackTrace: stackTrace,
      context: {
        'providerName': providerName,
        'stateProperty': stateProperty,
        'stateSnapshot': stateSnapshot,
      },
    );
  }
  
  /// Get error by ID
  static Map<String, dynamic>? getError(String errorId) {
    return _errorLog[errorId]?.map((key, value) => MapEntry(key, value));
  }
  
  /// Get all errors
  static Map<String, Map<String, dynamic>> getAllErrors() {
    return Map.unmodifiable(_errorLog);
  }
  
  /// Get errors by type
  static List<Map<String, dynamic>> getErrorsByType(String errorType) {
    return _errorLog.values
        .where((error) => error['errorType'] == errorType)
        .map((error) => Map<String, dynamic>.from(error))
        .toList();
  }
  
  /// Get errors for a specific user
  static List<Map<String, dynamic>> getErrorsByUser(String userId) {
    return _errorLog.values
        .where((error) => error['userId'] == userId)
        .map((error) => Map<String, dynamic>.from(error))
        .toList();
  }
  
  /// Get errors for a specific screen
  static List<Map<String, dynamic>> getErrorsByScreen(String screenName) {
    return _errorLog.values
        .where((error) => error['screenName'] == screenName)
        .map((error) => Map<String, dynamic>.from(error))
        .toList();
  }
  
  /// Get error statistics summary
  static Map<String, dynamic> getErrorSummary() {
    final summary = <String, dynamic>{
      'totalErrors': _errorLog.length,
      'errorCountByType': Map<String, int>.from(_errorStats),
      'recentErrors': _getRecentErrors(10),
      'mostCommonErrors': _getMostCommonErrors(5),
    };
    
    // Calculate additional statistics
    if (_errorLog.isNotEmpty) {
      final timestamps = _errorLog.values
          .map((e) => DateTime.parse(e['timestamp'] as String))
          .toList();
      timestamps.sort();
      
      summary['firstError'] = timestamps.first.toIso8601String();
      summary['lastError'] = timestamps.last.toIso8601String();
      summary['errorRate'] = _errorLog.length / 
          (DateTime.now().difference(timestamps.first).inHours + 1);
    }
    
    return summary;
  }
  
  /// Get errors with high occurrence count (duplicate errors)
  static List<Map<String, dynamic>> getDuplicateErrors({int minOccurrences = 2}) {
    return _errorLog.values
        .where((error) => (error['occurrenceCount'] as int) >= minOccurrences)
        .map((error) => Map<String, dynamic>.from(error))
        .toList()
      ..sort((a, b) => 
          (b['occurrenceCount'] as int).compareTo(a['occurrenceCount'] as int));
  }
  
  /// Get errors within a time range
  static List<Map<String, dynamic>> getErrorsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _errorLog.values
        .where((error) {
          final timestamp = DateTime.parse(error['timestamp'] as String);
          return timestamp.isAfter(start) && timestamp.isBefore(end);
        })
        .map((error) => Map<String, dynamic>.from(error))
        .toList()
      ..sort((a, b) => 
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }
  
  /// Clear all errors
  static void clearAll() {
    _errorLog.clear();
    _errorStats.clear();
    debugPrint('🧹 All errors cleared');
  }
  
  /// Clear errors older than specified duration
  static void clearOldErrors(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    final toRemove = <String>[];
    
    _errorLog.forEach((id, error) {
      final timestamp = DateTime.parse(error['timestamp'] as String);
      if (timestamp.isBefore(cutoff)) {
        toRemove.add(id);
        final errorType = error['errorType'] as String;
        _errorStats[errorType] = (_errorStats[errorType] ?? 1) - 1;
        if (_errorStats[errorType]! <= 0) {
          _errorStats.remove(errorType);
        }
      }
    });
    
    toRemove.forEach((id) => _errorLog.remove(id));
    debugPrint('🧹 Cleared ${toRemove.length} old errors');
  }
  
  /// Export errors as JSON
  static String exportErrorsAsJson() {
    return jsonEncode({
      'errors': _errorLog,
      'statistics': getErrorSummary(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get recent errors (most recent first)
  static List<Map<String, dynamic>> _getRecentErrors(int count) {
    final errors = _errorLog.values.toList()
      ..sort((a, b) => 
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    
    return errors
        .take(count)
        .map((error) => Map<String, dynamic>.from(error))
        .toList();
  }
  
  /// Get most common errors
  static List<Map<String, dynamic>> _getMostCommonErrors(int count) {
    final errors = _errorLog.values.toList()
      ..sort((a, b) => 
          (b['occurrenceCount'] as int).compareTo(a['occurrenceCount'] as int));
    
    return errors
        .take(count)
        .map((error) => Map<String, dynamic>.from(error))
        .toList();
  }
  
  /// Find similar error (same type and message)
  static Map<String, dynamic>? _findSimilarError(String errorType, String message) {
    for (final error in _errorLog.values) {
      if (error['errorType'] == errorType && 
          error['message'] == message) {
        return error;
      }
    }
    return null;
  }
  
  /// Remove oldest errors
  static void _removeOldestErrors(int count) {
    final sortedErrors = _errorLog.entries.toList()
      ..sort((a, b) => 
          (a.value['timestamp'] as String).compareTo(b.value['timestamp'] as String));
    
    for (int i = 0; i < count && i < sortedErrors.length; i++) {
      final entry = sortedErrors[i];
      final errorType = entry.value['errorType'] as String;
      _errorStats[errorType] = (_errorStats[errorType] ?? 1) - 1;
      if (_errorStats[errorType]! <= 0) {
        _errorStats.remove(errorType);
      }
      _errorLog.remove(entry.key);
    }
  }
  
  /// Generate unique error ID
  static String _generateErrorId() {
    return 'err_${DateTime.now().millisecondsSinceEpoch}_${_errorLog.length + 1}';
  }
}

