class LoyaltyInfo {
  final String loyaltyTier;
  final int loyaltyPoints;
  final int pointsToNextTier;
  final double tierProgress;
  final double tierDiscount;
  final int totalTrips;
  final double totalSpent;

  LoyaltyInfo({
    required this.loyaltyTier,
    required this.loyaltyPoints,
    required this.pointsToNextTier,
    required this.tierProgress,
    required this.tierDiscount,
    required this.totalTrips,
    required this.totalSpent,
  });

  factory LoyaltyInfo.fromJson(Map<String, dynamic> json) {
    return LoyaltyInfo(
      loyaltyTier: json['loyaltyTier'] ?? 'Bronze',
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      pointsToNextTier: json['pointsToNextTier'] ?? 0,
      tierProgress: (json['tierProgress'] ?? 0.0).toDouble(),
      tierDiscount: (json['tierDiscount'] ?? 0.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
    );
  }
}



