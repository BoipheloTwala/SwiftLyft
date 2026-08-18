import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Call Tracker - Track API calls and performance metrics using dictionaries
/// 
/// This utility uses dictionaries (Map<String, dynamic>) to store comprehensive
/// API call metadata including request/response details, timing, and performance metrics.
class ApiCallTracker {
  // Dictionary to store all API calls
  static final Map<String, Map<String, dynamic>> _apiCalls = {};
  
  // Performance metrics dictionary
  static final Map<String, Map<String, dynamic>> _performanceMetrics = {};
  
  // Maximum number of API calls to keep in memory
  static const int _maxCallCount = 200;
  
  /// Track an API request
  /// 
  /// Returns a unique request ID for reference
  static String trackRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic body,
    String? userId,
  }) {
    final requestId = _generateRequestId();
    final timestamp = DateTime.now();
    
    // Build comprehensive request dictionary
    final requestData = <String, dynamic>{
      'requestId': requestId,
      'endpoint': endpoint,
      'method': method.toUpperCase(),
      'timestamp': timestamp.toIso8601String(),
      'timestampMs': timestamp.millisecondsSinceEpoch,
      'headers': _sanitizeHeaders(headers),
      'queryParams': queryParams,
      'body': _sanitizeBody(body),
      'userId': userId,
      'status': 'pending',
      'retryCount': 0,
    };
    
    _apiCalls[requestId] = requestData;
    
    debugPrint('🚀 API Request tracked: $requestId - $method $endpoint');
    
    return requestId;
  }
  
  /// Track an API response
  static void trackResponse({
    required String requestId,
    required int statusCode,
    Map<String, String>? headers,
    dynamic responseBody,
    String? error,
    Duration? duration,
  }) {
    final request = _apiCalls[requestId];
    if (request == null) {
      debugPrint('⚠️ Response tracked for unknown request: $requestId');
      return;
    }
    
    final responseTimestamp = DateTime.now();
    final requestTimestamp = DateTime.parse(request['timestamp'] as String);
    final actualDuration = duration ?? 
        responseTimestamp.difference(requestTimestamp);
    
    // Update request with response data
    request.addAll({
      'statusCode': statusCode,
      'responseHeaders': _sanitizeHeaders(headers),
      'responseBody': _sanitizeResponseBody(responseBody),
      'error': error,
      'duration': actualDuration.inMilliseconds,
      'durationSeconds': actualDuration.inSeconds,
      'completedAt': responseTimestamp.toIso8601String(),
      'status': statusCode >= 200 && statusCode < 300 ? 'success' : 
                statusCode >= 400 && statusCode < 500 ? 'client_error' : 
                statusCode >= 500 ? 'server_error' : 'error',
      'isSuccess': statusCode >= 200 && statusCode < 300,
      'isError': statusCode >= 400,
    });
    
    // Update performance metrics
    _updatePerformanceMetrics(request);
    
    // Limit API call log size
    if (_apiCalls.length > _maxCallCount) {
      _removeOldestApiCalls(_apiCalls.length - _maxCallCount);
    }
    
    debugPrint('📥 API Response tracked: $requestId - $statusCode (${actualDuration.inMilliseconds}ms)');
  }
  
  /// Track a failed API call
  static void trackFailure({
    required String requestId,
    required String error,
    StackTrace? stackTrace,
    Duration? duration,
  }) {
    final request = _apiCalls[requestId];
    if (request == null) {
      debugPrint('⚠️ Failure tracked for unknown request: $requestId');
      return;
    }
    
    final failureTimestamp = DateTime.now();
    final requestTimestamp = DateTime.parse(request['timestamp'] as String);
    final actualDuration = duration ?? 
        failureTimestamp.difference(requestTimestamp);
    
    request.addAll({
      'error': error,
      'stackTrace': stackTrace?.toString(),
      'duration': actualDuration.inMilliseconds,
      'durationSeconds': actualDuration.inSeconds,
      'completedAt': failureTimestamp.toIso8601String(),
      'status': 'failure',
      'statusCode': 0,
      'isSuccess': false,
      'isError': true,
    });
    
    _updatePerformanceMetrics(request);
    
    debugPrint('❌ API Failure tracked: $requestId - $error');
  }
  
  /// Track a retry attempt
  static void trackRetry({
    required String requestId,
    int retryAttempt = 1,
  }) {
    final request = _apiCalls[requestId];
    if (request != null) {
      request['retryCount'] = (request['retryCount'] as int) + retryAttempt;
      request['lastRetryAt'] = DateTime.now().toIso8601String();
      debugPrint('🔄 API Retry tracked: $requestId (attempt ${request['retryCount']})');
    }
  }
  
  /// Get API call by ID
  static Map<String, dynamic>? getApiCall(String requestId) {
    return _apiCalls[requestId]?.map((key, value) => MapEntry(key, value));
  }
  
  /// Get all API calls
  static Map<String, Map<String, dynamic>> getAllApiCalls() {
    return Map.unmodifiable(_apiCalls);
  }
  
  /// Get API calls by endpoint
  static List<Map<String, dynamic>> getCallsByEndpoint(String endpoint) {
    return _apiCalls.values
        .where((call) => call['endpoint'] == endpoint)
        .map((call) => Map<String, dynamic>.from(call))
        .toList()
      ..sort((a, b) => 
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }
  
  /// Get API calls by status
  static List<Map<String, dynamic>> getCallsByStatus(String status) {
    return _apiCalls.values
        .where((call) => call['status'] == status)
        .map((call) => Map<String, dynamic>.from(call))
        .toList();
  }
  
  /// Get API calls for a specific user
  static List<Map<String, dynamic>> getCallsByUser(String userId) {
    return _apiCalls.values
        .where((call) => call['userId'] == userId)
        .map((call) => Map<String, dynamic>.from(call))
        .toList();
  }
  
  /// Get performance metrics
  static Map<String, dynamic> getPerformanceMetrics() {
    return Map.unmodifiable(_performanceMetrics);
  }
  
  /// Get performance metrics for a specific endpoint
  static Map<String, dynamic>? getEndpointMetrics(String endpoint) {
    return _performanceMetrics[endpoint]?.map((key, value) => MapEntry(key, value));
  }
  
  /// Get API statistics summary
  static Map<String, dynamic> getApiSummary() {
    final completedCalls = _apiCalls.values
        .where((call) => call['status'] != 'pending')
        .toList();
    
    if (completedCalls.isEmpty) {
      return {
        'totalCalls': _apiCalls.length,
        'pendingCalls': _apiCalls.length,
      };
    }
    
    final successfulCalls = completedCalls.where((call) => call['isSuccess'] == true).length;
    final failedCalls = completedCalls.where((call) => call['isError'] == true).length;
    
    final durations = completedCalls
        .where((call) => call['duration'] != null)
        .map((call) => call['duration'] as int)
        .toList();
    
    final summary = <String, dynamic>{
      'totalCalls': _apiCalls.length,
      'completedCalls': completedCalls.length,
      'pendingCalls': _apiCalls.length - completedCalls.length,
      'successfulCalls': successfulCalls,
      'failedCalls': failedCalls,
      'successRate': successfulCalls / completedCalls.length,
      'failureRate': failedCalls / completedCalls.length,
    };
    
    if (durations.isNotEmpty) {
      durations.sort();
      summary['avgResponseTime'] = durations.reduce((a, b) => a + b) / durations.length;
      summary['minResponseTime'] = durations.first;
      summary['maxResponseTime'] = durations.last;
      summary['medianResponseTime'] = durations[durations.length ~/ 2];
    }
    
    // Add endpoint-specific statistics
    final endpointStats = <String, Map<String, dynamic>>{};
    _apiCalls.values.forEach((call) {
      final endpoint = call['endpoint'] as String;
      if (!endpointStats.containsKey(endpoint)) {
        endpointStats[endpoint] = {
          'total': 0,
          'success': 0,
          'failed': 0,
          'durations': <int>[],
        };
      }
      
      final stats = endpointStats[endpoint]!;
      stats['total'] = (stats['total'] as int) + 1;
      
      if (call['isSuccess'] == true) {
        stats['success'] = (stats['success'] as int) + 1;
      } else if (call['isError'] == true) {
        stats['failed'] = (stats['failed'] as int) + 1;
      }
      
      if (call['duration'] != null) {
        (stats['durations'] as List<int>).add(call['duration'] as int);
      }
    });
    
    // Calculate averages for each endpoint
    endpointStats.forEach((endpoint, stats) {
      final durations = stats['durations'] as List<int>;
      if (durations.isNotEmpty) {
        durations.sort();
        stats['avgResponseTime'] = durations.reduce((a, b) => a + b) / durations.length;
        stats['minResponseTime'] = durations.first;
        stats['maxResponseTime'] = durations.last;
        stats['medianResponseTime'] = durations[durations.length ~/ 2];
        stats.remove('durations');
      }
      stats['successRate'] = (stats['success'] as int) / (stats['total'] as int);
    });
    
    summary['endpointStatistics'] = endpointStats;
    summary['recentCalls'] = _getRecentCalls(10);
    summary['slowestCalls'] = _getSlowestCalls(10);
    
    return summary;
  }
  
  /// Get recent API calls (most recent first)
  static List<Map<String, dynamic>> getRecentCalls(int count) {
    return _getRecentCalls(count);
  }
  
  /// Get slowest API calls
  static List<Map<String, dynamic>> getSlowestCalls(int count) {
    return _getSlowestCalls(count);
  }
  
  /// Get failed API calls
  static List<Map<String, dynamic>> getFailedCalls() {
    return _apiCalls.values
        .where((call) => call['isError'] == true)
        .map((call) => Map<String, dynamic>.from(call))
        .toList()
      ..sort((a, b) => 
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }
  
  /// Get API calls within a time range
  static List<Map<String, dynamic>> getCallsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _apiCalls.values
        .where((call) {
          final timestamp = DateTime.parse(call['timestamp'] as String);
          return timestamp.isAfter(start) && timestamp.isBefore(end);
        })
        .map((call) => Map<String, dynamic>.from(call))
        .toList()
      ..sort((a, b) => 
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }
  
  /// Clear all API calls
  static void clearAll() {
    _apiCalls.clear();
    _performanceMetrics.clear();
    debugPrint('🧹 All API calls cleared');
  }
  
  /// Remove oldest API calls (internal helper)
  static void _removeOldestApiCalls(int count) {
    if (count <= 0 || _apiCalls.isEmpty) return;
    
    final sortedCalls = _apiCalls.entries.toList()
      ..sort((a, b) => 
          (a.value['timestamp'] as String).compareTo(b.value['timestamp'] as String));
    
    final endpointsToUpdate = <String>{};
    
    for (int i = 0; i < count && i < sortedCalls.length; i++) {
      final entry = sortedCalls[i];
      final endpoint = entry.value['endpoint'] as String;
      endpointsToUpdate.add(endpoint);
      _apiCalls.remove(entry.key);
    }
    
    // Update metrics for affected endpoints
    for (final endpoint in endpointsToUpdate) {
      _updateEndpointMetricsAfterRemoval(endpoint);
    }
    
    debugPrint('🧹 Removed $count oldest API calls');
  }
  
  /// Clear API calls older than specified duration
  static void clearOldCalls(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    final toRemove = <String>[];
    
    _apiCalls.forEach((id, call) {
      final timestamp = DateTime.parse(call['timestamp'] as String);
      if (timestamp.isBefore(cutoff)) {
        toRemove.add(id);
        final endpoint = call['endpoint'] as String;
        if (_performanceMetrics.containsKey(endpoint)) {
          _updateEndpointMetricsAfterRemoval(endpoint);
        }
      }
    });
    
    toRemove.forEach((id) => _apiCalls.remove(id));
    debugPrint('🧹 Cleared ${toRemove.length} old API calls');
  }
  
  /// Export API calls as JSON
  static String exportApiCallsAsJson() {
    return jsonEncode({
      'apiCalls': _apiCalls,
      'performanceMetrics': _performanceMetrics,
      'statistics': getApiSummary(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get recent calls (internal helper)
  static List<Map<String, dynamic>> _getRecentCalls(int count) {
    final calls = _apiCalls.values.toList()
      ..sort((a, b) => 
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    
    return calls
        .take(count)
        .map((call) => Map<String, dynamic>.from(call))
        .toList();
  }
  
  /// Get slowest calls (internal helper)
  static List<Map<String, dynamic>> _getSlowestCalls(int count) {
    final calls = _apiCalls.values
        .where((call) => call['duration'] != null)
        .toList()
      ..sort((a, b) => 
          (b['duration'] as int).compareTo(a['duration'] as int));
    
    return calls
        .take(count)
        .map((call) => Map<String, dynamic>.from(call))
        .toList();
  }
  
  /// Update performance metrics for an endpoint
  static void _updatePerformanceMetrics(Map<String, dynamic> request) {
    final endpoint = request['endpoint'] as String;
    
    if (!_performanceMetrics.containsKey(endpoint)) {
      _performanceMetrics[endpoint] = {
        'totalCalls': 0,
        'successfulCalls': 0,
        'failedCalls': 0,
        'totalDuration': 0,
        'minDuration': null,
        'maxDuration': null,
        'durations': <int>[],
      };
    }
    
    final metrics = _performanceMetrics[endpoint]!;
    metrics['totalCalls'] = (metrics['totalCalls'] as int) + 1;
    
    if (request['isSuccess'] == true) {
      metrics['successfulCalls'] = (metrics['successfulCalls'] as int) + 1;
    } else if (request['isError'] == true) {
      metrics['failedCalls'] = (metrics['failedCalls'] as int) + 1;
    }
    
    if (request['duration'] != null) {
      final duration = request['duration'] as int;
      metrics['totalDuration'] = (metrics['totalDuration'] as int) + duration;
      (metrics['durations'] as List<int>).add(duration);
      
      // Keep only last 100 durations per endpoint
      if ((metrics['durations'] as List<int>).length > 100) {
        (metrics['durations'] as List<int>).removeAt(0);
      }
      
      final currentMin = metrics['minDuration'] as int?;
      if (currentMin == null || duration < currentMin) {
        metrics['minDuration'] = duration;
      }
      final currentMax = metrics['maxDuration'] as int?;
      if (currentMax == null || duration > currentMax) {
        metrics['maxDuration'] = duration;
      }
    }
  }
  
  /// Update endpoint metrics after removal (cleanup)
  static void _updateEndpointMetricsAfterRemoval(String endpoint) {
    final endpointCalls = _apiCalls.values
        .where((call) => call['endpoint'] == endpoint)
        .toList();
    
    if (endpointCalls.isEmpty && _performanceMetrics.containsKey(endpoint)) {
      _performanceMetrics.remove(endpoint);
      return;
    }
    
    final metrics = _performanceMetrics[endpoint]!;
    metrics['totalCalls'] = endpointCalls.length;
    metrics['successfulCalls'] = endpointCalls.where((c) => c['isSuccess'] == true).length;
    metrics['failedCalls'] = endpointCalls.where((c) => c['isError'] == true).length;
    
    final durations = endpointCalls
        .where((call) => call['duration'] != null)
        .map((call) => call['duration'] as int)
        .toList();
    
    if (durations.isNotEmpty) {
      durations.sort();
      metrics['totalDuration'] = durations.reduce((a, b) => a + b);
      metrics['minDuration'] = durations.first;
      metrics['maxDuration'] = durations.last;
      metrics['durations'] = durations.take(100).toList();
    }
  }
  
  /// Sanitize headers (remove sensitive information)
  static Map<String, String>? _sanitizeHeaders(Map<String, String>? headers) {
    if (headers == null) return null;
    
    final sanitized = Map<String, String>.from(headers);
    final sensitiveKeys = ['authorization', 'api-key', 'x-api-key', 'cookie'];
    
    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '***REDACTED***';
      }
    }
    
    return sanitized;
  }
  
  /// Sanitize request body (remove sensitive information)
  static dynamic _sanitizeBody(dynamic body) {
    if (body == null) return null;
    
    if (body is Map<String, dynamic>) {
      final sanitized = Map<String, dynamic>.from(body);
      final sensitiveKeys = ['password', 'token', 'accessToken', 'refreshToken'];
      
      for (final key in sensitiveKeys) {
        if (sanitized.containsKey(key)) {
          sanitized[key] = '***REDACTED***';
        }
      }
      
      return sanitized;
    }
    
    return body;
  }
  
  /// Sanitize response body (limit size)
  static dynamic _sanitizeResponseBody(dynamic body) {
    if (body == null) return null;
    
    if (body is String && body.length > 1000) {
      return '${body.substring(0, 1000)}... (truncated)';
    }
    
    return body;
  }
  
  /// Generate unique request ID
  static String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${_apiCalls.length + 1}';
  }
}

