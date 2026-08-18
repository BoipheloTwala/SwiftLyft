import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../utils/api_call_tracker.dart';
import '../utils/error_tracker.dart';

/// HTTP Client with interceptors for authentication and error handling
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late http.Client _client;
  String? _accessToken;
  String? _refreshToken;

  // Token refresh callback to avoid circular dependency
  Future<String?> Function()? _onTokenRefresh;

  void setTokenRefreshCallback(Future<String?> Function() callback) {
    _onTokenRefresh = callback;
  }

  ApiClient._internal() {
    _client = InterceptedClient.build(
      interceptors: [
        AuthInterceptor(this),
        LoggingInterceptor(),
        RetryInterceptor(),
      ],
      requestTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
    );
  }

  // Token management
  void setTokens(String? accessToken, String? refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  // HTTP methods with error handling
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    final requestId = ApiCallTracker.trackRequest(
      endpoint: uri.path,
      method: 'GET',
      headers: headers,
      queryParams: uri.queryParameters.isNotEmpty 
          ? Map<String, dynamic>.from(uri.queryParameters) 
          : null,
      userId: _accessToken != null ? 'authenticated' : null,
    );
    
    final startTime = DateTime.now();
    try {
      final response = await _client.get(
        uri,
        headers: _buildHeaders(headers),
      );
      
      final duration = DateTime.now().difference(startTime);
      dynamic responseBody;
      try {
        responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        responseBody = response.body.isNotEmpty ? response.body : null;
      }
      
      ApiCallTracker.trackResponse(
        requestId: requestId,
        statusCode: response.statusCode,
        headers: response.headers,
        responseBody: responseBody,
        duration: duration,
      );
      
      return _handleResponse(response, requestId: requestId);
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      
      ApiCallTracker.trackFailure(
        requestId: requestId,
        error: e.toString(),
        stackTrace: stackTrace,
        duration: duration,
      );
      
      // Track error
      ErrorTracker.logNetworkError(
        message: e.toString(),
        endpoint: uri.path,
        method: 'GET',
        stackTrace: stackTrace,
      );
      
      throw _handleError(e);
    }
  }

  Future<http.Response> post(String url,
      {Map<String, String>? headers, dynamic body}) async {
    final uri = Uri.parse(url);
    final requestId = ApiCallTracker.trackRequest(
      endpoint: uri.path,
      method: 'POST',
      headers: headers,
      queryParams: uri.queryParameters.isNotEmpty 
          ? Map<String, dynamic>.from(uri.queryParameters) 
          : null,
      body: body,
      userId: _accessToken != null ? 'authenticated' : null,
    );
    
    final startTime = DateTime.now();
    try {
      final response = await _client.post(
        uri,
        headers: _buildHeaders(headers),
        body: jsonEncode(body),
      );
      
      final duration = DateTime.now().difference(startTime);
      dynamic responseBody;
      try {
        responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        responseBody = response.body.isNotEmpty ? response.body : null;
      }
      
      ApiCallTracker.trackResponse(
        requestId: requestId,
        statusCode: response.statusCode,
        headers: response.headers,
        responseBody: responseBody,
        duration: duration,
      );
      
      return _handleResponse(response, requestId: requestId);
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      
      ApiCallTracker.trackFailure(
        requestId: requestId,
        error: e.toString(),
        stackTrace: stackTrace,
        duration: duration,
      );
      
      // Track error
      ErrorTracker.logNetworkError(
        message: e.toString(),
        endpoint: uri.path,
        method: 'POST',
        requestData: body is Map<String, dynamic> ? body : null,
        stackTrace: stackTrace,
      );
      
      throw _handleError(e);
    }
  }

  Future<http.Response> put(String url,
      {Map<String, String>? headers, dynamic body}) async {
    final uri = Uri.parse(url);
    final requestId = ApiCallTracker.trackRequest(
      endpoint: uri.path,
      method: 'PUT',
      headers: headers,
      queryParams: uri.queryParameters.isNotEmpty 
          ? Map<String, dynamic>.from(uri.queryParameters) 
          : null,
      body: body,
      userId: _accessToken != null ? 'authenticated' : null,
    );
    
    final startTime = DateTime.now();
    try {
      final response = await _client.put(
        uri,
        headers: _buildHeaders(headers),
        body: jsonEncode(body),
      );
      
      final duration = DateTime.now().difference(startTime);
      dynamic responseBody;
      try {
        responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        responseBody = response.body.isNotEmpty ? response.body : null;
      }
      
      ApiCallTracker.trackResponse(
        requestId: requestId,
        statusCode: response.statusCode,
        headers: response.headers,
        responseBody: responseBody,
        duration: duration,
      );
      
      return _handleResponse(response, requestId: requestId);
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      
      ApiCallTracker.trackFailure(
        requestId: requestId,
        error: e.toString(),
        stackTrace: stackTrace,
        duration: duration,
      );
      
      // Track error
      ErrorTracker.logNetworkError(
        message: e.toString(),
        endpoint: uri.path,
        method: 'PUT',
        requestData: body is Map<String, dynamic> ? body : null,
        stackTrace: stackTrace,
      );
      
      throw _handleError(e);
    }
  }

  Future<http.Response> delete(String url, {Map<String, String>? headers, dynamic body}) async {
    final uri = Uri.parse(url);
    final requestId = ApiCallTracker.trackRequest(
      endpoint: uri.path,
      method: 'DELETE',
      headers: headers,
      queryParams: uri.queryParameters.isNotEmpty 
          ? Map<String, dynamic>.from(uri.queryParameters) 
          : null,
      body: body,
      userId: _accessToken != null ? 'authenticated' : null,
    );
    
    final startTime = DateTime.now();
    try {
      final request = http.Request('DELETE', uri)
        ..headers.addAll(_buildHeaders(headers));
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      final duration = DateTime.now().difference(startTime);
      dynamic responseBody;
      try {
        responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        responseBody = response.body.isNotEmpty ? response.body : null;
      }
      
      ApiCallTracker.trackResponse(
        requestId: requestId,
        statusCode: response.statusCode,
        headers: response.headers,
        responseBody: responseBody,
        duration: duration,
      );
      
      return _handleResponse(response, requestId: requestId);
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      
      ApiCallTracker.trackFailure(
        requestId: requestId,
        error: e.toString(),
        stackTrace: stackTrace,
        duration: duration,
      );
      
      // Track error
      ErrorTracker.logNetworkError(
        message: e.toString(),
        endpoint: uri.path,
        method: 'DELETE',
        requestData: body is Map<String, dynamic> ? body : null,
        stackTrace: stackTrace,
      );
      
      throw _handleError(e);
    }
  }

  Future<http.Response> patch(String url,
      {Map<String, String>? headers, dynamic body}) async {
    final uri = Uri.parse(url);
    final requestId = ApiCallTracker.trackRequest(
      endpoint: uri.path,
      method: 'PATCH',
      headers: headers,
      queryParams: uri.queryParameters.isNotEmpty 
          ? Map<String, dynamic>.from(uri.queryParameters) 
          : null,
      body: body,
      userId: _accessToken != null ? 'authenticated' : null,
    );
    
    final startTime = DateTime.now();
    try {
      // Build request similar to PUT/DELETE for better control
      final request = http.Request('PATCH', uri)
        ..headers.addAll(_buildHeaders(headers));
      
      if (body != null) {
        request.body = jsonEncode(body);
      }
      
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      final duration = DateTime.now().difference(startTime);
      dynamic responseBody;
      try {
        responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        responseBody = response.body.isNotEmpty ? response.body : null;
      }
      
      ApiCallTracker.trackResponse(
        requestId: requestId,
        statusCode: response.statusCode,
        headers: response.headers,
        responseBody: responseBody,
        duration: duration,
      );
      
      return _handleResponse(response, requestId: requestId);
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      
      ApiCallTracker.trackFailure(
        requestId: requestId,
        error: e.toString(),
        stackTrace: stackTrace,
        duration: duration,
      );
      
      // Track error
      ErrorTracker.logNetworkError(
        message: e.toString(),
        endpoint: uri.path,
        method: 'PATCH',
        requestData: body is Map<String, dynamic> ? body : null,
        stackTrace: stackTrace,
      );
      
      throw _handleError(e);
    }
  }

  Future<http.Response> uploadFile(String url, String filePath,
      {Map<String, String>? headers, String fieldName = 'file'}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ApiException(message: 'File does not exist: $filePath');
      }

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_buildHeaders(headers));
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, String> _buildHeaders(Map<String, String>? additionalHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  http.Response _handleResponse(http.Response response, {String? requestId}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 401) {
      // Unauthorized - surface backend message if present
      String msg = 'Invalid email or password';
      Map<String, dynamic>? errorData;
      try {
        final body = jsonDecode(response.body);
        errorData = body is Map<String, dynamic> ? body : null;
        if (errorData != null && errorData['message'] is String && (errorData['message'] as String).isNotEmpty) {
          msg = errorData['message'] as String;
        }
      } catch (_) {}
      
      // Track API error
      ErrorTracker.logApiError(
        message: msg,
        endpoint: response.request?.url.path ?? 'unknown',
        method: response.request?.method ?? 'UNKNOWN',
        statusCode: 401,
        responseBody: errorData,
      );
      
      throw ApiException(statusCode: 401, message: msg, data: errorData);
    } else if (response.statusCode == 403) {
      ErrorTracker.logApiError(
        message: 'Access forbidden',
        endpoint: response.request?.url.path ?? 'unknown',
        method: response.request?.method ?? 'UNKNOWN',
        statusCode: 403,
      );
      throw ForbiddenException('Access forbidden');
    } else if (response.statusCode == 404) {
      ErrorTracker.logApiError(
        message: 'Resource not found',
        endpoint: response.request?.url.path ?? 'unknown',
        method: response.request?.method ?? 'UNKNOWN',
        statusCode: 404,
      );
      throw NotFoundException('Resource not found');
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      Map<String, dynamic>? errorData;
      try {
        errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        errorData = {'rawBody': response.body};
      }
      
      final message = errorData?['message'] ?? 'Client error';
      
      // Track API error
      ErrorTracker.logApiError(
        message: message,
        endpoint: response.request?.url.path ?? 'unknown',
        method: response.request?.method ?? 'UNKNOWN',
        statusCode: response.statusCode,
        responseBody: errorData,
      );
      
      throw ApiException(
        statusCode: response.statusCode,
        message: message,
        data: errorData,
      );
    } else if (response.statusCode >= 500) {
      Map<String, dynamic>? errorData;
      try {
        errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        errorData = {'rawBody': response.body};
      }
      
      // Track API error
      ErrorTracker.logApiError(
        message: 'Server error occurred',
        endpoint: response.request?.url.path ?? 'unknown',
        method: response.request?.method ?? 'UNKNOWN',
        statusCode: response.statusCode,
        responseBody: errorData,
      );
      
      throw ServerException('Server error occurred');
    }

    return response;
  }

  Exception _handleError(dynamic error) {
    if (error is SocketException) {
      return NetworkException('Network connection error');
    } else if (error is HttpException) {
      return NetworkException('HTTP error: ${error.message}');
    } else if (error is FormatException) {
      return ApiException(message: 'Invalid response format');
    } else {
      return ApiException(message: error.toString());
    }
  }
}

