import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/driver.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Driver Service - handles /api/drivers/* endpoints
class DriverService {
  static final DriverService _instance = DriverService._internal();
  factory DriverService() => _instance;

  final ApiClient _apiClient = ApiClient();

  DriverService._internal();

  /// Get available drivers near location
  Future<List<Driver>> getAvailableDrivers({
    required double latitude,
    required double longitude,
    int maxDistance = 10000,
    String? vehicleType,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'maxDistance': maxDistance.toString(),
        'limit': limit.toString(),
        if (vehicleType != null) 'vehicleType': vehicleType,
      };

      const url = '${AppConstants.baseUrl}/api/drivers/available';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final drivers = data['data']['drivers'] as List;
      return drivers.map((driver) => Driver.fromJson(driver)).toList();
    } catch (e) {
      debugPrint('Failed to get available drivers: $e');
      rethrow;
    }
  }

  /// Get driver by ID
  Future<Driver> getDriver(String driverId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/drivers/$driverId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return Driver.fromJson(data['data']['driver']);
    } catch (e) {
      debugPrint('Failed to get driver: $e');
      rethrow;
    }
  }

  /// Get driver profile
  Future<DriverProfile> getDriverProfile(String driverId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/profile';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return DriverProfile.fromJson(data['data']['profile']);
    } catch (e) {
      debugPrint('Failed to get driver profile: $e');
      rethrow;
    }
  }

  /// Rate driver
  Future<DriverRating> rateDriver({
    required String driverId,
    required double rating,
    String? review,
    String? bookingId,
    Map<String, double>? categoryRatings,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/rate';
      final response = await _apiClient.post(url, body: {
        'rating': rating,
        'review': review,
        'bookingId': bookingId,
        'categoryRatings': categoryRatings,
      });

      final data = jsonDecode(response.body);
      return DriverRating.fromJson(data['data']['rating']);
    } catch (e) {
      debugPrint('Failed to rate driver: $e');
      rethrow;
    }
  }

  /// Assign driver to booking
  Future<DriverAssignment> assignDriver({
    required String bookingId,
    required String driverId,
    String? notes,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/drivers/assign';
      final response = await _apiClient.post(url, body: {
        'bookingId': bookingId,
        'driverId': driverId,
        if (notes != null) 'notes': notes,
      });

      final data = jsonDecode(response.body);
      return DriverAssignment.fromJson(data['data']['assignment']);
    } catch (e) {
      debugPrint('Failed to assign driver: $e');
      rethrow;
    }
  }

  /// Get driver ratings
  Future<List<DriverRating>> getDriverRatings(
    String driverId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/ratings';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final ratings = data['data']['ratings'] as List;
      return ratings.map((rating) => DriverRating.fromJson(rating)).toList();
    } catch (e) {
      debugPrint('Failed to get driver ratings: $e');
      rethrow;
    }
  }

  /// Get driver location
  Future<DriverLocation> getDriverLocation(String driverId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/location';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return DriverLocation.fromJson(data['data']['location']);
    } catch (e) {
      debugPrint('Failed to get driver location: $e');
      rethrow;
    }
  }

  /// Update driver location (for driver app)
  Future<void> updateDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    String? status,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/drivers/location';
      await _apiClient.put(url, body: {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'status': status,
      });
    } catch (e) {
      debugPrint('Failed to update driver location: $e');
      rethrow;
    }
  }

  /// Get driver performance stats
  Future<DriverStats> getDriverStats(String driverId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/stats';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return DriverStats.fromJson(data['data']['stats']);
    } catch (e) {
      debugPrint('Failed to get driver stats: $e');
      rethrow;
    }
  }

  /// Report driver issue
  Future<void> reportDriverIssue({
    required String driverId,
    required String issueType,
    required String description,
    String? bookingId,
    List<String>? attachments,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/report-issue';
      await _apiClient.post(url, body: {
        'issueType': issueType,
        'description': description,
        'bookingId': bookingId,
        'attachments': attachments,
      });
    } catch (e) {
      debugPrint('Failed to report driver issue: $e');
      rethrow;
    }
  }

  /// Contact driver
  Future<DriverContact> contactDriver({
    required String driverId,
    required String message,
    String? bookingId,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/contact';
      final response = await _apiClient.post(url, body: {
        'message': message,
        'bookingId': bookingId,
      });

      final data = jsonDecode(response.body);
      return DriverContact.fromJson(data['data']['contact']);
    } catch (e) {
      debugPrint('Failed to contact driver: $e');
      rethrow;
    }
  }

  /// Get driver schedule
  Future<DriverSchedule> getDriverSchedule(String driverId, {
    DateTime? date,
    int days = 7,
  }) async {
    try {
      final queryParams = <String, String>{
        'days': days.toString(),
        if (date != null) 'date': date.toIso8601String(),
      };

      final url = '${AppConstants.baseUrl}/api/drivers/$driverId/schedule';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return DriverSchedule.fromJson(data['data']['schedule']);
    } catch (e) {
      debugPrint('Failed to get driver schedule: $e');
      rethrow;
    }
  }

  /// Update driver availability
  Future<void> updateDriverAvailability({
    required bool isAvailable,
    DateTime? availableUntil,
    List<String>? availableVehicleTypes,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/drivers/availability';
      await _apiClient.put(url, body: {
        'isAvailable': isAvailable,
        'availableUntil': availableUntil?.toIso8601String(),
        'availableVehicleTypes': availableVehicleTypes,
      });
    } catch (e) {
      debugPrint('Failed to update driver availability: $e');
      rethrow;
    }
  }

  /// Get nearby drivers
  Future<List<NearbyDriver>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    int radius = 5000,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'limit': limit.toString(),
      };

      const url = '${AppConstants.baseUrl}/api/drivers/nearby';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final drivers = data['data']['drivers'] as List;
      return drivers.map((driver) => NearbyDriver.fromJson(driver)).toList();
    } catch (e) {
      debugPrint('Failed to get nearby drivers: $e');
      rethrow;
    }
  }
}
