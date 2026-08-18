class UserStatistics {
  final int totalTrips;
  final double totalSpent;
  final int loyaltyPoints;
  final String loyaltyTier;
  final DateTime memberSince;
  final DateTime lastLogin;
  final int loginCount;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  UserStatistics({
    required this.totalTrips,
    required this.totalSpent,
    required this.loyaltyPoints,
    required this.loyaltyTier,
    required this.memberSince,
    required this.lastLogin,
    required this.loginCount,
    required this.isEmailVerified,
    required this.isPhoneVerified,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalTrips: json['totalTrips'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      loyaltyTier: json['loyaltyTier'] ?? 'Bronze',
      memberSince: DateTime.parse(json['memberSince'] ?? DateTime.now().toIso8601String()),
      lastLogin: DateTime.parse(json['lastLogin'] ?? DateTime.now().toIso8601String()),
      loginCount: json['loginCount'] ?? 0,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTrips': totalTrips,
      'totalSpent': totalSpent,
      'loyaltyPoints': loyaltyPoints,
      'loyaltyTier': loyaltyTier,
      'memberSince': memberSince.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'loginCount': loginCount,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
    };
  }

  // Helper getters
  double get averageSpentPerTrip => totalTrips > 0 ? totalSpent / totalTrips : 0.0;
  
  String get membershipDuration {
    final duration = DateTime.now().difference(memberSince);
    if (duration.inDays < 30) {
      return '${duration.inDays} days';
    } else if (duration.inDays < 365) {
      return '${(duration.inDays / 30).floor()} months';
    } else {
      return '${(duration.inDays / 365).floor()} years';
    }
  }
}

