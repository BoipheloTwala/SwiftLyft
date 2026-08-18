import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/special_features.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Special Features Service - handles /api/offers/* and special features endpoints
class SpecialFeaturesService {
  static final SpecialFeaturesService _instance = SpecialFeaturesService._internal();
  factory SpecialFeaturesService() => _instance;

  final ApiClient _apiClient = ApiClient();

  SpecialFeaturesService._internal();

  /// Get available promotional offers
  Future<List<PromotionalOffer>> getPromotionalOffers({
    String? userType,
    String? vehicleType,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (userType != null) 'userType': userType,
        if (vehicleType != null) 'vehicleType': vehicleType,
      };

      const url = '${AppConstants.baseUrl}/api/offers';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final offers = data['data']['offers'] as List;
      return offers.map((offer) => PromotionalOffer.fromJson(offer)).toList();
    } catch (e) {
      debugPrint('Failed to get promotional offers: $e');
      rethrow;
    }
  }

  /// Get offer by ID
  Future<PromotionalOffer> getOffer(String offerId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/offers/$offerId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return PromotionalOffer.fromJson(data['data']['offer']);
    } catch (e) {
      debugPrint('Failed to get offer: $e');
      rethrow;
    }
  }

  /// Apply promotional code
  Future<PromoCodeValidation> applyPromoCode({
    required String code,
    required double bookingAmount,
    String? vehicleType,
    Map<String, dynamic>? bookingDetails,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/offers/apply-code';
      final response = await _apiClient.post(url, body: {
        'code': code,
        'bookingAmount': bookingAmount,
        'vehicleType': vehicleType,
        'bookingDetails': bookingDetails,
      });

      final data = jsonDecode(response.body);
      return PromoCodeValidation.fromJson(data['data']['validation']);
    } catch (e) {
      debugPrint('Failed to apply promo code: $e');
      rethrow;
    }
  }

  /// Validate promotional code
  Future<PromoCodeValidation> validatePromoCode({
    required String code,
    required double bookingAmount,
    String? vehicleType,
  }) async {
    try {
      final queryParams = <String, String>{
        'code': code,
        'bookingAmount': bookingAmount.toString(),
        if (vehicleType != null) 'vehicleType': vehicleType,
      };

      const url = '${AppConstants.baseUrl}/api/offers/validate-code';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return PromoCodeValidation.fromJson(data['data']['validation']);
    } catch (e) {
      debugPrint('Failed to validate promo code: $e');
      rethrow;
    }
  }

  /// Get loyalty rewards
  Future<List<LoyaltyReward>> getLoyaltyRewards({
    String? tier,
    bool? availableOnly = true,
  }) async {
    try {
      final queryParams = <String, String>{
        if (tier != null) 'tier': tier,
        if (availableOnly != null) 'availableOnly': availableOnly.toString(),
      };

      const url = '${AppConstants.baseUrl}/api/loyalty/rewards';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final rewards = data['data']['rewards'] as List;
      return rewards.map((reward) => LoyaltyReward.fromJson(reward)).toList();
    } catch (e) {
      debugPrint('Failed to get loyalty rewards: $e');
      rethrow;
    }
  }

  /// Redeem loyalty reward
  Future<LoyaltyRedemption> redeemReward({
    required String rewardId,
    Map<String, dynamic>? redemptionData,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/loyalty/redeem';
      final response = await _apiClient.post(url, body: {
        'rewardId': rewardId,
        'redemptionData': redemptionData,
      });

      final data = jsonDecode(response.body);
      return LoyaltyRedemption.fromJson(data['data']['redemption']);
    } catch (e) {
      debugPrint('Failed to redeem reward: $e');
      rethrow;
    }
  }

  /// Get user loyalty status
  Future<LoyaltyStatus> getLoyaltyStatus() async {
    try {
      const url = '${AppConstants.baseUrl}/api/loyalty/status';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return LoyaltyStatus.fromJson(data['data']['status']);
    } catch (e) {
      debugPrint('Failed to get loyalty status: $e');
      rethrow;
    }
  }

  /// Get corporate booking options
  Future<List<CorporatePlan>> getCorporatePlans() async {
    try {
      const url = '${AppConstants.baseUrl}/api/corporate/plans';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final plans = data['data']['plans'] as List;
      return plans.map((plan) => CorporatePlan.fromJson(plan)).toList();
    } catch (e) {
      debugPrint('Failed to get corporate plans: $e');
      rethrow;
    }
  }

  /// Create corporate booking
  Future<CorporateBooking> createCorporateBooking({
    required String planId,
    required List<Map<String, dynamic>> bookings,
    Map<String, dynamic>? billingInfo,
    String? specialInstructions,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/corporate/bookings';
      final response = await _apiClient.post(url, body: {
        'planId': planId,
        'bookings': bookings,
        'billingInfo': billingInfo,
        'specialInstructions': specialInstructions,
      });

      final data = jsonDecode(response.body);
      return CorporateBooking.fromJson(data['data']['booking']);
    } catch (e) {
      debugPrint('Failed to create corporate booking: $e');
      rethrow;
    }
  }

  /// Get bulk booking options
  Future<BulkBookingOptions> getBulkBookingOptions({
    required int numberOfBookings,
    String? vehicleType,
    DateTime? preferredDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'numberOfBookings': numberOfBookings.toString(),
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (preferredDate != null) 'preferredDate': preferredDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/bulk/options';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return BulkBookingOptions.fromJson(data['data']['options']);
    } catch (e) {
      debugPrint('Failed to get bulk booking options: $e');
      rethrow;
    }
  }

  /// Create bulk booking
  Future<BulkBooking> createBulkBooking({
    required List<Map<String, dynamic>> bookings,
    Map<String, dynamic>? discountCode,
    String? contactPerson,
    String? specialNotes,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/bulk/bookings';
      final response = await _apiClient.post(url, body: {
        'bookings': bookings,
        'discountCode': discountCode,
        'contactPerson': contactPerson,
        'specialNotes': specialNotes,
      });

      final data = jsonDecode(response.body);
      return BulkBooking.fromJson(data['data']['booking']);
    } catch (e) {
      debugPrint('Failed to create bulk booking: $e');
      rethrow;
    }
  }

  /// Get airport transfer services
  Future<List<AirportService>> getAirportServices({
    String? airport,
    String? direction,
  }) async {
    try {
      final queryParams = <String, String>{
        if (airport != null) 'airport': airport,
        if (direction != null) 'direction': direction,
      };

      const url = '${AppConstants.baseUrl}/api/airport/services';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final services = data['data']['services'] as List;
      return services.map((service) => AirportService.fromJson(service)).toList();
    } catch (e) {
      debugPrint('Failed to get airport services: $e');
      rethrow;
    }
  }

  /// Get security services
  Future<List<SecurityService>> getSecurityServices({
    String? serviceType,
    int? duration,
  }) async {
    try {
      final queryParams = <String, String>{
        if (serviceType != null) 'serviceType': serviceType,
        if (duration != null) 'duration': duration.toString(),
      };

      const url = '${AppConstants.baseUrl}/api/security/services';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final services = data['data']['services'] as List;
      return services.map((service) => SecurityService.fromJson(service)).toList();
    } catch (e) {
      debugPrint('Failed to get security services: $e');
      rethrow;
    }
  }

  /// Request special service
  Future<SpecialServiceRequest> requestSpecialService({
    required String serviceType,
    required Map<String, dynamic> serviceDetails,
    required DateTime requestedDate,
    String? specialInstructions,
    Map<String, dynamic>? contactInfo,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/special-services/request';
      final response = await _apiClient.post(url, body: {
        'serviceType': serviceType,
        'serviceDetails': serviceDetails,
        'requestedDate': requestedDate.toIso8601String(),
        'specialInstructions': specialInstructions,
        'contactInfo': contactInfo,
      });

      final data = jsonDecode(response.body);
      return SpecialServiceRequest.fromJson(data['data']['request']);
    } catch (e) {
      debugPrint('Failed to request special service: $e');
      rethrow;
    }
  }

  /// Get referral program info
  Future<ReferralProgram> getReferralProgram() async {
    try {
      const url = '${AppConstants.baseUrl}/api/referral/program';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return ReferralProgram.fromJson(data['data']['program']);
    } catch (e) {
      debugPrint('Failed to get referral program: $e');
      rethrow;
    }
  }

  /// Get referral stats
  Future<ReferralStats> getReferralStats() async {
    try {
      const url = '${AppConstants.baseUrl}/api/referral/stats';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return ReferralStats.fromJson(data['data']['stats']);
    } catch (e) {
      debugPrint('Failed to get referral stats: $e');
      rethrow;
    }
  }

  /// Generate referral code
  Future<String> generateReferralCode() async {
    try {
      const url = '${AppConstants.baseUrl}/api/referral/generate-code';
      final response = await _apiClient.post(url);

      final data = jsonDecode(response.body);
      return data['data']['code'];
    } catch (e) {
      debugPrint('Failed to generate referral code: $e');
      rethrow;
    }
  }

  /// Share referral
  Future<void> shareReferral({
    required String referralCode,
    required List<String> recipientEmails,
    String? personalMessage,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/referral/share';
      await _apiClient.post(url, body: {
        'referralCode': referralCode,
        'recipientEmails': recipientEmails,
        'personalMessage': personalMessage,
      });
    } catch (e) {
      debugPrint('Failed to share referral: $e');
      rethrow;
    }
  }

  /// Get special offers for user
  Future<List<PersonalizedOffer>> getPersonalizedOffers() async {
    try {
      const url = '${AppConstants.baseUrl}/api/personalized/offers';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final offers = data['data']['offers'] as List;
      return offers.map((offer) => PersonalizedOffer.fromJson(offer)).toList();
    } catch (e) {
      debugPrint('Failed to get personalized offers: $e');
      rethrow;
    }
  }

  /// Track offer interaction
  Future<void> trackOfferInteraction({
    required String offerId,
    required String interactionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/offers/$offerId/interaction';
      await _apiClient.post(url, body: {
        'interactionType': interactionType,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Failed to track offer interaction: $e');
      rethrow;
    }
  }
}
