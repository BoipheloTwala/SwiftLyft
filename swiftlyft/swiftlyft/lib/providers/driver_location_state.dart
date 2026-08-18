import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/driver_location_service.dart';
import '../services/location_tracking_service.dart';

/// State management for driver location updates
class DriverLocationState extends ChangeNotifier {
  final DriverLocationService _driverLocationService;
  final LocationTrackingService _locationTrackingService;
  
  StreamSubscription<LocationData>? _locationSubscription;
  
  // State
  LocationData? _currentLocation;
  bool _isTracking = false;
  bool _isSendingUpdates = false;
  String? _error;
  
  // Driver info
  String? _driverId;
  String? _activeBookingId;
  
  // Statistics
  int _updatesSent = 0;
  int _updatesFailed = 0;
  DateTime? _lastUpdateTime;
  
  DriverLocationState(
    this._driverLocationService,
    this._locationTrackingService,
  );

  // Getters
  LocationData? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  bool get isSendingUpdates => _isSendingUpdates;
  String? get error => _error;
  int get updatesSent => _updatesSent;
  int get updatesFailed => _updatesFailed;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  LatLng? get currentLatLng => _currentLocation?.latLng;

  /// Initialize with driver ID
  void setDriverId(String driverId) {
    _driverId = driverId;
    debugPrint('👤 Driver ID set: $driverId');
  }

  /// Set active booking ID (for booking-specific updates)
  void setActiveBooking(String? bookingId) {
    _activeBookingId = bookingId;
    debugPrint('📋 Active booking: ${bookingId ?? "none"}');
    notifyListeners();
  }

  /// Start location tracking and sending updates
  Future<bool> startTracking({bool sendUpdates = true}) async {
    if (_isTracking) {
      debugPrint('⚠️ Tracking already active');
      return true;
    }

    if (_driverId == null && sendUpdates) {
      _setError('Driver ID not set');
      return false;
    }

    try {
      debugPrint('🎯 Starting location tracking');
      _clearError();

      // Start location tracking
      final stream = await _locationTrackingService.startTracking();
      if (stream == null) {
        _setError('Failed to start location tracking. Check permissions.');
        return false;
      }

      _isTracking = true;
      _isSendingUpdates = sendUpdates;

      // Listen to location updates
      _locationSubscription = stream.listen(
        (locationData) {
          _onLocationUpdate(locationData);
        },
        onError: (error) {
          _setError('Location tracking error: $error');
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  void stopTracking() {
    if (!_isTracking) {
      debugPrint('⚠️ Tracking not active');
      return;
    }

    debugPrint('🛑 Stopping location tracking');

    _locationSubscription?.cancel();
    _locationSubscription = null;
    
    _locationTrackingService.stopTracking();
    
    _isTracking = false;
    _isSendingUpdates = false;
    
    notifyListeners();
  }

  /// Handle location update
  void _onLocationUpdate(LocationData locationData) {
    _currentLocation = locationData;
    notifyListeners();

    // Send update to backend if enabled
    if (_isSendingUpdates) {
      _sendLocationUpdate(locationData);
    }
  }

  /// Send location update to backend
  Future<void> _sendLocationUpdate(LocationData locationData) async {
    if (_driverId == null) return;

    try {
      bool success;

      if (_activeBookingId != null) {
        // Send booking-specific update
        success = await _driverLocationService.updateDriverLocation(
          bookingId: _activeBookingId!,
          location: locationData.latLng,
          heading: locationData.heading,
          speed: locationData.speed,
          accuracy: locationData.accuracy,
        );
      } else {
        // Send general driver location update
        success = await _driverLocationService.updateLocation(
          driverId: _driverId!,
          location: locationData.latLng,
          heading: locationData.heading,
          speed: locationData.speed,
          accuracy: locationData.accuracy,
        );
      }

      if (success) {
        _updatesSent++;
        _lastUpdateTime = DateTime.now();
      } else {
        _updatesFailed++;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error sending location update: $e');
      _updatesFailed++;
      notifyListeners();
    }
  }

  /// Get current location once (without starting tracking)
  Future<LocationData?> getCurrentLocation() async {
    try {
      _clearError();
      final location = await _locationTrackingService.getCurrentLocation();
      if (location != null) {
        _currentLocation = location;
        notifyListeners();
      }
      return location;
    } catch (e) {
      _setError('Failed to get location: $e');
      return null;
    }
  }

  /// Manually send current location update
  Future<bool> sendManualUpdate() async {
    if (_currentLocation == null) {
      _setError('No location available');
      return false;
    }

    if (_driverId == null) {
      _setError('Driver ID not set');
      return false;
    }

    await _sendLocationUpdate(_currentLocation!);
    return _updatesSent > 0;
  }

  /// Update driver online/availability status
  Future<bool> updateStatus({
    required bool isOnline,
    required bool isAvailable,
  }) async {
    if (_driverId == null) {
      _setError('Driver ID not set');
      return false;
    }

    try {
      // Get current location
      final location = _currentLocation?.latLng ?? 
                      (await getCurrentLocation())?.latLng;
      
      if (location == null) {
        _setError('Location not available');
        return false;
      }

      final success = await _driverLocationService.updateLocation(
        driverId: _driverId!,
        location: location,
        isOnline: isOnline,
        isAvailable: isAvailable,
      );

      if (success) {
        debugPrint('✅ Driver status updated: online=$isOnline, available=$isAvailable');
      }

      return success;
    } catch (e) {
      _setError('Failed to update status: $e');
      return false;
    }
  }

  /// Get location update statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isTracking': _isTracking,
      'isSendingUpdates': _isSendingUpdates,
      'updatesSent': _updatesSent,
      'updatesFailed': _updatesFailed,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'currentLocation': _currentLocation != null
          ? {
              'latitude': _currentLocation!.latLng.latitude,
              'longitude': _currentLocation!.latLng.longitude,
              'accuracy': _currentLocation!.accuracy,
            }
          : null,
    };
  }

  /// Reset statistics
  void resetStatistics() {
    _updatesSent = 0;
    _updatesFailed = 0;
    _lastUpdateTime = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    debugPrint('❌ $error');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

