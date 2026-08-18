import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/coordinates.dart';
import '../models/booking.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Booking Service - handles /api/bookings/* endpoints for all users
/// Works for both regular and corporate users
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;

  final ApiClient _apiClient = ApiClient();

  BookingService._internal();

  /// Create a new booking - Aligned with backend POST /api/bookings
  /// Works for both regular and corporate users
  Future<Booking> createBooking({
    required String vehicleId,
    required String vehicleName,
    required String vehicleType,
    required String serviceType,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required DateTime scheduledDate,
    required int passengerCount,
    required Map<String, dynamic> pricing,
    String? pickupAddress,
    String? dropoffAddress,
    List<Map<String, dynamic>>? waypoints,
    int? luggageCount,
    DateTime? pickupTime,
    bool? isFlexibleTime,
    int? flexibleWindow,
    double? basePrice,
    double? finalPrice,
    String? specialNotes,
    bool closeProtectionOfficer = false,
    String? customerNotes,
    String? paymentMethod,
    Map<String, dynamic>? emergencyContact,
    String? quoteId,
  }) async {
    try {
      debugPrint('🚀 Creating booking via POST /api/bookings');
      
      const url = '${AppConstants.baseUrl}/api/bookings';
      
      // Transform location to backend Booking schema (latitude/longitude + city/province)
      Map<String, dynamic> transformLocation(Map<String, dynamic> location) {
        final coords = location['coordinates'] as Map<String, dynamic>?;
        final hasLatLng = coords != null && coords.containsKey('lat') && coords.containsKey('lng');
        final hasLatitudeLongitude = coords != null && coords.containsKey('latitude') && coords.containsKey('longitude');

        final transformed = <String, dynamic>{};
        transformed['address'] = location['address'];
        transformed['city'] = location['city'];
        transformed['province'] = location['province'];

        // Backend Booking model requires coordinates.latitude/coordinates.longitude
        transformed['coordinates'] = <String, dynamic>{
          'latitude': hasLatitudeLongitude
              ? coords!['latitude']
              : (hasLatLng ? coords!['lat'] : null),
          'longitude': hasLatitudeLongitude
              ? coords!['longitude']
              : (hasLatLng ? coords!['lng'] : null),
        };

        return transformed;
      }
      
      // Build request body matching backend expectations
      final body = {
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'vehicleType': vehicleType,
        'serviceType': serviceType,
        'pickupLocation': transformLocation(pickupLocation),
        'dropoffLocation': transformLocation(dropoffLocation),
        'scheduledDate': (pickupTime ?? scheduledDate).toIso8601String(),
        'pickupTime': (pickupTime ?? scheduledDate).toIso8601String(),
        'passengerCount': passengerCount,
        'pricing': pricing,
        if (pickupAddress != null) 'pickupAddress': pickupAddress,
        if (dropoffAddress != null) 'dropoffAddress': dropoffAddress,
        if (waypoints != null && waypoints.isNotEmpty) 'waypoints': waypoints,
        if (luggageCount != null) 'luggageCount': luggageCount,
        if (isFlexibleTime != null) 'isFlexibleTime': isFlexibleTime,
        if (flexibleWindow != null) 'flexibleWindow': flexibleWindow,
        if (basePrice != null) 'basePrice': basePrice,
        if (finalPrice != null) 'finalPrice': finalPrice,
        if (specialNotes != null) 'specialNotes': specialNotes,
        'closeProtectionOfficer': closeProtectionOfficer,
        if (customerNotes != null) 'customerNotes': customerNotes,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (quoteId != null) 'quoteId': quoteId,
      };

      debugPrint('Request body: ${jsonEncode(body)}');
      
      final response = await _apiClient.post(url, body: body);

      final data = jsonDecode(response.body);
      debugPrint('✅ Booking created: ${data['data']}');
      
      return Booking.fromJson(data['data']);
    } catch (e) {
      debugPrint('❌ Failed to create booking: $e');
      rethrow;
    }
  }

  /// Assign a driver to a booking - POST /api/bookings/{id}/assign-driver
  /// Typically used by admin/system, not end users
  Future<Booking> assignDriver(String bookingId, String driverId) async {
    try {
      debugPrint('🚀 Assigning driver to booking: $bookingId');
      
      final url = '${AppConstants.baseUrl}/api/bookings/$bookingId/assign-driver';
      final response = await _apiClient.post(url, body: {
        'driverId': driverId,
      });

      final data = jsonDecode(response.body);
      debugPrint('✅ Driver assigned successfully');
      
      return Booking.fromJson(data['data']);
    } catch (e) {
      debugPrint('❌ Failed to assign driver: $e');
      rethrow;
    }
  }

  /// Get booking by ID - GET /api/bookings/{id}
  /// Works for both regular and corporate users (checks ownership)
  Future<Booking> getBooking(String bookingId) async {
    try {
      debugPrint('🚀 Fetching booking: $bookingId');
      
      final url = '${AppConstants.baseUrl}/api/bookings/$bookingId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      debugPrint('✅ Booking retrieved');
      
      return Booking.fromJson(data['data']);
    } catch (e) {
      debugPrint('❌ Failed to get booking: $e');
      rethrow;
    }
  }

  /// NOTE: User bookings should be fetched via UserService.getUserBookings()
  /// which calls GET /api/users/{userId}/bookings
  /// This ensures proper authentication and authorization for all user types

  /// Update booking - PUT /api/bookings/{id}
  /// Only certain fields can be updated (specialNotes, customerNotes, paymentMethod, emergencyContact, closeProtectionOfficer)
  /// Works for both regular and corporate users (checks ownership)
  Future<Booking> updateBooking(String bookingId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🚀 Updating booking: $bookingId');
      debugPrint('Updates: ${jsonEncode(updates)}');
      
      final url = '${AppConstants.baseUrl}/api/bookings/$bookingId';
      final response = await _apiClient.put(url, body: updates);

      final data = jsonDecode(response.body);
      debugPrint('✅ Booking updated successfully');
      
      return Booking.fromJson(data['data']);
    } catch (e) {
      debugPrint('❌ Failed to update booking: $e');
      rethrow;
    }
  }

  /// Submit a booking modification request
  /// Endpoint: POST /api/bookings/{id}/modifications
  Future<Map<String, dynamic>> requestBookingModification(
    String bookingId, {
    required Map<String, dynamic> requestedChanges,
    String? reason,
  }) async {
    try {
      debugPrint('📝 Submitting booking modification for $bookingId');

      // Preferred endpoint (if backend supports it)
      final url = '${AppConstants.baseUrl}/api/bookings/$bookingId/modifications';
      try {
        final response = await _apiClient.post(url, body: {
          'requestedChanges': requestedChanges,
          if (reason != null) 'reason': reason,
        });

        final data = jsonDecode(response.body);
        return data['data'] is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>)
            : {'modification': data['data']};
      } catch (e) {
        // Fallback: backend does not implement modifications endpoint
        if (e.toString().contains('404') || e.toString().contains('Resource not found')) {
          debugPrint('ℹ️ Modifications endpoint not available; falling back to customerNotes');
          // Send a structured note via allowed PUT fields
          final fallbackNote = {
            'type': 'modification_request',
            'reason': reason,
            'requestedChanges': requestedChanges,
            'requestedAt': DateTime.now().toIso8601String(),
          };

          final putUrl = '${AppConstants.baseUrl}/api/bookings/$bookingId';
          final putResponse = await _apiClient.put(putUrl, body: {
            'customerNotes': '[MODIFICATION_REQUEST] ' + jsonEncode(fallbackNote),
          });

          final putData = jsonDecode(putResponse.body);
          return {
            'modification': fallbackNote,
            'booking': putData['data'],
            'fallback': true,
          };
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Failed to submit booking modification: $e');
      rethrow;
    }
  }

  /// Cancel booking - DELETE /api/bookings/{id}
  /// Calculates cancellation fee based on timing
  /// Works for both regular and corporate users (checks ownership)
  Future<Map<String, dynamic>> cancelBooking(String bookingId, {String? reason}) async {
    try {
      debugPrint('🚀 Cancelling booking: $bookingId');
      
      final url = '${AppConstants.baseUrl}/api/bookings/$bookingId';
      final response = await _apiClient.delete(url, body: {
        if (reason != null) 'reason': reason,
      });

      final data = jsonDecode(response.body);
      debugPrint('✅ Booking cancelled. Fee: ${data['data']['cancellationFee']}');
      
      return data['data']; // Returns {bookingId, cancellationFee, cancelledAt}
    } catch (e) {
      debugPrint('❌ Failed to cancel booking: $e');
      rethrow;
    }
  }

  /// Update booking status - PUT /api/bookings/{id}/status
  /// Used to update status with additional tracking
  /// Works for both regular and corporate users
  Future<Booking> updateBookingStatus(String bookingId, String status, {String? notes}) async {
    try {
      debugPrint('🚀 Updating booking status: $bookingId to $status');
      
      final url = '${AppConstants.baseUrl}/api/bookings/$bookingId/status';
      final response = await _apiClient.put(url, body: {
        'status': status,
        if (notes != null) 'notes': notes,
      });

      final data = jsonDecode(response.body);
      debugPrint('✅ Booking status updated');
      
      return Booking.fromJson(data['data']);
    } catch (e) {
      debugPrint('❌ Failed to update booking status: $e');
      rethrow;
    }
  }

  /// Rate booking/driver - POST /api/bookings/{id}/rating
  /// Submits trip rating and review (only for completed trips)
  /// Also awards loyalty points to the user
  /// Works for both regular and corporate users
  Future<Booking> rateBooking({
    required String bookingId,
    required double rating,
    String? review,
    Map<String, dynamic>? categories,
  }) async {
    try {
      debugPrint('🚀 Rating booking: $bookingId with rating: $rating');
      
      final url = '${AppConstants.baseUrl}/api/bookings/$bookingId/rating';
      final response = await _apiClient.post(url, body: {
        'rating': rating,
        if (review != null) 'review': review,
        if (categories != null) 'categories': categories,
      });

      final data = jsonDecode(response.body);
      debugPrint('✅ Booking rated successfully');
      
      return Booking.fromJson(data['data']);
    } catch (e) {
      debugPrint('❌ Failed to rate booking: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DEPRECATED / REMOVED ENDPOINTS
  // ============================================================================
  // The following methods have been removed as they don't exist in the backend:
  // - getBookingHistory() → Use UserService.getUserBookings() instead
  // - getActiveBookings() → Use UserService.getUserBookings() with status filter instead
  // - trackBooking() → Not implemented in backend yet
  // - getBookingStats() → Admin-only endpoint, not for regular users
  // - requestModification() → Not implemented in backend yet
  // - getBookingReceipt() → Not implemented in backend yet
  // ============================================================================

  /// Simulate driver movement (for development/testing only)
  /// Note: This is a placeholder for real-time WebSocket integration
  Future<void> simulateDriverMovement(String driverId) async {
    debugPrint('⚠️ Simulating driver movement for $driverId (dev only)');
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Get driver's current location (for development/testing only)
  /// Note: This should be replaced with real-time WebSocket integration
  LatLng getDriverLocation(String driverId) {
    debugPrint('⚠️ Getting simulated driver location for $driverId (dev only)');
    // Return Johannesburg city center as placeholder
    return const LatLng(-26.2041, 28.0473);
  }
}
