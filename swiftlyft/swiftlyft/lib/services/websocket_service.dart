import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../utils/constants.dart';

/// WebSocket service for real-time updates
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<String> _connectionController = StreamController.broadcast();

  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  WebSocketService._internal();

  /// Stream of incoming messages
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream of connection status changes
  Stream<String> get connectionStatus => _connectionController.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect(String? accessToken) async {
    if (_isConnected) return;

    try {
      final wsUrl = '${AppConstants.baseUrl.replaceFirst('http', 'ws')}/ws?token=$accessToken';
      debugPrint('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: _onError,
      );

      // Wait for connection confirmation
      await _channel!.ready.timeout(const Duration(seconds: 10));

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add('connected');
      debugPrint('WebSocket connected successfully');

    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _connectionController.add('error');
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _isConnected = false;
    _connectionController.add('disconnected');
    debugPrint('WebSocket disconnected');
  }

  /// Send a message to the server
  void send(String event, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      debugPrint('Cannot send message: WebSocket not connected');
      return;
    }

    final message = {
      'event': event,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(jsonEncode(message));
    debugPrint('Sent WebSocket message: $event');
  }

  /// Subscribe to a specific event type
  Stream<Map<String, dynamic>> subscribeToEvent(String eventType) {
    return messages.where((message) => message['event'] == eventType);
  }

  /// Subscribe to booking updates for a specific booking
  Stream<Map<String, dynamic>> subscribeToBookingUpdates(String bookingId) {
    return messages.where((message) {
      final event = message['event'];
      final data = message['data'];
      return event == 'booking_update' && data['bookingId'] == bookingId;
    });
  }

  /// Subscribe to driver location updates
  Stream<Map<String, dynamic>> subscribeToDriverLocation(String driverId) {
    return messages.where((message) {
      final event = message['event'];
      final data = message['data'];
      return event == 'driver_location' && data['driverId'] == driverId;
    });
  }

  void _onMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message as String) as Map<String, dynamic>;
      _messageController.add(decoded);
      debugPrint('Received WebSocket message: ${decoded['event']}');
    } catch (e) {
      debugPrint('Failed to parse WebSocket message: $e');
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionController.add('disconnected');
    debugPrint('WebSocket disconnected');
    _scheduleReconnect();
  }

  void _onError(Object error) {
    debugPrint('WebSocket error: $error');
    _connectionController.add('error');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
      debugPrint('Attempting to reconnect... ($_reconnectAttempts/$_maxReconnectAttempts)');
      // Note: Reconnection would need access to the current token
      // This should be handled by the caller (AppState) when token is available
    });
  }

  /// Reset reconnection attempts (call when user logs in)
  void resetReconnectionAttempts() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
  }
}
