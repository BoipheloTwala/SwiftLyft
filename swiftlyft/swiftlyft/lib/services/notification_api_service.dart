import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Notification Service - handles /api/notifications/* endpoints
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final ApiClient _apiClient = ApiClient();

  NotificationService._internal();

  /// Get user notifications
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? read,
    String? type,
    DateTime? since,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (read != null) 'read': read.toString(),
        if (type != null) 'type': type,
        if (since != null) 'since': since.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/notifications';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final notifications = data['data']['notifications'] as List;
      return notifications.map((notif) => NotificationModel.fromJson(notif)).toList();
    } catch (e) {
      debugPrint('Failed to get notifications: $e');
      rethrow;
    }
  }

  /// Get notification by ID
  Future<NotificationModel> getNotification(String notificationId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/notifications/$notificationId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return NotificationModel.fromJson(data['data']['notification']);
    } catch (e) {
      debugPrint('Failed to get notification: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/notifications/$notificationId/read';
      await _apiClient.put(url);
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      rethrow;
    }
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/read';
      await _apiClient.put(url, body: {
        'notificationIds': notificationIds,
      });
    } catch (e) {
      debugPrint('Failed to mark notifications as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/read-all';
      await _apiClient.put(url);
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/notifications/$notificationId';
      await _apiClient.delete(url);
    } catch (e) {
      debugPrint('Failed to delete notification: $e');
      rethrow;
    }
  }

  /// Delete multiple notifications
  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications';
      await _apiClient.delete(url, body: {
        'notificationIds': notificationIds,
      });
    } catch (e) {
      debugPrint('Failed to delete notifications: $e');
      rethrow;
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/preferences';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return NotificationPreferences.fromJson(data['data']['preferences']);
    } catch (e) {
      debugPrint('Failed to get notification preferences: $e');
      rethrow;
    }
  }

  /// Update notification preferences
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/preferences';
      final response = await _apiClient.put(url, body: preferences.toJson());

      final data = jsonDecode(response.body);
      return NotificationPreferences.fromJson(data['data']['preferences']);
    } catch (e) {
      debugPrint('Failed to update notification preferences: $e');
      rethrow;
    }
  }

  /// Register device for push notifications
  Future<void> registerDevice({
    required String token,
    required String platform,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/register-device';
      await _apiClient.post(url, body: {
        'token': token,
        'platform': platform,
        'deviceId': deviceId,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Failed to register device: $e');
      rethrow;
    }
  }

  /// Unregister device from push notifications
  Future<void> unregisterDevice(String token) async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/unregister-device';
      await _apiClient.post(url, body: {
        'token': token,
      });
    } catch (e) {
      debugPrint('Failed to unregister device: $e');
      rethrow;
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/test';
      await _apiClient.post(url);
    } catch (e) {
      debugPrint('Failed to send test notification: $e');
      rethrow;
    }
  }

  /// Get notification statistics
  Future<NotificationStats> getStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/notifications/stats';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return NotificationStats.fromJson(data['data']['stats']);
    } catch (e) {
      debugPrint('Failed to get notification stats: $e');
      rethrow;
    }
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/notifications/$notificationId/archive';
      await _apiClient.put(url);
    } catch (e) {
      debugPrint('Failed to archive notification: $e');
      rethrow;
    }
  }

  /// Get archived notifications
  Future<List<NotificationModel>> getArchivedNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      const url = '${AppConstants.baseUrl}/api/notifications/archived';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final notifications = data['data']['notifications'] as List;
      return notifications.map((notif) => NotificationModel.fromJson(notif)).toList();
    } catch (e) {
      debugPrint('Failed to get archived notifications: $e');
      rethrow;
    }
  }

  /// Subscribe to notification topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/subscribe';
      await _apiClient.post(url, body: {
        'topic': topic,
      });
    } catch (e) {
      debugPrint('Failed to subscribe to topic: $e');
      rethrow;
    }
  }

  /// Unsubscribe from notification topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/unsubscribe';
      await _apiClient.post(url, body: {
        'topic': topic,
      });
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic: $e');
      rethrow;
    }
  }

  /// Get notification templates
  Future<List<NotificationTemplate>> getTemplates() async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/templates';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final templates = data['data']['templates'] as List;
      return templates.map((template) => NotificationTemplate.fromJson(template)).toList();
    } catch (e) {
      debugPrint('Failed to get notification templates: $e');
      rethrow;
    }
  }

  /// Create custom notification
  Future<NotificationModel> createCustomNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    DateTime? scheduledFor,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/notifications/custom';
      final response = await _apiClient.post(url, body: {
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'scheduledFor': scheduledFor?.toIso8601String(),
      });

      final jsonData = jsonDecode(response.body);
      return NotificationModel.fromJson(jsonData['data']['notification']);
    } catch (e) {
      debugPrint('Failed to create custom notification: $e');
      rethrow;
    }
  }
}
