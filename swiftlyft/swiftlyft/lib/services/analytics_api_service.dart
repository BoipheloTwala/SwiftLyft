import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/analytics.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Analytics Service - handles /api/analytics/* endpoints
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  final ApiClient _apiClient = ApiClient();

  // Rate limiting
  static const Duration _minInterval = Duration(seconds: 2); // Minimum 2 seconds between requests
  DateTime? _lastRequestTime;

  // Retry configuration for rate limiting
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 5);

  AnalyticsService._internal();

  /// Make HTTP request with retry logic for rate limiting
  Future<void> _makeRequestWithRetry(Future<void> Function() request) async {
    int attempt = 0;
    Duration delay = _initialRetryDelay;

    while (attempt < _maxRetries) {
      try {
        await request();
        return; // Success, exit retry loop
      } catch (e) {
        attempt++;

        // Check if it's a 429 (Too Many Requests) error
        if (e.toString().contains('429') || e.toString().contains('Too many requests')) {
          if (attempt < _maxRetries) {
            debugPrint('⏳ Analytics rate limited (attempt $attempt/$_maxRetries), retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
            delay *= 2; // Exponential backoff
            continue;
          } else {
            debugPrint('❌ Analytics rate limiting persists after $_maxRetries attempts, giving up');
            rethrow;
          }
        } else {
          // Not a rate limiting error, don't retry
          rethrow;
        }
      }
    }
  }

  /// Valid backend event types
  static const Set<String> _validEventTypes = {
    'app_open', 'app_close', 'booking_started', 'booking_completed',
    'payment_attempt', 'payment_success', 'payment_failed', 'quote_requested',
    'quote_accepted', 'profile_updated', 'location_search', 'driver_rated',
    'support_contacted', 'promotion_viewed', 'loyalty_used',
    'user_sign_in', 'user_sign_in_failed', 'user_sign_out', 'password_reset_requested'
  };

  /// Map frontend event types to valid backend event types
  String? _mapEventType(String eventType) {
    // If already valid, return as-is
    if (_validEventTypes.contains(eventType)) {
      return eventType;
    }

    // Map custom frontend events to backend events
    final Map<String, String> eventMapping = {
      // Booking events
      'bookings_loaded': 'app_open',
      'booking_created': 'booking_started',
      'booking_creation_failed': 'booking_started',
      'booking_status_updated': 'booking_completed',
      'booking_status_update_failed': 'booking_completed',
      'booking_cancelled': 'booking_completed',
      
      // Quote events
      'quotes_loaded': 'quote_requested',
      'quote_created': 'quote_requested',
      'quote_creation_failed': 'quote_requested',
      'quote_status_updated': 'quote_accepted',
      
      // Payment events
      'payment_methods_loaded': 'payment_attempt',
      'payment_method_added': 'payment_attempt',
      'payment_method_updated': 'payment_attempt',
      'payment_method_deleted': 'payment_attempt',
      'default_payment_method_changed': 'payment_attempt',
      
      // General events
      'vehicles_loaded': 'app_open',
      'screen_view': 'app_open',
      'user_action': 'app_open',

      // Modification requests (no direct backend type)
      'booking_modification_requested': 'support_contacted',
      'booking_modification_request_failed': 'support_contacted',
    };

    return eventMapping[eventType];
  }

  /// Track user event
  Future<void> trackEvent({
    required String eventType,
    Map<String, dynamic>? eventData,
    String? sessionId,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? location,
  }) async {
    try {
      // Rate limiting: check if we need to wait
      final now = DateTime.now();
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = now.difference(_lastRequestTime!);
        if (timeSinceLastRequest < _minInterval) {
          // Skip this request to avoid rate limiting
          debugPrint('⏱️ Skipping analytics event due to rate limiting: $eventType');
          return;
        }
      }
      _lastRequestTime = now;

      // Map to valid backend event type
      final mappedEventType = _mapEventType(eventType);

      // Skip if event type cannot be mapped
      if (mappedEventType == null) {
        debugPrint('ℹ️ Skipping unmapped analytics event: $eventType');
        return;
      }

      // Add original event type to eventData for context
      final enrichedEventData = {
        ...?eventData,
        if (mappedEventType != eventType) 'original_event_type': eventType,
      };

      // Make request with retry logic for rate limiting
      await _makeRequestWithRetry(() async {
        const url = '${AppConstants.baseUrl}/api/analytics/events';
        await _apiClient.post(url, body: {
          'eventType': mappedEventType,
          'eventData': enrichedEventData,
          'sessionId': sessionId,
          'deviceInfo': deviceInfo ?? {},
          'location': location,
        });
      });
    } catch (e) {
      // Analytics failures shouldn't break the app
      // Only log if it's not an "Invalid event type" error
      if (!e.toString().contains('Invalid event type')) {
        debugPrint('Failed to track event: $e');
      }
    }
  }

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    Map<String, dynamic>? parameters,
    Duration? timeSpent,
  }) async {
    try {
      await trackEvent(
        eventType: 'screen_view',
        eventData: {
          'screenName': screenName,
          'timeSpent': timeSpent?.inSeconds,
          ...?parameters,
        },
      );
    } catch (e) {
      debugPrint('Failed to track screen view: $e');
    }
  }

  /// Track user action
  Future<void> trackUserAction({
    required String action,
    required String screenName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await trackEvent(
        eventType: 'user_action',
        eventData: {
          'action': action,
          'screenName': screenName,
          ...?parameters,
        },
      );
    } catch (e) {
      debugPrint('Failed to track user action: $e');
    }
  }

  /// Track booking event
  Future<void> trackBookingEvent({
    required String eventType,
    String? bookingId,
    String? vehicleId,
    String? vehicleName,
    double? amount,
    String? pickupLocation,
    String? dropoffLocation,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await trackEvent(
        eventType: 'booking_event',
        eventData: {
          'bookingEventType': eventType,
          'bookingId': bookingId,
          'vehicleId': vehicleId,
          'vehicleName': vehicleName,
          'amount': amount,
          'pickupLocation': pickupLocation,
          'dropoffLocation': dropoffLocation,
          ...?additionalData,
        },
      );
    } catch (e) {
      debugPrint('Failed to track booking event: $e');
    }
  }

  /// Track payment event
  Future<void> trackPaymentEvent({
    required String eventType,
    String? paymentMethod,
    double? amount,
    String? currency,
    bool? success,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await trackEvent(
        eventType: 'payment_event',
        eventData: {
          'paymentEventType': eventType,
          'paymentMethod': paymentMethod,
          'amount': amount,
          'currency': currency ?? 'ZAR',
          'success': success,
          'errorMessage': errorMessage,
          ...?additionalData,
        },
      );
    } catch (e) {
      debugPrint('Failed to track payment event: $e');
    }
  }

  /// Track search event
  Future<void> trackSearchEvent({
    required String query,
    String? filter,
    int? resultCount,
    String? searchType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await trackEvent(
        eventType: 'search_event',
        eventData: {
          'query': query,
          'filter': filter,
          'resultCount': resultCount,
          'searchType': searchType ?? 'vehicle',
          ...?additionalData,
        },
      );
    } catch (e) {
      debugPrint('Failed to track search event: $e');
    }
  }

  /// Track error event
  Future<void> trackError({
    required String errorType,
    String? errorMessage,
    String? stackTrace,
    String? screenName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await trackEvent(
        eventType: 'error_event',
        eventData: {
          'errorType': errorType,
          'errorMessage': errorMessage,
          'stackTrace': stackTrace,
          'screenName': screenName,
          ...?additionalData,
        },
      );
    } catch (e) {
      debugPrint('Failed to track error: $e');
    }
  }

  /// Track performance metric
  Future<void> trackPerformance({
    required String metricName,
    double? value,
    String? unit,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await trackEvent(
        eventType: 'performance_metric',
        eventData: {
          'metricName': metricName,
          'value': value,
          'unit': unit,
          ...?metadata,
        },
      );
    } catch (e) {
      debugPrint('Failed to track performance metric: $e');
    }
  }

  /// Track user engagement
  Future<void> trackEngagement({
    required String engagementType,
    String? contentId,
    String? contentType,
    int? duration,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await trackEvent(
        eventType: 'engagement_event',
        eventData: {
          'engagementType': engagementType,
          'contentId': contentId,
          'contentType': contentType,
          'duration': duration,
          ...?parameters,
        },
      );
    } catch (e) {
      debugPrint('Failed to track engagement: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    String? userType,
    String? loyaltyTier,
    String? city,
    String? language,
    Map<String, dynamic>? additionalProperties,
  }) async {
    try {
      await trackEvent(
        eventType: 'user_properties',
        eventData: {
          'userId': userId,
          'userType': userType,
          'loyaltyTier': loyaltyTier,
          'city': city,
          'language': language,
          ...?additionalProperties,
        },
      );
    } catch (e) {
      debugPrint('Failed to set user properties: $e');
    }
  }

  /// Get dashboard overview
  Future<AnalyticsDashboard> getDashboard({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/analytics/dashboard';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return AnalyticsDashboard.fromJson(data['data']['dashboard']);
    } catch (e) {
      debugPrint('Failed to get analytics dashboard: $e');
      rethrow;
    }
  }

  /// Get user analytics
  Future<UserAnalytics> getUserAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/analytics/user';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return UserAnalytics.fromJson(data['data']['analytics']);
    } catch (e) {
      debugPrint('Failed to get user analytics: $e');
      rethrow;
    }
  }

  /// Get booking analytics
  Future<BookingAnalytics> getBookingAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/analytics/bookings';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return BookingAnalytics.fromJson(data['data']['analytics']);
    } catch (e) {
      debugPrint('Failed to get booking analytics: $e');
      rethrow;
    }
  }

  /// Get revenue analytics
  Future<RevenueAnalytics> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/analytics/revenue';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return RevenueAnalytics.fromJson(data['data']['analytics']);
    } catch (e) {
      debugPrint('Failed to get revenue analytics: $e');
      rethrow;
    }
  }

  /// Get driver analytics
  Future<DriverAnalytics> getDriverAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/analytics/drivers';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return DriverAnalytics.fromJson(data['data']['analytics']);
    } catch (e) {
      debugPrint('Failed to get driver analytics: $e');
      rethrow;
    }
  }

  /// Export analytics data
  Future<String> exportAnalytics({
    required String dataType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'dataType': dataType,
        'format': format,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/analytics/export';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return data['data']['downloadUrl'];
    } catch (e) {
      debugPrint('Failed to export analytics: $e');
      rethrow;
    }
  }

  /// Create custom report
  Future<CustomReport> createCustomReport({
    required String name,
    required List<String> metrics,
    required Map<String, dynamic> filters,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/analytics/reports/custom';
      final response = await _apiClient.post(url, body: {
        'name': name,
        'metrics': metrics,
        'filters': filters,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });

      final data = jsonDecode(response.body);
      return CustomReport.fromJson(data['data']['report']);
    } catch (e) {
      debugPrint('Failed to create custom report: $e');
      rethrow;
    }
  }

  /// Get custom reports
  Future<List<CustomReport>> getCustomReports() async {
    try {
      const url = '${AppConstants.baseUrl}/api/analytics/reports/custom';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final reports = data['data']['reports'] as List;
      return reports.map((report) => CustomReport.fromJson(report)).toList();
    } catch (e) {
      debugPrint('Failed to get custom reports: $e');
      rethrow;
    }
  }
}
