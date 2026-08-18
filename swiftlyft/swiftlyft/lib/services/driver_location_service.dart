import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'http_client.dart';
import '../utils/constants.dart';

/// Service for posting driver location updates to backend
class DriverLocationService {
  static final DriverLocationService _instance = DriverLocationService._internal();
  factory DriverLocationService() => _instance;

  final ApiClient _apiClient = ApiClient();
  
  // Location update tracking
  DateTime? _lastUpdateTime;
  LatLng? _lastLocation;
  int _updateCount = 0;
  
  // Throttling configuration
  static const Duration _minUpdateInterval = Duration(seconds: 5);
  static const double _minDistanceMeters = 10.0; // Minimum distance to trigger update
  
  DriverLocationService._internal();

  /// Update driver location for a booking
  Future<bool> updateDriverLocation({
    required String bookingId,
    required LatLng location,
    double? heading,
    double? speed,
    double? accuracy,
  }) async {
    try {
      // Throttle updates
      if (!_shouldUpdate(location)) {
        debugPrint('⏸️ Location update throttled');
        return false;
      }

      debugPrint('📍 Updating driver location: $location');

      final url = '${AppConstants.baseUrl}/api/bookings/$bookingId/driver-location';
      
      final body = {
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.put(
        url,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _lastUpdateTime = DateTime.now();
        _lastLocation = location;
        _updateCount++;
        
        debugPrint('✅ Location updated successfully (count: $_updateCount)');
        return true;
      } else {
        debugPrint('❌ Location update failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating driver location: $e');
      return false;
    }
  }

  /// Update driver location (general, not tied to booking)
  Future<bool> updateLocation({
    required String driverId,
    required LatLng location,
    double? heading,
    double? speed,
    double? accuracy,
    bool? isOnline,
    bool? isAvailable,
  }) async {
    try {
      // Throttle updates
      if (!_shouldUpdate(location)) {
        debugPrint('⏸️ Location update throttled');
        return false;
      }

      debugPrint('📍 Updating driver location (general): $location');

      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/location';
      
      final body = {
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
        if (isOnline != null) 'isOnline': isOnline,
        if (isAvailable != null) 'isAvailable': isAvailable,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.post(
        url,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _lastUpdateTime = DateTime.now();
        _lastLocation = location;
        _updateCount++;
        
        debugPrint('✅ Location updated successfully (count: $_updateCount)');
        return true;
      } else {
        debugPrint('❌ Location update failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating driver location: $e');
      return false;
    }
  }

  /// Batch update multiple locations (for offline sync)
  Future<bool> batchUpdateLocations({
    required String driverId,
    required List<LocationUpdate> updates,
  }) async {
    try {
      debugPrint('📦 Batch updating ${updates.length} locations');

      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/location/batch';
      
      final body = {
        'updates': updates.map((u) => u.toJson()).toList(),
      };

      final response = await _apiClient.post(
        url,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Batch location update successful');
        return true;
      } else {
        debugPrint('❌ Batch location update failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error batch updating locations: $e');
      return false;
    }
  }

  /// Get driver's current location from backend
  Future<DriverLocationData?> getDriverLocation(String driverId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/location';
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DriverLocationData.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching driver location: $e');
      return null;
    }
  }

  /// Get location update history
  Future<List<LocationUpdate>> getLocationHistory({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (startDate != null) 'start': startDate.toIso8601String(),
        if (endDate != null) 'end': endDate.toIso8601String(),
      };

      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/location/history';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      
      final response = await _apiClient.get(uri.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updates = data['data']['updates'] as List;
        return updates.map((u) => LocationUpdate.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching location history: $e');
      return [];
    }
  }

  /// Check if location update should be sent based on throttling rules
  bool _shouldUpdate(LatLng newLocation) {
    // First update always goes through
    if (_lastUpdateTime == null || _lastLocation == null) {
      return true;
    }

    // Check time interval
    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
    if (timeSinceLastUpdate < _minUpdateInterval) {
      return false;
    }

    // Check distance moved
    final distance = _calculateDistance(
      _lastLocation!.latitude,
      _lastLocation!.longitude,
      newLocation.latitude,
      newLocation.longitude,
    );

    return distance >= _minDistanceMeters;
  }

  /// Calculate distance between two points in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Get update statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalUpdates': _updateCount,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'lastLocation': _lastLocation != null
          ? {
              'latitude': _lastLocation!.latitude,
              'longitude': _lastLocation!.longitude,
            }
          : null,
    };
  }

  /// Reset statistics
  void resetStatistics() {
    _updateCount = 0;
    _lastUpdateTime = null;
    _lastLocation = null;
  }
}

/// Location update data model
class LocationUpdate {
  final LatLng location;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final DateTime timestamp;

  LocationUpdate({
    required this.location,
    this.heading,
    this.speed,
    this.accuracy,
    required this.timestamp,
  });

  factory LocationUpdate.fromJson(Map<String, dynamic> json) {
    final coords = json['location'];
    return LocationUpdate(
      location: LatLng(
        coords['latitude']?.toDouble() ?? 0.0,
        coords['longitude']?.toDouble() ?? 0.0,
      ),
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Driver location data from backend
class DriverLocationData {
  final String driverId;
  final LatLng location;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final bool isOnline;
  final bool isAvailable;
  final DateTime timestamp;
  final DateTime updatedAt;

  DriverLocationData({
    required this.driverId,
    required this.location,
    this.heading,
    this.speed,
    this.accuracy,
    required this.isOnline,
    required this.isAvailable,
    required this.timestamp,
    required this.updatedAt,
  });

  factory DriverLocationData.fromJson(Map<String, dynamic> json) {
    final coords = json['location'];
    return DriverLocationData(
      driverId: json['driverId'] ?? '',
      location: LatLng(
        coords['latitude']?.toDouble() ?? 0.0,
        coords['longitude']?.toDouble() ?? 0.0,
      ),
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      isOnline: json['isOnline'] ?? false,
      isAvailable: json['isAvailable'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

