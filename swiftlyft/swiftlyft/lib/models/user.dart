import 'package:flutter/foundation.dart';
import 'special_features.dart' show Referral;
import 'corporate.dart';

class User {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String loyaltyTier;
  final int loyaltyPoints;
  final int totalTrips;
  final double totalSpent;
  final List<String> savedAddresses;
  final List<String> paymentMethods;
  final List<LoyaltyReward> earnedRewards;
  final List<LoyaltyReward> availableRewards;
  final String? referralCode;
  final String? referredBy;
  final List<Referral> referrals;
  final CorporateAccount? corporateAccount;
  final List<CorporateBooking> bulkBookings;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  User({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.loyaltyTier = 'Bronze',
    this.loyaltyPoints = 0,
    this.totalTrips = 0,
    this.totalSpent = 0.0,
    this.savedAddresses = const [],
    this.paymentMethods = const [],
    this.earnedRewards = const [],
    this.availableRewards = const [],
    this.referralCode,
    this.referredBy,
    this.referrals = const [],
    this.corporateAccount,
    this.bulkBookings = const [],
    required this.createdAt,
    required this.lastLoginAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  // Loyalty program methods
  int get pointsToNextTier {
    switch (loyaltyTier) {
      case 'Bronze':
        return 1000 - loyaltyPoints;
      case 'Silver':
        return 2500 - loyaltyPoints;
      case 'Gold':
        return 5000 - loyaltyPoints;
      case 'Platinum':
        return 10000 - loyaltyPoints;
      default:
        return 0;
    }
  }

  double get tierProgress {
    switch (loyaltyTier) {
      case 'Bronze':
        return loyaltyPoints / 1000.0;
      case 'Silver':
        return (loyaltyPoints - 1000) / 1500.0;
      case 'Gold':
        return (loyaltyPoints - 2500) / 2500.0;
      case 'Platinum':
        return (loyaltyPoints - 5000) / 5000.0;
      default:
        return 1.0;
    }
  }

  String get nextTier {
    switch (loyaltyTier) {
      case 'Bronze':
        return 'Silver';
      case 'Silver':
        return 'Gold';
      case 'Gold':
        return 'Platinum';
      case 'Platinum':
        return 'Diamond';
      default:
        return 'Bronze';
    }
  }

  double get tierDiscount {
    switch (loyaltyTier) {
      case 'Bronze':
        return 0.0;
      case 'Silver':
        return 0.05; // 5% discount
      case 'Gold':
        return 0.10; // 10% discount
      case 'Platinum':
        return 0.15; // 15% discount
      case 'Diamond':
        return 0.20; // 20% discount
      default:
        return 0.0;
    }
  }

  // Check if user has corporate account
  bool get isCorporateUser => corporateAccount != null;
  
  // Get corporate discount
  double get corporateDiscount {
    if (corporateAccount == null) return 0.0;
    return corporateAccount!.discountPercentage;
  }

  // Get total discount (loyalty + corporate)
  double get totalDiscount {
    return tierDiscount + corporateDiscount;
  }

  // Generate referral code if not exists
  String get getReferralCode {
    if (referralCode != null) return referralCode!;
    // Generate a unique referral code based on user ID
    return 'REF${id.substring(0, 8).toUpperCase()}';
  }

  // Calculate referral earnings
  double get referralEarnings {
    return referrals.fold(0.0, (sum, referral) => sum + referral.earnings);
  }

  // Get successful referrals count
  int get successfulReferrals {
    return referrals.where((r) => r.status == 'completed').length;
  }

  // Get pending referrals count
  int get pendingReferrals {
    return referrals.where((r) => r.status == 'pending').length;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('🔍 Parsing User - step by step...');
      
      final id = json['id'] ?? '';
      debugPrint('  ✓ id');
      final email = json['email'] ?? '';
      debugPrint('  ✓ email');
      final name = json['name'];
      debugPrint('  ✓ name');
      final phoneNumber = json['phoneNumber'];
      debugPrint('  ✓ phoneNumber');
      final profileImageUrl = json['profileImageUrl'];
      debugPrint('  ✓ profileImageUrl');
      final loyaltyTier = json['loyaltyTier'] ?? 'Bronze';
      debugPrint('  ✓ loyaltyTier');
      final loyaltyPoints = json['loyaltyPoints'] ?? 0;
      debugPrint('  ✓ loyaltyPoints');
      final totalTrips = json['totalTrips'] ?? 0;
      debugPrint('  ✓ totalTrips');
      final totalSpent = (json['totalSpent'] ?? 0.0).toDouble();
      debugPrint('  ✓ totalSpent');
      
      debugPrint('  🔍 Parsing savedAddresses...');
      final savedAddresses = (json['savedAddresses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      debugPrint('  ✓ savedAddresses');
      
      debugPrint('  🔍 Parsing paymentMethods...');
      final paymentMethods = (json['paymentMethods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      debugPrint('  ✓ paymentMethods');
      
      debugPrint('  🔍 Parsing earnedRewards...');
      final earnedRewards = (json['earnedRewards'] as List<dynamic>?)
          ?.map((r) => LoyaltyReward.fromJson(r))
          .toList() ?? [];
      debugPrint('  ✓ earnedRewards');
      
      debugPrint('  🔍 Parsing availableRewards...');
      final availableRewards = (json['availableRewards'] as List<dynamic>?)
          ?.map((r) => LoyaltyReward.fromJson(r))
          .toList() ?? [];
      debugPrint('  ✓ availableRewards');
      
      final referralCode = json['referralCode'];
      debugPrint('  ✓ referralCode');
      final referredBy = json['referredBy'] is String ? json['referredBy'] : null;
      debugPrint('  ✓ referredBy');
      
      debugPrint('  🔍 Parsing referrals...');
      final referrals = (json['referrals'] as List<dynamic>?)
          ?.map((r) => Referral.fromJson(r))
          .toList() ?? [];
      debugPrint('  ✓ referrals');
      
      // Parse corporateAccount - manually to avoid type conversion issues
      CorporateAccount? corporateAccount;
      if (json['corporateAccount'] != null) {
        try {
          final corpData = json['corporateAccount'] as Map;
          
          // Manually extract each field with safe type conversion
          final id = (corpData['id'] ?? '').toString();
          final companyName = (corpData['companyName'] ?? '').toString();
          final companyEmail = (corpData['companyEmail'] ?? '').toString();
          final contactPerson = (corpData['contactPerson'] ?? '').toString();
          final contactPhone = (corpData['contactPhone'] ?? '').toString();
          final discountPercentage = (corpData['discountPercentage'] ?? 0.0).toDouble();
          final monthlyBudget = (corpData['monthlyBudget'] ?? 0.0).toDouble();
          final usedBudget = (corpData['usedBudget'] ?? 0.0).toDouble();
          final status = (corpData['status'] ?? 'pending').toString();
          
          // Parse dates safely
          DateTime createdAt = DateTime.now();
          if (corpData['createdAt'] != null && corpData['createdAt'] is String && (corpData['createdAt'] as String).isNotEmpty) {
            try {
              createdAt = DateTime.parse(corpData['createdAt']);
            } catch (_) {
              // Use default if parsing fails
            }
          }
          
          DateTime? expiresAt;
          if (corpData['expiresAt'] != null && corpData['expiresAt'] is String && (corpData['expiresAt'] as String).isNotEmpty) {
            try {
              expiresAt = DateTime.parse(corpData['expiresAt']);
            } catch (_) {
              // Null if parsing fails
            }
          }
          
          final authorizedUsers = (corpData['authorizedUsers'] as List?)
              ?.map((e) => e.toString())
              .toList() ?? [];
          
          // Create CorporateAccount directly using constructor
          corporateAccount = CorporateAccount(
            id: id,
            companyName: companyName,
            companyEmail: companyEmail,
            contactPerson: contactPerson,
            contactPhone: contactPhone,
            discountPercentage: discountPercentage,
            monthlyBudget: monthlyBudget,
            usedBudget: usedBudget,
            status: status,
            createdAt: createdAt,
            expiresAt: expiresAt,
            authorizedUsers: authorizedUsers,
          );
        } catch (e) {
          debugPrint('Failed to parse corporateAccount: $e');
          corporateAccount = null;
        }
      }
      
      debugPrint('  🔍 Parsing bulkBookings...');
      final bulkBookings = (json['bulkBookings'] as List<dynamic>?)
          ?.map((b) => CorporateBooking.fromJson(b))
          .toList() ?? [];
      debugPrint('  ✓ bulkBookings');
      
      debugPrint('  🔍 Parsing createdAt...');
      final createdAt = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
      debugPrint('  ✓ createdAt');
      
      debugPrint('  🔍 Parsing lastLoginAt...');
      final lastLoginAt = DateTime.parse(json['lastLoginAt'] ?? DateTime.now().toIso8601String());
      debugPrint('  ✓ lastLoginAt');
      
      final isEmailVerified = json['isEmailVerified'] ?? false;
      debugPrint('  ✓ isEmailVerified');
      final isPhoneVerified = json['isPhoneVerified'] ?? false;
      debugPrint('  ✓ isPhoneVerified');
      
      debugPrint('✅ All User fields parsed, creating User object...');
      
      return User(
        id: id,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        loyaltyTier: loyaltyTier,
        loyaltyPoints: loyaltyPoints,
        totalTrips: totalTrips,
        totalSpent: totalSpent,
        savedAddresses: savedAddresses,
        paymentMethods: paymentMethods,
        earnedRewards: earnedRewards,
        availableRewards: availableRewards,
        referralCode: referralCode,
        referredBy: referredBy,
        referrals: referrals,
        corporateAccount: corporateAccount,
        bulkBookings: bulkBookings,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt,
        isEmailVerified: isEmailVerified,
        isPhoneVerified: isPhoneVerified,
      );
    } catch (e) {
      debugPrint('❌ User.fromJson error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'loyaltyTier': loyaltyTier,
      'loyaltyPoints': loyaltyPoints,
      'totalTrips': totalTrips,
      'totalSpent': totalSpent,
      'savedAddresses': savedAddresses,
      'paymentMethods': paymentMethods,
      'earnedRewards': earnedRewards.map((r) => r.toJson()).toList(),
      'availableRewards': availableRewards.map((r) => r.toJson()).toList(),
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referrals': referrals.map((r) => r.toJson()).toList(),
      'corporateAccount': corporateAccount?.toJson(),
      'bulkBookings': bulkBookings.map((b) => b.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? loyaltyTier,
    int? loyaltyPoints,
    int? totalTrips,
    double? totalSpent,
    List<String>? savedAddresses,
    List<String>? paymentMethods,
    List<LoyaltyReward>? earnedRewards,
    List<LoyaltyReward>? availableRewards,
    String? referralCode,
    String? referredBy,
    List<Referral>? referrals,
    CorporateAccount? corporateAccount,
    List<CorporateBooking>? bulkBookings,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalTrips: totalTrips ?? this.totalTrips,
      totalSpent: totalSpent ?? this.totalSpent,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      earnedRewards: earnedRewards ?? this.earnedRewards,
      availableRewards: availableRewards ?? this.availableRewards,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      referrals: referrals ?? this.referrals,
      corporateAccount: corporateAccount ?? this.corporateAccount,
      bulkBookings: bulkBookings ?? this.bulkBookings,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}

class LoyaltyReward {
  final String id;
  final String name;
  final String description;
  final String type; // 'discount', 'free_ride', 'upgrade', 'priority'
  final int pointsCost;
  final double discountPercentage;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? redeemedAt;

  LoyaltyReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.pointsCost,
    this.discountPercentage = 0.0,
    this.isActive = true,
    this.expiresAt,
    this.redeemedAt,
  });

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      pointsCost: json['pointsCost'] ?? 0,
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      redeemedAt: json['redeemedAt'] != null ? DateTime.parse(json['redeemedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'pointsCost': pointsCost,
      'discountPercentage': discountPercentage,
      'isActive': isActive,
      'expiresAt': expiresAt?.toIso8601String(),
      'redeemedAt': redeemedAt?.toIso8601String(),
    };
  }
}

/// User Statistics
class UserStats {
  final int totalBookings;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalSpent;
  final double averageRating;
  final String favoriteVehicle;
  final String mostUsedPickupLocation;
  final int loyaltyPoints;
  final String loyaltyTier;
  final int referralCount;
  final DateTime memberSince;

  UserStats({
    required this.totalBookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalSpent,
    required this.averageRating,
    required this.favoriteVehicle,
    required this.mostUsedPickupLocation,
    required this.loyaltyPoints,
    required this.loyaltyTier,
    required this.referralCount,
    required this.memberSince,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalBookings: json['totalBookings'] ?? 0,
      activeBookings: json['activeBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      favoriteVehicle: json['favoriteVehicle'] ?? '',
      mostUsedPickupLocation: json['mostUsedPickupLocation'] ?? '',
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      loyaltyTier: json['loyaltyTier'] ?? 'Bronze',
      referralCount: json['referralCount'] ?? 0,
      memberSince: DateTime.parse(json['memberSince'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'activeBookings': activeBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'totalSpent': totalSpent,
      'averageRating': averageRating,
      'favoriteVehicle': favoriteVehicle,
      'mostUsedPickupLocation': mostUsedPickupLocation,
      'loyaltyPoints': loyaltyPoints,
      'loyaltyTier': loyaltyTier,
      'referralCount': referralCount,
      'memberSince': memberSince.toIso8601String(),
    };
  }
}
/// Notification model
class Notification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] ?? {},
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 