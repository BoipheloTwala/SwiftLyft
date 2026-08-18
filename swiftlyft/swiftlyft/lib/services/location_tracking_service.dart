import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for tracking device location using GPS
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamController<LocationData>? _locationController;
  
  Position? _lastPosition;
  bool _isTracking = false;
  
  // Location settings
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
  );

  LocationTrackingService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location once
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied');
        return null;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastPosition = position;
      
      return LocationData.fromPosition(position);
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<Stream<LocationData>?> startTracking() async {
    if (_isTracking) {
      debugPrint('⚠️ Location tracking already active');
      return _locationController?.stream;
    }

    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied');
        return null;
      }

      debugPrint('🎯 Starting location tracking');

      // Create stream controller
      _locationController = StreamController<LocationData>.broadcast();

      // Start listening to position stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (Position position) {
          _lastPosition = position;
          final locationData = LocationData.fromPosition(position);
          _locationController?.add(locationData);
          
          debugPrint('📍 Location update: ${locationData.latLng}');
        },
        onError: (error) {
          debugPrint('❌ Location tracking error: $error');
          _locationController?.addError(error);
        },
      );

      _isTracking = true;
      return _locationController?.stream;
    } catch (e) {
      debugPrint('❌ Error starting location tracking: $e');
      return null;
    }
  }

  /// Stop location tracking
  void stopTracking() {
    if (!_isTracking) {
      debugPrint('⚠️ Location tracking not active');
      return;
    }

    debugPrint('🛑 Stopping location tracking');

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    _locationController?.close();
    _locationController = null;
    
    _isTracking = false;
  }

  /// Get last known location
  LocationData? getLastLocation() {
    if (_lastPosition == null) return null;
    return LocationData.fromPosition(_lastPosition!);
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Calculate distance between two locations in meters
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calculate bearing between two locations in degrees
  double calculateBearing(LatLng from, LatLng to) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Dispose service
  void dispose() {
    stopTracking();
  }
}

/// Location data wrapper
class LocationData {
  final LatLng latLng;
  final double accuracy;
  final double? altitude;
  final double? heading;
  final double? speed;
  final double? speedAccuracy;
  final DateTime timestamp;

  LocationData({
    required this.latLng,
    required this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    this.speedAccuracy,
    required this.timestamp,
  });

  factory LocationData.fromPosition(Position position) {
    return LocationData(
      latLng: LatLng(position.latitude, position.longitude),
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      timestamp: position.timestamp,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: ${latLng.latitude}, lng: ${latLng.longitude}, '
           'accuracy: ${accuracy.toStringAsFixed(1)}m, '
           'speed: ${speed?.toStringAsFixed(1) ?? "N/A"} m/s)';
  }
}

/// Location permission status helper
class LocationPermissionHelper {
  static String getPermissionStatusMessage(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission denied. Please grant permission to continue.';
      case LocationPermission.deniedForever:
        return 'Location permission permanently denied. Please enable in app settings.';
      case LocationPermission.whileInUse:
        return 'Location permission granted for app usage.';
      case LocationPermission.always:
        return 'Location permission granted for background tracking.';
      default:
        return 'Unknown permission status.';
    }
  }

  static bool isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }
}

