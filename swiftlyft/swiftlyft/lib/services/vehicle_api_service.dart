import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Vehicle Service - handles /api/vehicles/* endpoints
class VehicleService {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;

  final ApiClient _apiClient = ApiClient();

  VehicleService._internal();

  /// Get available vehicles by location
  Future<List<Vehicle>> getAvailableVehicles({
    required double latitude,
    required double longitude,
    int maxDistance = 10000,
    String? category,
    int? passengerCount,
    List<String>? features,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'maxDistance': maxDistance.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (passengerCount != null) 'passengerCount': passengerCount.toString(),
        if (features != null && features.isNotEmpty) 'features': features.join(','),
      };

      const url = '${AppConstants.baseUrl}/api/vehicles/available';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      // Backend returns data as array directly, not data.vehicles
      final vehicles = data['data'] as List;
      return vehicles.map((vehicle) => Vehicle.fromJson(vehicle)).toList();
    } catch (e) {
      debugPrint('Failed to get available vehicles: $e');
      rethrow;
    }
  }

  /// Get vehicle details by ID
  Future<Vehicle> getVehicleDetails(String vehicleId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/vehicles/$vehicleId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      // Handle both possible response structures
      if (data['data'] != null) {
        final vehicleData = data['data']['vehicle'] ?? data['data'];
        return Vehicle.fromJson(vehicleData);
      }
      return Vehicle.fromJson(data);
    } catch (e) {
      debugPrint('Failed to get vehicle details: $e');
      rethrow;
    }
  }

  /// Search vehicles
  Future<List<Vehicle>> searchVehicles({
    String? query,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    List<String>? features,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': page.toString(),
        if (query != null) 'query': query,
        if (category != null) 'category': category,
        if (location != null) 'location': location,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        if (features != null && features.isNotEmpty) 'features': features.join(','),
      };

      const url = '${AppConstants.baseUrl}/api/vehicles/search';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final vehicles = data['data']['vehicles'] as List;
      return vehicles.map((vehicle) => Vehicle.fromJson(vehicle)).toList();
    } catch (e) {
      debugPrint('Failed to search vehicles: $e');
      rethrow;
    }
  }

  /// Get vehicle categories
  Future<List<VehicleCategory>> getVehicleCategories() async {
    try {
      const url = '${AppConstants.baseUrl}/api/vehicles/categories';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final categories = data['data']['categories'] as List;
      return categories.map((category) => VehicleCategory.fromJson(category)).toList();
    } catch (e) {
      debugPrint('Failed to get vehicle categories: $e');
      rethrow;
    }
  }

  /// Get popular vehicles
  Future<List<Vehicle>> getPopularVehicles({
    String? location,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (location != null) 'location': location,
      };

      const url = '${AppConstants.baseUrl}/api/vehicles/popular';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final vehicles = data['data']['vehicles'] as List;
      return vehicles.map((vehicle) => Vehicle.fromJson(vehicle)).toList();
    } catch (e) {
      debugPrint('Failed to get popular vehicles: $e');
      rethrow;
    }
  }

  /// Get vehicle availability for specific time
  Future<VehicleAvailability> checkVehicleAvailability(
    String vehicleId,
    DateTime dateTime,
  ) async {
    try {
      final queryParams = <String, String>{
        'dateTime': dateTime.toIso8601String(),
      };

      final url = '${AppConstants.baseUrl}/api/vehicles/$vehicleId/availability';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return VehicleAvailability.fromJson(data['data']['availability']);
    } catch (e) {
      debugPrint('Failed to check vehicle availability: $e');
      rethrow;
    }
  }

  /// Get vehicles by driver
  Future<List<Vehicle>> getVehiclesByDriver(String driverId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/vehicles/driver/$driverId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final vehicles = data['data']['vehicles'] as List;
      return vehicles.map((vehicle) => Vehicle.fromJson(vehicle)).toList();
    } catch (e) {
      debugPrint('Failed to get vehicles by driver: $e');
      rethrow;
    }
  }

  /// Rate vehicle
  Future<VehicleRating> rateVehicle({
    required String vehicleId,
    required double rating,
    String? review,
    String? bookingId,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/vehicles/$vehicleId/rate';
      final response = await _apiClient.post(url, body: {
        'rating': rating,
        if (review != null) 'review': review,
        if (bookingId != null) 'bookingId': bookingId,
      });

      final data = jsonDecode(response.body);
      return VehicleRating.fromJson(data['data']['rating']);
    } catch (e) {
      debugPrint('Failed to rate vehicle: $e');
      rethrow;
    }
  }

  /// Get vehicle reviews
  Future<List<VehicleRating>> getVehicleReviews(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = '${AppConstants.baseUrl}/api/vehicles/$vehicleId/reviews';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final reviews = data['data']['reviews'] as List;
      return reviews.map((review) => VehicleRating.fromJson(review)).toList();
    } catch (e) {
      debugPrint('Failed to get vehicle reviews: $e');
      rethrow;
    }
  }

  /// Get vehicle pricing
  Future<VehiclePricing> getVehiclePricing(String vehicleId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/vehicles/$vehicleId/pricing';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return VehiclePricing.fromJson(data['data']['pricing']);
    } catch (e) {
      debugPrint('Failed to get vehicle pricing: $e');
      rethrow;
    }
  }

  /// Get vehicle features
  Future<List<VehicleFeature>> getVehicleFeatures() async {
    try {
      const url = '${AppConstants.baseUrl}/api/vehicles/features';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final features = data['data']['features'] as List;
      return features.map((feature) => VehicleFeature.fromJson(feature)).toList();
    } catch (e) {
      debugPrint('Failed to get vehicle features: $e');
      rethrow;
    }
  }

  /// Report vehicle issue
  Future<void> reportVehicleIssue({
    required String vehicleId,
    required String issueType,
    required String description,
    String? bookingId,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/vehicles/$vehicleId/report-issue';
      await _apiClient.post(url, body: {
        'issueType': issueType,
        'description': description,
        if (bookingId != null) 'bookingId': bookingId,
      });
    } catch (e) {
      debugPrint('Failed to report vehicle issue: $e');
      rethrow;
    }
  }
}
