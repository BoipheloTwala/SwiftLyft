import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import 'notification_service.dart';
import 'trip_notification_service.dart';

/// Manager for trip status notifications
class TripNotificationManager {
  static final TripNotificationManager _instance = TripNotificationManager._internal();
  factory TripNotificationManager() => _instance;

  final NotificationService _notificationService = NotificationService();
  final TripNotificationService _tripNotificationService = TripNotificationService();
  
  StreamSubscription<TripNotification>? _notificationSubscription;
  bool _isEnabled = true;
  
  // Notification preferences
  final Map<String, bool> _preferences = {
    'driver_assigned': true,
    'driver_arrived': true,
    'trip_started': true,
    'trip_completed': true,
    'eta_alerts': true,
    'payment_updates': true,
    'promotional': false,
  };

  TripNotificationManager._internal();

  /// Initialize the notification manager
  Future<void> initialize() async {
    debugPrint('🔔 Initializing trip notification manager');
    
    // Initialize notification service
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    
    // Listen to trip notifications
    _notificationSubscription = Stream<TripNotification>.empty().listen(null);
    _tripNotificationService.addListener(_handleTripNotification);
    
    debugPrint('✅ Trip notification manager initialized');
  }

  /// Handle trip notification
  void _handleTripNotification(TripNotification notification) {
    if (!_isEnabled) return;
    
    // Check if notification type is enabled
    if (!_isNotificationTypeEnabled(notification.milestone)) {
      debugPrint('🔕 Notification type disabled: ${notification.milestone}');
      return;
    }
    
    // Send push notification
    _sendPushNotification(notification);
  }

  /// Send push notification
  Future<void> _sendPushNotification(TripNotification notification) async {
    final notificationId = notification.bookingId.hashCode;
    
    await _notificationService.showNotification(
      id: notificationId,
      title: notification.title,
      body: notification.message,
      payload: jsonEncode({
        'type': 'trip_update',
        'bookingId': notification.bookingId,
        'milestone': notification.milestone.toString(),
      }),
      importance: _getImportanceForMilestone(notification.milestone),
      priority: _getPriorityForMilestone(notification.milestone),
    );
  }

  /// Notify driver assigned
  Future<void> notifyDriverAssigned({
    required String bookingId,
    required String driverName,
    String? driverPhone,
    String? vehicleInfo,
    int? eta,
  }) async {
    if (!_preferences['driver_assigned']!) return;
    
    final body = eta != null
        ? '$driverName will arrive in $eta minutes. $vehicleInfo'
        : 'Your driver $driverName is on the way. $vehicleInfo';
    
    await _notificationService.showNotification(
      id: bookingId.hashCode,
      title: '🚗 Driver Assigned',
      body: body,
      payload: jsonEncode({
        'type': 'driver_assigned',
        'bookingId': bookingId,
      }),
      importance: NotificationImportance.high,
      priority: NotificationPriority.high,
      channelId: 'trip_updates',
      channelName: 'Trip Updates',
    );
  }

  /// Notify driver arriving
  Future<void> notifyDriverArriving({
    required String bookingId,
    required int eta,
  }) async {
    if (!_preferences['eta_alerts']!) return;
    
    await _notificationService.showNotification(
      id: bookingId.hashCode + 1,
      title: '⏱️ Driver Almost Here',
      body: 'Your driver will arrive in $eta minutes',
      payload: jsonEncode({
        'type': 'driver_arriving',
        'bookingId': bookingId,
      }),
      importance: NotificationImportance.high,
      priority: NotificationPriority.high,
    );
  }

  /// Notify driver arrived
  Future<void> notifyDriverArrived({
    required String bookingId,
    required String driverName,
  }) async {
    if (!_preferences['driver_arrived']!) return;
    
    await _notificationService.showNotificationWithActions(
      id: bookingId.hashCode + 2,
      title: '📍 Driver Has Arrived',
      body: '$driverName is waiting at the pickup location',
      payload: jsonEncode({
        'type': 'driver_arrived',
        'bookingId': bookingId,
      }),
      actions: [
        NotificationAction(
          id: 'call_driver',
          title: 'Call Driver',
          showsUserInterface: true,
        ),
        NotificationAction(
          id: 'view_map',
          title: 'View Map',
          showsUserInterface: true,
        ),
      ],
    );
  }

  /// Notify trip started
  Future<void> notifyTripStarted({
    required String bookingId,
    required String destination,
  }) async {
    if (!_preferences['trip_started']!) return;
    
    await _notificationService.showNotification(
      id: bookingId.hashCode + 3,
      title: '🎉 Trip Started',
      body: 'Enjoy your ride to $destination',
      payload: jsonEncode({
        'type': 'trip_started',
        'bookingId': bookingId,
      }),
      importance: NotificationImportance.defaultImportance,
      priority: NotificationPriority.defaultPriority,
    );
  }

  /// Notify trip completed
  Future<void> notifyTripCompleted({
    required String bookingId,
    required double fare,
  }) async {
    if (!_preferences['trip_completed']!) return;
    
    await _notificationService.showNotificationWithActions(
      id: bookingId.hashCode + 4,
      title: '✅ Trip Completed',
      body: 'Thank you for riding with us! Fare: R${fare.toStringAsFixed(2)}',
      payload: jsonEncode({
        'type': 'trip_completed',
        'bookingId': bookingId,
      }),
      actions: [
        NotificationAction(
          id: 'rate_trip',
          title: 'Rate Trip',
          showsUserInterface: true,
        ),
        NotificationAction(
          id: 'view_receipt',
          title: 'View Receipt',
          showsUserInterface: true,
        ),
      ],
    );
  }

