import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'http_client.dart';

/// Push Notification Service - handles FCM and local notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, dynamic>> _notificationController = StreamController.broadcast();

  String? _fcmToken;
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  PushNotificationService._internal();

  /// Stream of incoming notifications
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;

  /// Current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Configure message handlers
      await _configureMessageHandlers();

      _isInitialized = true;
      debugPrint('Push notification service initialized');

    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Request permissions for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined permission');
    }

    // For Android, permissions are handled automatically
    // But we can check if notifications are enabled
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');

        // Store token locally
        await _prefs?.setString('fcm_token', _fcmToken!);

        // Send token to backend
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) async {
      debugPrint('FCM Token refreshed: $token');
      _fcmToken = token;
      await _prefs?.setString('fcm_token', token);
      await _sendTokenToBackend(token);
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final httpClient = ApiClient();
      await httpClient.post('${AppConstants.baseUrl}/api/notifications/register-token', body: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });

      debugPrint('FCM token sent to backend successfully');
    } catch (e) {
      debugPrint('Failed to send FCM token to backend: $e');
    }
  }

  Future<void> _configureMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is terminated)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.notification?.title}');

    // Show local notification
    await _showLocalNotification(message);

    // Emit to stream
    _notificationController.add({
      'type': 'foreground',
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('App opened from notification: ${message.notification?.title}');

    // Handle navigation based on notification data
    _handleNotificationAction(message.data);

    // Emit to stream
    _notificationController.add({
      'type': 'opened',
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'swiftlyft_channel',
      'SwiftLyft Notifications',
      channelDescription: 'Notifications from SwiftLyft',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'SwiftLyft',
      message.notification?.body ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final data = jsonDecode(response.payload ?? '{}') as Map<String, dynamic>;
    _handleNotificationAction(data);
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    // Handle different notification types
    final type = data['type'];
    final bookingId = data['bookingId'];
    final quoteId = data['quoteId'];

    switch (type) {
      case 'booking_update':
        if (bookingId != null) {
          // Navigate to trip tracking
          // This would need to be handled by the app's navigation system
          debugPrint('Navigate to booking: $bookingId');
        }
        break;
      case 'quote_ready':
        if (quoteId != null) {
          // Navigate to quote details
          debugPrint('Navigate to quote: $quoteId');
        }
        break;
      case 'driver_assigned':
        if (bookingId != null) {
          // Navigate to trip tracking
          debugPrint('Navigate to booking: $bookingId');
        }
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(Map<String, bool> preferences) async {
    try {
      final httpClient = ApiClient();
      await httpClient.put('${AppConstants.baseUrl}/api/notifications/preferences', body: {
        'preferences': preferences,
      });

      debugPrint('Notification preferences updated');
    } catch (e) {
      debugPrint('Failed to update notification preferences: $e');
      rethrow;
    }
  }

  /// Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final httpClient = ApiClient();
      final response = await httpClient.get('${AppConstants.baseUrl}/api/notifications/preferences');
      final data = jsonDecode(response.body);

      final preferences = data['data']['preferences'] as Map<String, dynamic>;
      return preferences.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      debugPrint('Failed to get notification preferences: $e');
      return {};
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      await _requestPermissions();
      return true;
    } catch (e) {
      debugPrint('Failed to request permissions: $e');
      return false;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }

  /// Subscribe to a FCM topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _notificationController.close();
  }
}

/// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.notification?.title}');

  // Initialize local notifications for background
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Show notification
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'swiftlyft_channel_bg',
    'SwiftLyft Background Notifications',
    channelDescription: 'Background notifications from SwiftLyft',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'SwiftLyft',
    message.notification?.body ?? 'Background notification',
    platformChannelSpecifics,
    payload: jsonEncode(message.data),
  );
}
