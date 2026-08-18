import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/trip_notification_manager.dart';

/// State management for notification preferences
class NotificationPreferencesState extends ChangeNotifier {
  final TripNotificationManager _notificationManager;
  
  // Preferences
  bool _notificationsEnabled = true;
  bool _driverAssignedNotifications = true;
  bool _driverArrivedNotifications = true;
  bool _tripStartedNotifications = true;
  bool _tripCompletedNotifications = true;
  bool _etaAlertsNotifications = true;
  bool _paymentNotifications = true;
  bool _promotionalNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Loading state
  bool _isLoading = false;
  
  NotificationPreferencesState(this._notificationManager) {
    _loadPreferences();
  }

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get driverAssignedNotifications => _driverAssignedNotifications;
  bool get driverArrivedNotifications => _driverArrivedNotifications;
  bool get tripStartedNotifications => _tripStartedNotifications;
  bool get tripCompletedNotifications => _tripCompletedNotifications;
  bool get etaAlertsNotifications => _etaAlertsNotifications;
  bool get paymentNotifications => _paymentNotifications;
  bool get promotionalNotifications => _promotionalNotifications;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get isLoading => _isLoading;

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _driverAssignedNotifications = prefs.getBool('driver_assigned_notifications') ?? true;
      _driverArrivedNotifications = prefs.getBool('driver_arrived_notifications') ?? true;
      _tripStartedNotifications = prefs.getBool('trip_started_notifications') ?? true;
      _tripCompletedNotifications = prefs.getBool('trip_completed_notifications') ?? true;
      _etaAlertsNotifications = prefs.getBool('eta_alerts_notifications') ?? true;
      _paymentNotifications = prefs.getBool('payment_notifications') ?? true;
      _promotionalNotifications = prefs.getBool('promotional_notifications') ?? false;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      
      // Sync with notification manager
      _syncWithManager();
      
      debugPrint('✅ Notification preferences loaded');
    } catch (e) {
      debugPrint('❌ Error loading notification preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('driver_assigned_notifications', _driverAssignedNotifications);
      await prefs.setBool('driver_arrived_notifications', _driverArrivedNotifications);
      await prefs.setBool('trip_started_notifications', _tripStartedNotifications);
      await prefs.setBool('trip_completed_notifications', _tripCompletedNotifications);
      await prefs.setBool('eta_alerts_notifications', _etaAlertsNotifications);
      await prefs.setBool('payment_notifications', _paymentNotifications);
      await prefs.setBool('promotional_notifications', _promotionalNotifications);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      
      // Sync with notification manager
      _syncWithManager();
      
      debugPrint('✅ Notification preferences saved');
    } catch (e) {
      debugPrint('❌ Error saving notification preferences: $e');
    }
  }

  /// Sync preferences with notification manager
  void _syncWithManager() {
    if (_notificationsEnabled) {
      _notificationManager.enableAll();
    } else {
      _notificationManager.disableAll();
    }
    
    _notificationManager.setPreference('driver_assigned', _driverAssignedNotifications);
    _notificationManager.setPreference('driver_arrived', _driverArrivedNotifications);
    _notificationManager.setPreference('trip_started', _tripStartedNotifications);
    _notificationManager.setPreference('trip_completed', _tripCompletedNotifications);
    _notificationManager.setPreference('eta_alerts', _etaAlertsNotifications);
    _notificationManager.setPreference('payment_updates', _paymentNotifications);
    _notificationManager.setPreference('promotional', _promotionalNotifications);
  }

  /// Toggle notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set driver assigned notifications
  Future<void> setDriverAssignedNotifications(bool enabled) async {
    _driverAssignedNotifications = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set driver arrived notifications
  Future<void> setDriverArrivedNotifications(bool enabled) async {
    _driverArrivedNotifications = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set trip started notifications
  Future<void> setTripStartedNotifications(bool enabled) async {
    _tripStartedNotifications = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set trip completed notifications
  Future<void> setTripCompletedNotifications(bool enabled) async {
    _tripCompletedNotifications = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set ETA alerts notifications
  Future<void> setEtaAlertsNotifications(bool enabled) async {
    _etaAlertsNotifications = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set payment notifications
  Future<void> setPaymentNotifications(bool enabled) async {
    _paymentNotifications = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set promotional notifications
  Future<void> setPromotionalNotifications(bool enabled) async {
    _promotionalNotifications = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set sound enabled
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Set vibration enabled
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();
    await _savePreferences();
  }

  /// Enable all trip notifications
  Future<void> enableAllTripNotifications() async {
    _driverAssignedNotifications = true;
    _driverArrivedNotifications = true;
    _tripStartedNotifications = true;
    _tripCompletedNotifications = true;
    _etaAlertsNotifications = true;
    notifyListeners();
    await _savePreferences();
  }

  /// Disable all trip notifications
  Future<void> disableAllTripNotifications() async {
    _driverAssignedNotifications = false;
    _driverArrivedNotifications = false;
    _tripStartedNotifications = false;
    _tripCompletedNotifications = false;
    _etaAlertsNotifications = false;
    notifyListeners();
    await _savePreferences();
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _notificationsEnabled = true;
    _driverAssignedNotifications = true;
    _driverArrivedNotifications = true;
    _tripStartedNotifications = true;
    _tripCompletedNotifications = true;
    _etaAlertsNotifications = true;
    _paymentNotifications = true;
    _promotionalNotifications = false;
    _soundEnabled = true;
    _vibrationEnabled = true;
    notifyListeners();
    await _savePreferences();
  }

  /// Get summary of enabled notifications
  Map<String, bool> getSummary() {
    return {
      'notifications_enabled': _notificationsEnabled,
      'driver_assigned': _driverAssignedNotifications,
      'driver_arrived': _driverArrivedNotifications,
      'trip_started': _tripStartedNotifications,
      'trip_completed': _tripCompletedNotifications,
      'eta_alerts': _etaAlertsNotifications,
      'payment': _paymentNotifications,
      'promotional': _promotionalNotifications,
      'sound': _soundEnabled,
      'vibration': _vibrationEnabled,
    };
  }
}

