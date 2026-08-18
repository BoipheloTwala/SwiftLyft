import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_api_service.dart';
import '../services/analytics_api_service.dart';

/// Notification state management
class NotificationState extends ChangeNotifier {
  final NotificationService _notificationService;
  final AnalyticsService _analyticsService;

  NotificationState(this._notificationService, this._analyticsService);

  // State
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadNotificationCount = 0;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadNotificationCount => _unreadNotificationCount;

  Future<void> loadNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      final notifications = await _notificationService.getNotifications();
      _notifications = notifications;
      _updateUnreadCount();

      // Track successful load
      await _analyticsService.trackEvent(
        eventType: 'notifications_loaded',
        eventData: {'count': notifications.length},
      );

    } catch (e) {
      // Gracefully handle 404 (endpoint not implemented yet)
      if (e.toString().contains('Resource not found') || 
          e.toString().contains('404')) {
        debugPrint('ℹ️ Notifications endpoint not available yet');
        _notifications = []; // Set empty list instead of erroring
        _unreadNotificationCount = 0;
      } else {
        final errorMessage = 'Failed to load notifications: $e';
        _setError(errorMessage);
        debugPrint('❌ $errorMessage');
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      final notificationIndex = _notifications.indexWhere((n) => n.id == notificationId);
      if (notificationIndex != -1) {
        final updatedNotification = _notifications[notificationIndex].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _notifications[notificationIndex] = updatedNotification;
        _updateUnreadCount();
      }

      // Track notification read
      await _analyticsService.trackEvent(
        eventType: 'notification_read',
        eventData: {'notification_id': notificationId},
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');

      // Track failure
      await _analyticsService.trackEvent(
        eventType: 'notification_mark_read_failed',
        eventData: {'notification_id': notificationId, 'error': e.toString()},
      );

      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      _notifications = _notifications.map((notification) {
        return notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }).toList();

      _unreadNotificationCount = 0;

      // Track all notifications read
      await _analyticsService.trackEvent(
        eventType: 'all_notifications_read',
        eventData: {'total_count': _notifications.length},
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');

      // Track failure
      await _analyticsService.trackEvent(
        eventType: 'mark_all_notifications_read_failed',
        eventData: {'error': e.toString()},
      );

      return false;
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification); // Add to beginning
    if (!notification.isRead) {
      _unreadNotificationCount++;
    }

    // Track new notification
    _analyticsService.trackEvent(
      eventType: 'notification_received',
      eventData: {
        'notification_id': notification.id,
        'type': notification.type,
      },
    );

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadNotificationCount = _notifications.where((n) => !n.isRead).length;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }
}
