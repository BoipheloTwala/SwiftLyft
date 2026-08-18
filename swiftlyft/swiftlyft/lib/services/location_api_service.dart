import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/coordinates.dart';
import '../models/location.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Location Service - handles /api/location/* endpoints
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  final ApiClient _apiClient = ApiClient();

  LocationService._internal();

  /// Check location permission status
  Future<bool> checkLocationPermission() async {
    // TODO: Implement actual location permission checking
    // For now, return true as a stub
    return true;
  }

  /// Geocode address to coordinates
  Future<GeocodeResult> geocodeAddress(String address, {
    String? country,
    String? region,
  }) async {
    try {
      final queryParams = <String, String>{
        'address': address,
        if (country != null) 'country': country,
        if (region != null) 'region': region,
      };

      const url = '${AppConstants.baseUrl}/api/location/geocode';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return GeocodeResult.fromJson(data['data']['result']);
    } catch (e) {
      debugPrint('Failed to geocode address: $e');
      rethrow;
    }
  }

  /// Reverse geocode coordinates to address
  Future<ReverseGeocodeResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };

      const url = '${AppConstants.baseUrl}/api/location/reverse-geocode';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return ReverseGeocodeResult.fromJson(data['data']['result']);
    } catch (e) {
      debugPrint('Failed to reverse geocode: $e');
      rethrow;
    }
  }

  /// Calculate route between two points
  Future<RouteResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String? travelMode,
    List<LatLng>? waypoints,
    Map<String, dynamic>? options,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/location/route';
      final response = await _apiClient.post(url, body: {
        'origin': {
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        },
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
        'travelMode': travelMode ?? 'driving',
        'waypoints': waypoints?.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList(),
        'options': options,
      });

      final data = jsonDecode(response.body);
      return RouteResult.fromJson(data['data']['route']);
    } catch (e) {
      debugPrint('Failed to calculate route: $e');
      rethrow;
    }
  }

  /// Search for places
  Future<List<PlaceResult>> searchPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'query': query,
        'limit': limit.toString(),
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        'radius': radius.toString(),
        if (type != null) 'type': type,
      };

      const url = '${AppConstants.baseUrl}/api/location/places/search';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final places = data['data']['places'] as List;
      return places.map((place) => PlaceResult.fromJson(place)).toList();
    } catch (e) {
      debugPrint('Failed to search places: $e');
      rethrow;
    }
  }

  /// Get place details
  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/location/places/$placeId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return PlaceDetails.fromJson(data['data']['place']);
    } catch (e) {
      debugPrint('Failed to get place details: $e');
      rethrow;
    }
  }

  /// Get nearby places
  Future<List<NearbyPlace>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    String? type,
    int radius = 1000,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };

      const url = '${AppConstants.baseUrl}/api/location/places/nearby';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final places = data['data']['places'] as List;
      return places.map((place) => NearbyPlace.fromJson(place)).toList();
    } catch (e) {
      debugPrint('Failed to get nearby places: $e');
      rethrow;
    }
  }

  /// Validate address
  Future<AddressValidation> validateAddress({
    required String address,
    String? country,
  }) async {
    try {
      final queryParams = <String, String>{
        'address': address,
        if (country != null) 'country': country,
      };

      const url = '${AppConstants.baseUrl}/api/location/validate-address';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return AddressValidation.fromJson(data['data']['validation']);
    } catch (e) {
      debugPrint('Failed to validate address: $e');
      rethrow;
    }
  }

  /// Get distance matrix
  Future<DistanceMatrix> getDistanceMatrix({
    required List<LatLng> origins,
    required List<LatLng> destinations,
    String? travelMode,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/location/distance-matrix';
      final response = await _apiClient.post(url, body: {
        'origins': origins.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList(),
        'destinations': destinations.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList(),
        'travelMode': travelMode ?? 'driving',
      });

      final data = jsonDecode(response.body);
      return DistanceMatrix.fromJson(data['data']['matrix']);
    } catch (e) {
      debugPrint('Failed to get distance matrix: $e');
      rethrow;
    }
  }

  /// Get directions with multiple waypoints
  Future<DetailedDirections> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    String? travelMode,
    bool? optimizeWaypoints,
    Map<String, dynamic>? options,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/location/directions';
      final response = await _apiClient.post(url, body: {
        'origin': {
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        },
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
        'waypoints': waypoints?.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList(),
        'travelMode': travelMode ?? 'driving',
        'optimizeWaypoints': optimizeWaypoints ?? false,
        'options': options,
      });

      final data = jsonDecode(response.body);
      return DetailedDirections.fromJson(data['data']['directions']);
    } catch (e) {
      debugPrint('Failed to get directions: $e');
      rethrow;
    }
  }

  /// Get service area boundaries
  Future<ServiceArea> getServiceArea() async {
    try {
      const url = '${AppConstants.baseUrl}/api/location/service-area';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return ServiceArea.fromJson(data['data']['area']);
    } catch (e) {
      debugPrint('Failed to get service area: $e');
      rethrow;
    }
  }

  /// Check if location is within service area
  Future<ServiceAreaCheck> checkServiceArea({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };

      const url = '${AppConstants.baseUrl}/api/location/service-area/check';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return ServiceAreaCheck.fromJson(data['data']['check']);
    } catch (e) {
      debugPrint('Failed to check service area: $e');
      rethrow;
    }
  }

  /// Get traffic information
  Future<TrafficInfo> getTrafficInfo({
    required LatLng northeast,
    required LatLng southwest,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/location/traffic';
      final response = await _apiClient.post(url, body: {
        'bounds': {
          'northeast': {
            'latitude': northeast.latitude,
            'longitude': northeast.longitude,
          },
          'southwest': {
            'latitude': southwest.latitude,
            'longitude': southwest.longitude,
          },
        },
      });

      final data = jsonDecode(response.body);
      return TrafficInfo.fromJson(data['data']['traffic']);
    } catch (e) {
      debugPrint('Failed to get traffic info: $e');
      rethrow;
    }
  }
}
