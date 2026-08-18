import 'package:flutter/foundation.dart';

/// Reward model representing loyalty rewards
class Reward {
  final String id;
  final String name;
  final String description;
  final String type; // 'discount', 'free_ride', 'upgrade', 'priority'
  final int pointsCost;
  final double discountPercentage;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? redeemedAt;

  Reward({
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

  factory Reward.fromJson(Map<String, dynamic> json) {
    try {
      return Reward(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        type: (json['type'] ?? 'discount').toString(),
        pointsCost: (json['pointsCost'] ?? 0) is int 
            ? json['pointsCost'] 
            : int.tryParse(json['pointsCost'].toString()) ?? 0,
        discountPercentage: (json['discountPercentage'] ?? 0.0) is double
            ? json['discountPercentage']
            : double.tryParse(json['discountPercentage'].toString()) ?? 0.0,
        isActive: json['isActive'] ?? true,
        expiresAt: json['expiresAt'] != null && json['expiresAt'] is String && (json['expiresAt'] as String).isNotEmpty
            ? DateTime.tryParse(json['expiresAt'])
            : null,
        redeemedAt: json['redeemedAt'] != null && json['redeemedAt'] is String && (json['redeemedAt'] as String).isNotEmpty
            ? DateTime.tryParse(json['redeemedAt'])
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing Reward: $e');
      rethrow;
    }
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

  // Helper getters
  bool get isRedeemed => redeemedAt != null;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isAvailable => isActive && !isExpired && !isRedeemed;

  // Get icon based on reward type
  String get iconName {
    switch (type) {
      case 'discount':
        return 'percent';
      case 'free_ride':
        return 'directions_car';
      case 'upgrade':
        return 'star';
      case 'priority':
        return 'fast_forward';
      default:
        return 'card_giftcard';
    }
  }

  // Get user-friendly type label
  String get typeLabel {
    switch (type) {
      case 'discount':
        return 'Discount';
      case 'free_ride':
        return 'Free Ride';
      case 'upgrade':
        return 'Upgrade';
      case 'priority':
        return 'Priority';
      default:
        return type;
    }
  }

  // Get color based on reward type
  int get colorValue {
    switch (type) {
      case 'discount':
        return 0xFF4CAF50; // Green
      case 'free_ride':
        return 0xFF2196F3; // Blue
      case 'upgrade':
        return 0xFFFF9800; // Orange
      case 'priority':
        return 0xFF9C27B0; // Purple
      default:
        return 0xFF757575; // Gray
    }
  }
}

/// Rewards info containing all reward data
class RewardsInfo {
  final List<Reward> earnedRewards;
  final List<Reward> availableRewards;
  final int loyaltyPoints;
  final String loyaltyTier;
  final int totalEarnedRewards;
  final int totalAvailableRewards;

  RewardsInfo({
    required this.earnedRewards,
    required this.availableRewards,
    required this.loyaltyPoints,
    required this.loyaltyTier,
    required this.totalEarnedRewards,
    required this.totalAvailableRewards,
  });

  factory RewardsInfo.fromJson(Map<String, dynamic> json) {
    try {
      final earnedList = (json['earnedRewards'] as List<dynamic>?)
          ?.map((e) => Reward.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      
      final availableList = (json['availableRewards'] as List<dynamic>?)
          ?.map((e) => Reward.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];

      return RewardsInfo(
        earnedRewards: earnedList,
        availableRewards: availableList,
        loyaltyPoints: json['loyaltyPoints'] ?? 0,
        loyaltyTier: (json['loyaltyTier'] ?? 'Bronze').toString(),
        totalEarnedRewards: json['totalEarnedRewards'] ?? earnedList.length,
        totalAvailableRewards: json['totalAvailableRewards'] ?? availableList.length,
      );
    } catch (e) {
      debugPrint('Error parsing RewardsInfo: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'earnedRewards': earnedRewards.map((r) => r.toJson()).toList(),
      'availableRewards': availableRewards.map((r) => r.toJson()).toList(),
      'loyaltyPoints': loyaltyPoints,
      'loyaltyTier': loyaltyTier,
      'totalEarnedRewards': totalEarnedRewards,
      'totalAvailableRewards': totalAvailableRewards,
    };
  }

  // Get available rewards that user can afford
  List<Reward> get affordableRewards {
    return availableRewards.where((r) => r.pointsCost <= loyaltyPoints && r.isAvailable).toList();
  }

  // Get expired rewards
  List<Reward> get expiredRewards {
    return earnedRewards.where((r) => r.isExpired).toList();
  }

  // Get active earned rewards (not expired, not redeemed)
  List<Reward> get activeEarnedRewards {
    return earnedRewards.where((r) => r.isAvailable).toList();
  }
}

