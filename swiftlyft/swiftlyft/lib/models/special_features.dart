/// Promotional offer model
class PromotionalOffer {
  final String id;
  final String title;
  final String description;
  final String code;
  final String discountType; // 'percentage', 'fixed', 'free'
  final double discountValue;
  final double? minimumAmount;
  final double? maximumDiscount;
  final Map<String, dynamic> conditions;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int usageLimit;
  final int usageCount;
  final List<String> applicableServices;
  final List<String> applicableUsers;
  final String? imageUrl;
  final DateTime createdAt;

  PromotionalOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minimumAmount,
    this.maximumDiscount,
    required this.conditions,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.usageLimit,
    required this.usageCount,
    required this.applicableServices,
    required this.applicableUsers,
    this.imageUrl,
    required this.createdAt,
  });

  factory PromotionalOffer.fromJson(Map<String, dynamic> json) {
    return PromotionalOffer(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0.0).toDouble(),
      minimumAmount: json['minimumAmount'] != null ? (json['minimumAmount'] as num).toDouble() : null,
      maximumDiscount: json['maximumDiscount'] != null ? (json['maximumDiscount'] as num).toDouble() : null,
      conditions: json['conditions'] ?? {},
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      usageLimit: json['usageLimit'] ?? 0,
      usageCount: json['usageCount'] ?? 0,
      applicableServices: List<String>.from(json['applicableServices'] ?? []),
      applicableUsers: List<String>.from(json['applicableUsers'] ?? []),
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'minimumAmount': minimumAmount,
      'maximumDiscount': maximumDiscount,
      'conditions': conditions,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'applicableServices': applicableServices,
      'applicableUsers': applicableUsers,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Promo code validation model
class PromoCodeValidation {
  final bool isValid;
  final String? errorMessage;
  final PromotionalOffer? offer;
  final double? discountAmount;
  final double? finalAmount;

  PromoCodeValidation({
    required this.isValid,
    this.errorMessage,
    this.offer,
    this.discountAmount,
    this.finalAmount,
  });

  factory PromoCodeValidation.fromJson(Map<String, dynamic> json) {
    return PromoCodeValidation(
      isValid: json['isValid'] ?? false,
      errorMessage: json['errorMessage'],
      offer: json['offer'] != null ? PromotionalOffer.fromJson(json['offer']) : null,
      discountAmount: json['discountAmount'] != null ? (json['discountAmount'] as num).toDouble() : null,
      finalAmount: json['finalAmount'] != null ? (json['finalAmount'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'errorMessage': errorMessage,
      'offer': offer?.toJson(),
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
    };
  }
}

/// Loyalty reward model
class LoyaltyReward {
  final String id;
  final String name;
  final String description;
  final String type; // 'discount', 'free_service', 'upgrade', 'points_multiplier'
  final Map<String, dynamic> rewardValue;
  final int pointsRequired;
  final String tierRequired;
  final bool isActive;
  final int maxClaims;
  final int claimsCount;
  final DateTime? expiryDate;
  final DateTime createdAt;

  LoyaltyReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rewardValue,
    required this.pointsRequired,
    required this.tierRequired,
    required this.isActive,
    required this.maxClaims,
    required this.claimsCount,
    this.expiryDate,
    required this.createdAt,
  });

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'discount',
      rewardValue: json['rewardValue'] ?? {},
      pointsRequired: json['pointsRequired'] ?? 0,
      tierRequired: json['tierRequired'] ?? 'Bronze',
      isActive: json['isActive'] ?? true,
      maxClaims: json['maxClaims'] ?? 0,
      claimsCount: json['claimsCount'] ?? 0,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'rewardValue': rewardValue,
      'pointsRequired': pointsRequired,
      'tierRequired': tierRequired,
      'isActive': isActive,
      'maxClaims': maxClaims,
      'claimsCount': claimsCount,
      'expiryDate': expiryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Loyalty redemption model
class LoyaltyRedemption {
  final String id;
  final String userId;
  final String rewardId;
  final int pointsUsed;
  final Map<String, dynamic> redemptionData;
  final String status;
  final DateTime redeemedAt;
  final DateTime? usedAt;

  LoyaltyRedemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.pointsUsed,
    required this.redemptionData,
    required this.status,
    required this.redeemedAt,
    this.usedAt,
  });

  factory LoyaltyRedemption.fromJson(Map<String, dynamic> json) {
    return LoyaltyRedemption(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      rewardId: json['rewardId'] ?? '',
      pointsUsed: json['pointsUsed'] ?? 0,
      redemptionData: json['redemptionData'] ?? {},
      status: json['status'] ?? 'pending',
      redeemedAt: DateTime.parse(json['redeemedAt'] ?? DateTime.now().toIso8601String()),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rewardId': rewardId,
      'pointsUsed': pointsUsed,
      'redemptionData': redemptionData,
      'status': status,
      'redeemedAt': redeemedAt.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
    };
  }
}