/// Authentication interceptor for automatic token refresh
class AuthInterceptor extends InterceptorContract {
  final ApiClient _apiClient;

  AuthInterceptor(this._apiClient);

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    // Request interceptor - add any additional headers if needed
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async {
    if (response.statusCode == 401 && _apiClient._onTokenRefresh != null) {
      // If the 401 came from auth endpoints, let normal response handling show the backend message
      final original = response.request;
      final path = original?.url.path ?? '';
      if (path.contains('/api/auth/login') || path.contains('/api/auth/refresh-token')) {
        return response;
      }
      // Attempt to refresh token using callback
      try {
        final newToken = await _apiClient._onTokenRefresh!();
        if (newToken != null && newToken.isNotEmpty) {
          // Retry the original request with new token
          final originalRequest = response.request!;
          final newHeaders = Map<String, String>.from(originalRequest.headers);
          newHeaders['Authorization'] = 'Bearer $newToken';

          final retryRequest = http.Request(
            originalRequest.method,
            originalRequest.url,
          )
            ..headers.addAll(newHeaders);

          if (originalRequest is http.Request && originalRequest.body.isNotEmpty) {
            retryRequest.body = originalRequest.body;
          }

          // Avoid retrying login/refresh endpoints
          final retryPath = originalRequest.url.path;
          if (retryPath.contains('/api/auth/login') || retryPath.contains('/api/auth/refresh-token')) {
            throw UnauthorizedException('Authentication failed');
          }
          final newResponse = await http.Client().send(retryRequest);
          return newResponse;
        }
        // No token obtained - do not loop further; bubble 401 up
        throw UnauthorizedException('Authentication failed - token refresh unsuccessful');
      } catch (e) {
        // Suppress noisy refresh logs in UI
        // Do not attempt further retries here; return original 401 to caller
        throw UnauthorizedException('Authentication failed - token refresh unsuccessful');
      }
    }
    return response;
  }
}

/// Logging interceptor for debugging
class LoggingInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    if (kDebugMode) {
      print('🚀 API Request: ${request.method} ${request.url}');
      print('Headers: ${request.headers}');
    }
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async {
    if (kDebugMode) {
      print('📥 API Response: ${response.statusCode} ${response.request?.url}');
      if (response is http.Response) {
        print('Response body: ${response.body}');
      }
    }
    return response;
  }
}

/// Retry interceptor for failed requests
class RetryInterceptor extends InterceptorContract {
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    _retryCount = 0; // Reset retry count for new requests
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async {
    // Retry on network errors or server errors (5xx)
    if ((response.statusCode >= 500 || response.statusCode == 0) && _retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('Retrying request ($_retryCount/$_maxRetries) after ${response.statusCode} error');

      // Wait before retrying with exponential backoff
      await Future.delayed(_retryDelay * _retryCount);

      // The http_interceptor package handles the retry automatically
      // This is just for logging purposes
    }
    return response;
  }
}

/// Custom exceptions
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;

  ApiException({this.statusCode, required this.message, this.data});

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message: message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(statusCode: 401, message: message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(statusCode: 403, message: message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(statusCode: 404, message: message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(statusCode: 500, message: message);
}
