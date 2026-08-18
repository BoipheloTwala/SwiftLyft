import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  final List<Function(String?)> _notificationTapCallbacks = [];

  NotificationService._internal();

  /// Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize with callback for when notification is tapped
      final initialized = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response.payload);
        },
      );

      _isInitialized = initialized ?? false;
      debugPrint('📬 Notification service initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
      return false;
    }
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    try {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? true; // Android doesn't need runtime permission
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
    NotificationImportance importance = NotificationImportance.defaultImportance,
    String? channelId,
    String? channelName,
    bool playSound = true,
    bool showProgress = false,
    int? progress,
    int? maxProgress,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId ?? 'trip_updates',
        channelName ?? 'Trip Updates',
        channelDescription: 'Notifications for trip status updates',
        importance: importance.toAndroidImportance(),
        priority: priority.toAndroidPriority(),
        playSound: playSound,
        showProgress: showProgress,
        progress: progress ?? 0,
        maxProgress: maxProgress ?? 100,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('📬 Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  /// Show notification with custom sound
  Future<void> showNotificationWithSound({
    required int id,
    required String title,
    required String body,
    required String soundFileName,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'trip_updates_sound',
        'Trip Updates',
        channelDescription: 'Trip notifications with sound',
        importance: NotificationImportance.high.toAndroidImportance(),
        priority: NotificationPriority.high.toAndroidPriority(),
        sound: RawResourceAndroidNotificationSound(soundFileName),
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$soundFileName.aiff',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error showing notification with sound: $e');
    }
  }

  /// Show notification with actions
  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required List<NotificationAction> actions,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'trip_actions',
        'Trip Actions',
        channelDescription: 'Notifications with actions',
        importance: NotificationImportance.high.toAndroidImportance(),
        priority: NotificationPriority.high.toAndroidPriority(),
        actions: actions
            .map((action) => AndroidNotificationAction(
                  action.id,
                  action.title,
                  showsUserInterface: action.showsUserInterface,
                ))
            .toList(),
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error showing notification with actions: $e');
    }
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'scheduled_trips',
        'Scheduled Trips',
        channelDescription: 'Scheduled trip reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert DateTime to TZDateTime
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint('📅 Notification scheduled for: $scheduledDate');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('🚫 Notification cancelled: $id');
    } catch (e) {
      debugPrint('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('🚫 All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Get active notifications
  Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.getActiveNotifications() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting active notifications: $e');
      return [];
    }
  }

  /// Add callback for when notification is tapped
  void addNotificationTapCallback(Function(String?) callback) {
    _notificationTapCallbacks.add(callback);
  }

  /// Remove notification tap callback
  void removeNotificationTapCallback(Function(String?) callback) {
    _notificationTapCallbacks.remove(callback);
  }

  /// Handle notification tap
  void _handleNotificationTap(String? payload) {
    debugPrint('📬 Notification tapped with payload: $payload');
    for (final callback in _notificationTapCallbacks) {
      callback(payload);
    }
  }

  /// Clear badge count (iOS) - Note: Not available in current version
  Future<void> clearBadge() async {
    try {
      // Badge clearing not available in current flutter_local_notifications version
      // Consider updating package or using alternative method
      debugPrint('⚠️ Badge clearing not implemented');
    } catch (e) {
      debugPrint('❌ Error clearing badge: $e');
    }
  }
}

/// Notification action model
class NotificationAction {
  final String id;
  final String title;
  final bool showsUserInterface;

  NotificationAction({
    required this.id,
    required this.title,
    this.showsUserInterface = false,
  });
}

/// Notification importance levels
enum NotificationImportance {
  min,
  low,
  defaultImportance,
  high,
  max,
}

extension NotificationImportanceExtension on NotificationImportance {
  Importance toAndroidImportance() {
    switch (this) {
      case NotificationImportance.min:
        return Importance.min;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.defaultImportance:
        return Importance.defaultImportance;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.max:
        return Importance.max;
    }
  }
}

/// Notification priority levels
enum NotificationPriority {
  min,
  low,
  defaultPriority,
  high,
  max,
}

extension NotificationPriorityExtension on NotificationPriority {
  Priority toAndroidPriority() {
    switch (this) {
      case NotificationPriority.min:
        return Priority.min;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.defaultPriority:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }
}

