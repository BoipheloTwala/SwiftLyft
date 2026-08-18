import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/address.dart';
import '../models/preferences.dart';
import '../models/quote.dart';
import '../models/booking.dart';
import '../services/http_client.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../models/loyalty.dart';
import '../models/referral.dart';
import '../models/corporate.dart';
import '../models/user_stats.dart';
import '../models/reward.dart';
import '../models/bulk_booking.dart';

/// User Service - handles /api/users/* endpoints
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  UserService._internal();

  /// Get current user profile
  Future<User> getProfile() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/profile';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return User.fromJson(data['data']['user']);
    } catch (e) {
      debugPrint('Failed to get user profile: $e');
      rethrow;
    }
  }

  /// Get loyalty info for current user
  Future<LoyaltyInfo> getLoyalty() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/loyalty';
      final response = await _apiClient.get(url);
      final data = jsonDecode(response.body);
      return LoyaltyInfo.fromJson(data['data']);
    } catch (e) {
      debugPrint('Failed to get loyalty info: $e');
      rethrow;
    }
  }

  /// Get referral info for current user
  Future<ReferralInfo> getReferral() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/referral';
      final response = await _apiClient.get(url);
      final data = jsonDecode(response.body);
      return ReferralInfo.fromJson(data['data']);
    } catch (e) {
      debugPrint('Failed to get referral info: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/profile';
      final response = await _apiClient.put(url, body: {
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (bio != null) 'bio': bio,
      });

      final data = jsonDecode(response.body);
      return User.fromJson(data['data']['user']);
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      rethrow;
    }
  }

  /// Get user preferences
  Future<UserPreferences> getPreferences() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/preferences';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return UserPreferences.fromJson(data['data']['preferences']);
    } catch (e) {
      debugPrint('Failed to get user preferences: $e');
      rethrow;
    }
  }

  /// Update user preferences
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/preferences';
      final response = await _apiClient.put(url, body: preferences.toJson());

      final data = jsonDecode(response.body);
      return UserPreferences.fromJson(data['data']['preferences']);
    } catch (e) {
      debugPrint('Failed to update user preferences: $e');
      rethrow;
    }
  }

  /// Get user addresses
  Future<List<Address>> getAddresses() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/addresses';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final addresses = data['data']['addresses'] as List;
      return addresses.map((addr) => Address.fromJson(addr)).toList();
    } catch (e) {
      debugPrint('Failed to get user addresses: $e');
      rethrow;
    }
  }

  /// Add new address
  Future<Address> addAddress(Address address) async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/addresses';
      final response = await _apiClient.post(url, body: address.toJson());

      final data = jsonDecode(response.body);
      return Address.fromJson(data['data']['address']);
    } catch (e) {
      debugPrint('Failed to add address: $e');
      rethrow;
    }
  }

  /// Update address
  Future<Address> updateAddress(String addressId, Address address) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/addresses/$addressId';
      final response = await _apiClient.put(url, body: address.toJson());

      final data = jsonDecode(response.body);
      return Address.fromJson(data['data']['address']);
    } catch (e) {
      debugPrint('Failed to update address: $e');
      rethrow;
    }
  }

  /// Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/addresses/$addressId';
      await _apiClient.delete(url);
    } catch (e) {
      debugPrint('Failed to delete address: $e');
      rethrow;
    }
  }

  /// Set default address
  Future<void> setDefaultAddress(String addressId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/addresses/$addressId/default';
      await _apiClient.put(url);
    } catch (e) {
      debugPrint('Failed to set default address: $e');
      rethrow;
    }
  }

  /// Get user quotes
  /// Note: This is a proxy method. Consider using QuoteService.getUserQuotes() directly instead.
  Future<List<Quote>> getUserQuotes(
    String userId, {
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final url = '${AppConstants.baseUrl}/api/users/$userId/quotes';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final quotes = data['data']['quotes'] as List;
      return quotes.map((quote) => Quote.fromJson(quote)).toList();
    } catch (e) {
      debugPrint('Failed to get user quotes: $e');
      rethrow;
    }
  }

  /// Get user bookings
  /// Backend endpoint: GET /api/bookings/user/:userId
  Future<List<Booking>> getUserBookings({
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get current user ID from AuthService
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      // Backend endpoint: GET /api/bookings/user/:userId (from bookings.js route)
      final url = '${AppConstants.baseUrl}/api/bookings/user/$userId';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      
      // Backend returns data directly as array, not nested in bookings
      final bookings = data['data'] as List;
      return bookings.map((booking) => Booking.fromJson(booking)).toList();
    } catch (e) {
      debugPrint('Failed to get user bookings: $e');
      rethrow;
    }
  }

  /// Get user notifications
  Future<List<Notification>> getUserNotifications({
    int page = 1,
    int limit = 20,
    bool? read,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (read != null) 'read': read.toString(),
      };

      const url = '${AppConstants.baseUrl}/api/users/notifications';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final notifications = data['data']['notifications'] as List;
      return notifications.map((notif) => Notification.fromJson(notif)).toList();
    } catch (e) {
      debugPrint('Failed to get user notifications: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/notifications/$notificationId/read';
      await _apiClient.put(url);
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/notifications/read-all';
      await _apiClient.put(url);
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/notifications/$notificationId';
      await _apiClient.delete(url);
    } catch (e) {
      debugPrint('Failed to delete notification: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<UserStats> getUserStats() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/stats';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return UserStats.fromJson(data['data']['stats']);
    } catch (e) {
      debugPrint('Failed to get user stats: $e');
      rethrow;
    }
  }

  /// Update user avatar
  Future<String> updateAvatar(String imagePath) async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/avatar';
      final response = await _apiClient.uploadFile(url, imagePath, fieldName: 'avatar');
      final data = jsonDecode(response.body);
      return data['avatarUrl'] ?? '';
    } catch (e) {
      debugPrint('Failed to update avatar: $e');
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/change-password';
      await _apiClient.put(url, body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      debugPrint('Failed to change password: $e');
      rethrow;
    }
  }
  /// Add vehicle to favorites
  Future<void> addFavoriteVehicle(String vehicleId) async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/favorites/vehicles';
      await _apiClient.post(url, body: {'vehicleId': vehicleId});
      debugPrint('Vehicle $vehicleId added to favorites');
    } catch (e) {
      debugPrint('Failed to add favorite vehicle: $e');
      rethrow;
    }
  }

  /// Remove vehicle from favorites
  Future<void> removeFavoriteVehicle(String vehicleId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/favorites/vehicles/$vehicleId';
      await _apiClient.delete(url);
      debugPrint('Vehicle $vehicleId removed from favorites');
    } catch (e) {
      debugPrint('Failed to remove favorite vehicle: $e');
      rethrow;
    }
  }

  /// Get user's favorite vehicles
  Future<List<String>> getUserFavorites() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/favorites/vehicles';
      final response = await _apiClient.get(url);
      final data = jsonDecode(response.body);
      final favorites = data['data']['favorites'] as List;
      return favorites.map((item) => item['vehicleId'] as String).toList();
    } catch (e) {
      debugPrint('Failed to get user favorites: $e');
      rethrow;
    }
  }

  /// Get corporate account information
  /// Returns null if user doesn't have a corporate account (404 is expected)
  Future<CorporateInfo?> getCorporateInfo() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/corporate';
      final response = await _apiClient.get(url);
      final data = jsonDecode(response.body);
      return CorporateInfo.fromJson(data['data']);
    } catch (e) {
      // If user doesn't have a corporate account, this is expected behavior
      if (e.toString().contains('404') || 
          e.toString().contains('No corporate account found') ||
          e.toString().contains('Resource not found')) {
        debugPrint('ℹ️ User does not have a corporate account (this is normal for regular users)');
        return null;
      }
      debugPrint('❌ Failed to get corporate info: $e');
      rethrow;
    }
  }

  /// Check if user has corporate account
  Future<bool> hasCorporateAccount() async {
    try {
      final info = await getCorporateInfo();
      return info != null;
    } catch (e) {
      debugPrint('Failed to check corporate account: $e');
      return false;
    }
  }

  /// Create a corporate booking (legacy method - uses /api/corporate/bookings)
  /// @deprecated Use createBulkBooking() instead for new bulk bookings feature
  Future<CorporateBooking> createCorporateBooking({
    required String title,
    String? description,
    required String bookingType,
    required List<Map<String, dynamic>> trips,
    String? specialInstructions,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/corporate/bookings';
      final response = await _apiClient.post(url, body: {
        'title': title,
        if (description != null) 'description': description,
        'bookingType': bookingType,
        'trips': trips,
        if (specialInstructions != null) 'specialInstructions': specialInstructions,
      });

      final data = jsonDecode(response.body);
      return CorporateBooking.fromJson(data['data']['booking']);
    } catch (e) {
      debugPrint('Failed to create corporate booking: $e');
      rethrow;
    }
  }

  /// Get corporate bookings
  Future<List<CorporateBooking>> getCorporateBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = await getProfile();
      final queryParams = <String, String>{
        if (status != null) 'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = '${AppConstants.baseUrl}/api/users/${user.id}/corporate/bookings';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final bookings = data['data']['bookings'] as List;
      return bookings.map((b) => CorporateBooking.fromJson(b)).toList();
    } catch (e) {
      debugPrint('Failed to get corporate bookings: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<UserStatistics> getStats() async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/stats';
      final response = await _apiClient.get(url);
      final data = jsonDecode(response.body);
      return UserStatistics.fromJson(data['data']);
    } catch (e) {
      debugPrint('Failed to get user stats: $e');
      rethrow;
    }
  }

  /// Get user rewards (earned and available)
  Future<RewardsInfo> getRewards(String userId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/$userId/rewards';
      final response = await _apiClient.get(url);
      final data = jsonDecode(response.body);
      return RewardsInfo.fromJson(data['data']);
    } catch (e) {
      debugPrint('Failed to get user rewards: $e');
      rethrow;
    }
  }

  /// Get bulk bookings for corporate users
  Future<BulkBookingsResponse> getBulkBookings(
    String userId, {
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        if (status != null) 'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = '${AppConstants.baseUrl}/api/users/$userId/bulk-bookings';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      
      debugPrint('Fetching bulk bookings from: ${uri.toString()}');
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      debugPrint('Bulk bookings response: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');
      
      return BulkBookingsResponse.fromJson(data['data']);
    } catch (e) {
      debugPrint('Failed to get bulk bookings: $e');
      debugPrint('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Create a new bulk booking (corporate users only)
  /// TODO: Implement backend endpoint POST /api/users/:id/bulk-bookings
  Future<BulkBooking> createBulkBooking(
    String userId,
    Map<String, dynamic> bookingData,
  ) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/$userId/bulk-bookings';
      final response = await _apiClient.post(url, body: bookingData);

      final data = jsonDecode(response.body);
      return BulkBooking.fromJson(data['data']['booking']);
    } catch (e) {
      debugPrint('Failed to create bulk booking: $e');
      rethrow;
    }
  }

  /// Update an existing bulk booking
  /// TODO: Implement backend endpoint PUT /api/users/:id/bulk-bookings/:bookingId
  Future<BulkBooking> updateBulkBooking(
    String userId,
    String bookingId,
    Map<String, dynamic> bookingData,
  ) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/$userId/bulk-bookings/$bookingId';
      final response = await _apiClient.put(url, body: bookingData);

      final data = jsonDecode(response.body);
      return BulkBooking.fromJson(data['data']['booking']);
    } catch (e) {
      debugPrint('Failed to update bulk booking: $e');
      rethrow;
    }
  }

  /// Cancel/Delete a bulk booking
  /// Uses DELETE endpoint to remove the booking entirely from the list
  /// Endpoint: DELETE /api/users/:id/bulk-bookings/:bookingId
  Future<void> cancelBulkBooking(
    String userId,
    String bookingId,
  ) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/$userId/bulk-bookings/$bookingId';
      final response = await _apiClient.delete(url);
      debugPrint('✅ Bulk booking $bookingId deleted successfully');
      debugPrint('Response status: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Failed to delete bulk booking: $e');
      rethrow;
    }
  }

  /// Get a single bulk booking by ID
  /// TODO: Implement backend endpoint GET /api/users/:id/bulk-bookings/:bookingId
  Future<BulkBooking> getBulkBookingById(
    String userId,
    String bookingId,
  ) async {
    try {
      final url = '${AppConstants.baseUrl}/api/users/$userId/bulk-bookings/$bookingId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return BulkBooking.fromJson(data['data']['booking']);
    } catch (e) {
      debugPrint('Failed to get bulk booking: $e');
      rethrow;
    }
  }

  /// Delete user account
  /// [password] - User's password for confirmation
  /// [permanent] - If true, permanently deletes account. If false (default), deactivates account
  Future<Map<String, dynamic>> deleteAccount({
    required String password,
    bool permanent = false,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/account';
      final response = await _apiClient.delete(
        url,
        body: {
          'password': password,
          'permanent': permanent,
        },
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? '',
        'deletionType': data['deletionType'] ?? 'deactivation',
        'recoveryPeriod': data['recoveryPeriod'],
      };
    } catch (e) {
      debugPrint('Failed to delete account: $e');
      rethrow;
    }
  }
}
