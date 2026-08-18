import 'special_features.dart';

class ReferralStats {
  final int totalReferrals;
  final int successfulReferrals;
  final int pendingReferrals;
  final int cancelledReferrals;
  final double totalEarnings;

  ReferralStats({
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.pendingReferrals,
    required this.cancelledReferrals,
    required this.totalEarnings,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      totalReferrals: json['totalReferrals'] ?? 0,
      successfulReferrals: json['successfulReferrals'] ?? 0,
      pendingReferrals: json['pendingReferrals'] ?? 0,
      cancelledReferrals: json['cancelledReferrals'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
    );
  }
}

class ReferralInfo {
  final String? referralCode;
  final List<Referral> referrals;
  final ReferralStats stats;

  ReferralInfo({
    required this.referralCode,
    required this.referrals,
    required this.stats,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    final referralsJson = (json['referrals'] as List<dynamic>? ) ?? [];
    return ReferralInfo(
      referralCode: json['referralCode'],
      referrals: referralsJson.map((e) => Referral.fromJson(e)).toList(),
      stats: ReferralStats.fromJson(json['stats'] ?? {}),
    );
  }
}