  /// Notify payment processed
  Future<void> notifyPaymentProcessed({
    required String bookingId,
    required double amount,
    required String method,
  }) async {
    if (!_preferences['payment_updates']!) return;
    
    await _notificationService.showNotification(
      id: bookingId.hashCode + 5,
      title: '💳 Payment Processed',
      body: 'R${amount.toStringAsFixed(2)} charged to $method',
      payload: jsonEncode({
        'type': 'payment_processed',
        'bookingId': bookingId,
      }),
      importance: NotificationImportance.low,
      priority: NotificationPriority.low,
    );
  }

  /// Notify booking cancelled
  Future<void> notifyBookingCancelled({
    required String bookingId,
    required String reason,
    double? refundAmount,
  }) async {
    final body = refundAmount != null
        ? 'Booking cancelled. R${refundAmount.toStringAsFixed(2)} will be refunded.'
        : 'Booking cancelled: $reason';
    
    await _notificationService.showNotification(
      id: bookingId.hashCode + 6,
      title: '🚫 Booking Cancelled',
      body: body,
      payload: jsonEncode({
        'type': 'booking_cancelled',
        'bookingId': bookingId,
      }),
      importance: NotificationImportance.high,
      priority: NotificationPriority.high,
    );
  }

  /// Schedule trip reminder
  Future<void> scheduleTripReminder({
    required String bookingId,
    required DateTime pickupTime,
    required String pickupAddress,
    int reminderMinutes = 30,
  }) async {
    final reminderTime = pickupTime.subtract(Duration(minutes: reminderMinutes));
    
    // Only schedule if in the future
    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }
    
    await _notificationService.scheduleNotification(
      id: bookingId.hashCode + 100,
      title: '🔔 Upcoming Trip',
      body: 'Your trip to $pickupAddress starts in $reminderMinutes minutes',
      scheduledDate: reminderTime,
      payload: jsonEncode({
        'type': 'trip_reminder',
        'bookingId': bookingId,
      }),
    );
    
    debugPrint('📅 Trip reminder scheduled for: $reminderTime');
  }

  /// Cancel trip reminder
  Future<void> cancelTripReminder(String bookingId) async {
    await _notificationService.cancelNotification(bookingId.hashCode + 100);
  }

  /// Get notification importance for milestone
  NotificationImportance _getImportanceForMilestone(TripMilestone milestone) {
    switch (milestone) {
      case TripMilestone.driverAssigned:
      case TripMilestone.driverArrived:
        return NotificationImportance.high;
      case TripMilestone.eta5Minutes:
      case TripMilestone.eta2Minutes:
        return NotificationImportance.high;
      case TripMilestone.tripStarted:
      case TripMilestone.tripCompleted:
        return NotificationImportance.defaultImportance;
    }
  }

  /// Get notification priority for milestone
  NotificationPriority _getPriorityForMilestone(TripMilestone milestone) {
    switch (milestone) {
      case TripMilestone.driverAssigned:
      case TripMilestone.driverArrived:
        return NotificationPriority.high;
      case TripMilestone.eta5Minutes:
      case TripMilestone.eta2Minutes:
        return NotificationPriority.high;
      case TripMilestone.tripStarted:
      case TripMilestone.tripCompleted:
        return NotificationPriority.defaultPriority;
    }
  }

  /// Check if notification type is enabled
  bool _isNotificationTypeEnabled(TripMilestone milestone) {
    switch (milestone) {
      case TripMilestone.driverAssigned:
        return _preferences['driver_assigned'] ?? true;
      case TripMilestone.driverArrived:
        return _preferences['driver_arrived'] ?? true;
      case TripMilestone.tripStarted:
        return _preferences['trip_started'] ?? true;
      case TripMilestone.tripCompleted:
        return _preferences['trip_completed'] ?? true;
      case TripMilestone.eta5Minutes:
      case TripMilestone.eta2Minutes:
        return _preferences['eta_alerts'] ?? true;
    }
  }

  /// Set notification preference
  void setPreference(String key, bool value) {
    _preferences[key] = value;
    debugPrint('🔔 Notification preference updated: $key = $value');
  }

  /// Get notification preference
  bool getPreference(String key) {
    return _preferences[key] ?? true;
  }

  /// Get all preferences
  Map<String, bool> getAllPreferences() {
    return Map.from(_preferences);
  }

  /// Enable all notifications
  void enableAll() {
    _isEnabled = true;
    debugPrint('🔔 All notifications enabled');
  }

  /// Disable all notifications
  void disableAll() {
    _isEnabled = false;
    debugPrint('🔕 All notifications disabled');
  }

  /// Check if notifications are enabled
  bool get isEnabled => _isEnabled;

  /// Clear all trip notifications
  Future<void> clearAllTripNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  /// Dispose
  void dispose() {
    _notificationSubscription?.cancel();
    _tripNotificationService.removeListener(_handleTripNotification);
  }
}