/// Loyalty status model
class LoyaltyStatus {
  final String userId;
  final String currentTier;
  final int currentPoints;
  final int pointsToNextTier;
  final int totalPointsEarned;
  final int totalPointsSpent;
  final List<LoyaltyReward> availableRewards;
  final List<LoyaltyRedemption> recentRedemptions;
  final Map<String, dynamic> tierBenefits;
  final DateTime lastUpdated;

  LoyaltyStatus({
    required this.userId,
    required this.currentTier,
    required this.currentPoints,
    required this.pointsToNextTier,
    required this.totalPointsEarned,
    required this.totalPointsSpent,
    required this.availableRewards,
    required this.recentRedemptions,
    required this.tierBenefits,
    required this.lastUpdated,
  });

  factory LoyaltyStatus.fromJson(Map<String, dynamic> json) {
    return LoyaltyStatus(
      userId: json['userId'] ?? '',
      currentTier: json['currentTier'] ?? 'Bronze',
      currentPoints: json['currentPoints'] ?? 0,
      pointsToNextTier: json['pointsToNextTier'] ?? 0,
      totalPointsEarned: json['totalPointsEarned'] ?? 0,
      totalPointsSpent: json['totalPointsSpent'] ?? 0,
      availableRewards: (json['availableRewards'] as List<dynamic>?)
          ?.map((reward) => LoyaltyReward.fromJson(reward))
          .toList() ?? [],
      recentRedemptions: (json['recentRedemptions'] as List<dynamic>?)
          ?.map((redemption) => LoyaltyRedemption.fromJson(redemption))
          .toList() ?? [],
      tierBenefits: json['tierBenefits'] ?? {},
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentTier': currentTier,
      'currentPoints': currentPoints,
      'pointsToNextTier': pointsToNextTier,
      'totalPointsEarned': totalPointsEarned,
      'totalPointsSpent': totalPointsSpent,
      'availableRewards': availableRewards.map((reward) => reward.toJson()).toList(),
      'recentRedemptions': recentRedemptions.map((redemption) => redemption.toJson()).toList(),
      'tierBenefits': tierBenefits,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Corporate plan model
class CorporatePlan {
  final String id;
  final String name;
  final String description;
  final String billingCycle; // 'monthly', 'quarterly', 'yearly'
  final double basePrice;
  final int maxBookings;
  final int maxUsers;
  final List<String> includedServices;
  final Map<String, dynamic> discounts;
  final Map<String, dynamic> features;
  final bool isActive;
  final DateTime createdAt;

  CorporatePlan({
    required this.id,
    required this.name,
    required this.description,
    required this.billingCycle,
    required this.basePrice,
    required this.maxBookings,
    required this.maxUsers,
    required this.includedServices,
    required this.discounts,
    required this.features,
    required this.isActive,
    required this.createdAt,
  });

  factory CorporatePlan.fromJson(Map<String, dynamic> json) {
    return CorporatePlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      billingCycle: json['billingCycle'] ?? 'monthly',
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      maxBookings: json['maxBookings'] ?? 0,
      maxUsers: json['maxUsers'] ?? 0,
      includedServices: List<String>.from(json['includedServices'] ?? []),
      discounts: json['discounts'] ?? {},
      features: json['features'] ?? {},
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'billingCycle': billingCycle,
      'basePrice': basePrice,
      'maxBookings': maxBookings,
      'maxUsers': maxUsers,
      'includedServices': includedServices,
      'discounts': discounts,
      'features': features,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Corporate booking model
class CorporateBooking {
  final String id;
  final String companyId;
  final String planId;
  final List<Map<String, dynamic>> bookings;
  final Map<String, dynamic> billingInfo;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? processedAt;

  CorporateBooking({
    required this.id,
    required this.companyId,
    required this.planId,
    required this.bookings,
    required this.billingInfo,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.processedAt,
  });

  factory CorporateBooking.fromJson(Map<String, dynamic> json) {
    return CorporateBooking(
      id: json['id'] ?? '',
      companyId: json['companyId'] ?? '',
      planId: json['planId'] ?? '',
      bookings: List<Map<String, dynamic>>.from(json['bookings'] ?? []),
      billingInfo: json['billingInfo'] ?? {},
      status: json['status'] ?? 'pending',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'planId': planId,
      'bookings': bookings,
      'billingInfo': billingInfo,
      'status': status,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}

/// Bulk booking options model
class BulkBookingOptions {
  final int maxBookings;
  final double discountPercentage;
  final double totalSavings;
  final Map<String, dynamic> pricingBreakdown;
  final List<String> availableVehicles;
  final DateTime validUntil;

  BulkBookingOptions({
    required this.maxBookings,
    required this.discountPercentage,
    required this.totalSavings,
    required this.pricingBreakdown,
    required this.availableVehicles,
    required this.validUntil,
  });

  factory BulkBookingOptions.fromJson(Map<String, dynamic> json) {
    return BulkBookingOptions(
      maxBookings: json['maxBookings'] ?? 0,
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      totalSavings: (json['totalSavings'] ?? 0.0).toDouble(),
      pricingBreakdown: json['pricingBreakdown'] ?? {},
      availableVehicles: List<String>.from(json['availableVehicles'] ?? []),
      validUntil: DateTime.parse(json['validUntil'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxBookings': maxBookings,
      'discountPercentage': discountPercentage,
      'totalSavings': totalSavings,
      'pricingBreakdown': pricingBreakdown,
      'availableVehicles': availableVehicles,
      'validUntil': validUntil.toIso8601String(),
    };
  }
}

/// Bulk booking model
class BulkBooking {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> bookings;
  final Map<String, dynamic> discountCode;
  final String? contactPerson;
  final String? specialNotes;
  final String status;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final DateTime createdAt;
  final DateTime? processedAt;

  BulkBooking({
    required this.id,
    required this.userId,
    required this.bookings,
    required this.discountCode,
    this.contactPerson,
    this.specialNotes,
    required this.status,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.createdAt,
    this.processedAt,
  });

  factory BulkBooking.fromJson(Map<String, dynamic> json) {
    return BulkBooking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      bookings: List<Map<String, dynamic>>.from(json['bookings'] ?? []),
      discountCode: json['discountCode'] ?? {},
      contactPerson: json['contactPerson'],
      specialNotes: json['specialNotes'],
      status: json['status'] ?? 'pending',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookings': bookings,
      'discountCode': discountCode,
      'contactPerson': contactPerson,
      'specialNotes': specialNotes,
      'status': status,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}

/// Airport service model
class AirportService {
  final String id;
  final String airportCode;
  final String airportName;
  final String serviceType; // 'pickup', 'dropoff', 'transfer'
  final double basePrice;
  final Map<String, dynamic> pricing;
  final Map<String, dynamic> availability;
  final List<String> terminals;
  final Map<String, dynamic> requirements;
  final bool isActive;
  final DateTime createdAt;

  AirportService({
    required this.id,
    required this.airportCode,
    required this.airportName,
    required this.serviceType,
    required this.basePrice,
    required this.pricing,
    required this.availability,
    required this.terminals,
    required this.requirements,
    required this.isActive,
    required this.createdAt,
  });

  factory AirportService.fromJson(Map<String, dynamic> json) {
    return AirportService(
      id: json['id'] ?? '',
      airportCode: json['airportCode'] ?? '',
      airportName: json['airportName'] ?? '',
      serviceType: json['serviceType'] ?? 'pickup',
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      pricing: json['pricing'] ?? {},
      availability: json['availability'] ?? {},
      terminals: List<String>.from(json['terminals'] ?? []),
      requirements: json['requirements'] ?? {},
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airportCode': airportCode,
      'airportName': airportName,
      'serviceType': serviceType,
      'basePrice': basePrice,
      'pricing': pricing,
      'availability': availability,
      'terminals': terminals,
      'requirements': requirements,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Security service model
class SecurityService {
  final String id;
  final String name;
  final String description;
  final String serviceType;
  final double basePrice;
  final Duration duration;
  final Map<String, dynamic> pricing;
  final Map<String, dynamic> requirements;
  final List<String> certifications;
  final bool isActive;
  final DateTime createdAt;

  SecurityService({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceType,
    required this.basePrice,
    required this.duration,
    required this.pricing,
    required this.requirements,
    required this.certifications,
    required this.isActive,
    required this.createdAt,
  });

  factory SecurityService.fromJson(Map<String, dynamic> json) {
    return SecurityService(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      serviceType: json['serviceType'] ?? '',
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      duration: Duration(hours: json['duration'] ?? 1),
      pricing: json['pricing'] ?? {},
      requirements: json['requirements'] ?? {},
      certifications: List<String>.from(json['certifications'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'serviceType': serviceType,
      'basePrice': basePrice,
      'duration': duration.inHours,
      'pricing': pricing,
      'requirements': requirements,
      'certifications': certifications,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Special service request model
class SpecialServiceRequest {
  final String id;
  final String userId;
  final String serviceType;
  final Map<String, dynamic> serviceDetails;
  final DateTime requestedDate;
  final String? specialInstructions;
  final Map<String, dynamic> contactInfo;
  final String status;
  final Map<String, dynamic> response;
  final DateTime createdAt;
  final DateTime? processedAt;

  SpecialServiceRequest({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.serviceDetails,
    required this.requestedDate,
    this.specialInstructions,
    required this.contactInfo,
    required this.status,
    required this.response,
    required this.createdAt,
    this.processedAt,
  });

  factory SpecialServiceRequest.fromJson(Map<String, dynamic> json) {
    return SpecialServiceRequest(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceType: json['serviceType'] ?? '',
      serviceDetails: json['serviceDetails'] ?? {},
      requestedDate: DateTime.parse(json['requestedDate'] ?? DateTime.now().toIso8601String()),
      specialInstructions: json['specialInstructions'],
      contactInfo: json['contactInfo'] ?? {},
      status: json['status'] ?? 'pending',
      response: json['response'] ?? {},
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceType': serviceType,
      'serviceDetails': serviceDetails,
      'requestedDate': requestedDate.toIso8601String(),
      'specialInstructions': specialInstructions,
      'contactInfo': contactInfo,
      'status': status,
      'response': response,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}

/// Referral program model
class ReferralProgram {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> rewards;
  final int maxReferrals;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final Map<String, dynamic> terms;
  final DateTime createdAt;

  ReferralProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.rewards,
    required this.maxReferrals,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.terms,
    required this.createdAt,
  });

  factory ReferralProgram.fromJson(Map<String, dynamic> json) {
    return ReferralProgram(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      rewards: json['rewards'] ?? {},
      maxReferrals: json['maxReferrals'] ?? 0,
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
      terms: json['terms'] ?? {},
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rewards': rewards,
      'maxReferrals': maxReferrals,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'terms': terms,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Referral model
class Referral {
  final String id;
  final String referredUserId;
  final String referredUserEmail;
  final String referredUserName;
  final String status; // 'pending', 'completed', 'cancelled'
  final double earnings;
  final DateTime createdAt;
  final DateTime? completedAt;

  Referral({
    required this.id,
    required this.referredUserId,
    required this.referredUserEmail,
    required this.referredUserName,
    required this.status,
    required this.earnings,
    required this.createdAt,
    this.completedAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    // Handle referredUserId which might be an object or string
    String userId = '';
    if (json['referredUserId'] is String) {
      userId = json['referredUserId'];
    } else if (json['referredUserId'] is Map && (json['referredUserId'] as Map).isNotEmpty) {
      userId = json['referredUserId']['id'] ?? json['referredUserId']['\$oid'] ?? '';
    }

    // Handle createdAt which might be an object or string
    DateTime created = DateTime.now();
    try {
      if (json['createdAt'] is String) {
        created = DateTime.parse(json['createdAt']);
      } else if (json['createdAt'] is Map) {
        // MongoDB date object format
        created = DateTime.parse(json['createdAt']['\$date'] ?? DateTime.now().toIso8601String());
      }
    } catch (e) {
      created = DateTime.now();
    }

    // Handle completedAt similarly
    DateTime? completed;
    try {
      if (json['completedAt'] != null) {
        if (json['completedAt'] is String) {
          completed = DateTime.parse(json['completedAt']);
        } else if (json['completedAt'] is Map) {
          completed = DateTime.parse(json['completedAt']['\$date'] ?? '');
        }
      }
    } catch (e) {
      completed = null;
    }

    return Referral(
      id: json['id'] ?? '',
      referredUserId: userId,
      referredUserEmail: json['referredUserEmail'] ?? '',
      referredUserName: json['referredUserName'] ?? '',
      status: json['status'] ?? 'pending',
      earnings: (json['earnings'] ?? 0.0).toDouble(),
      createdAt: created,
      completedAt: completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referredUserId': referredUserId,
      'referredUserEmail': referredUserEmail,
      'referredUserName': referredUserName,
      'status': status,
      'earnings': earnings,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

/// Referral stats model
class ReferralStats {
  final String userId;
  final String referralCode;
  final int totalReferrals;
  final int successfulReferrals;
  final double totalEarnings;
  final List<Referral> referrals;
  final Map<String, dynamic> rewards;
  final DateTime lastUpdated;

  ReferralStats({
    required this.userId,
    required this.referralCode,
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.totalEarnings,
    required this.referrals,
    required this.rewards,
    required this.lastUpdated,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      userId: json['userId'] ?? '',
      referralCode: json['referralCode'] ?? '',
      totalReferrals: json['totalReferrals'] ?? 0,
      successfulReferrals: json['successfulReferrals'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      referrals: (json['referrals'] as List<dynamic>?)
          ?.map((referral) => Referral.fromJson(referral))
          .toList() ?? [],
      rewards: json['rewards'] ?? {},
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'referralCode': referralCode,
      'totalReferrals': totalReferrals,
      'successfulReferrals': successfulReferrals,
      'totalEarnings': totalEarnings,
      'referrals': referrals.map((referral) => referral.toJson()).toList(),
      'rewards': rewards,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Personalized offer model
class PersonalizedOffer {
  final String id;
  final String userId;
  final String offerType;
  final String title;
  final String description;
  final Map<String, dynamic> offerDetails;
  final DateTime validUntil;
  final bool isActive;
  final Map<String, dynamic> targetingCriteria;
  final DateTime createdAt;

  PersonalizedOffer({
    required this.id,
    required this.userId,
    required this.offerType,
    required this.title,
    required this.description,
    required this.offerDetails,
    required this.validUntil,
    required this.isActive,
    required this.targetingCriteria,
    required this.createdAt,
  });

  factory PersonalizedOffer.fromJson(Map<String, dynamic> json) {
    return PersonalizedOffer(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      offerType: json['offerType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      offerDetails: json['offerDetails'] ?? {},
      validUntil: DateTime.parse(json['validUntil'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      targetingCriteria: json['targetingCriteria'] ?? {},
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'offerType': offerType,
      'title': title,
      'description': description,
      'offerDetails': offerDetails,
      'validUntil': validUntil.toIso8601String(),
      'isActive': isActive,
      'targetingCriteria': targetingCriteria,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
