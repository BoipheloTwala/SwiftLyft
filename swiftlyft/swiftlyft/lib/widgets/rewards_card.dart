import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/reward.dart';
import '../utils/theme.dart';

/// Widget to display user rewards (earned and available)
class RewardsCard extends StatelessWidget {
  const RewardsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final rewardsInfo = appState.rewardsInfo;
        final isLoading = appState.isLoadingRewards;
        final error = appState.rewardsError;

        if (isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load rewards', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(error, style: const TextStyle(color: SwiftLyftTheme.mediumGray)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => appState.loadRewards(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (rewardsInfo == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No rewards data available')),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SwiftLyftTheme.pureWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.card_giftcard, color: SwiftLyftTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Text(
                    'My Rewards',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.deepCharcoal,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, size: 16, color: SwiftLyftTheme.primaryBlue),
                        const SizedBox(width: 4),
                        Text(
                          '${rewardsInfo.loyaltyPoints} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SwiftLyftTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      'Available',
                      rewardsInfo.totalAvailableRewards.toString(),
                      Icons.redeem,
                      SwiftLyftTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      'Earned',
                      rewardsInfo.totalEarnedRewards.toString(),
                      Icons.emoji_events,
                      SwiftLyftTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      'Affordable',
                      rewardsInfo.affordableRewards.length.toString(),
                      Icons.shopping_bag,
                      SwiftLyftTheme.warmOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Available Rewards Section
              if (rewardsInfo.availableRewards.isNotEmpty) ...[
                Text(
                  'Available Rewards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...rewardsInfo.availableRewards.take(3).map((reward) => _buildRewardTile(context, reward, rewardsInfo.loyaltyPoints)),
                if (rewardsInfo.availableRewards.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to full rewards page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Full rewards page coming soon!')),
                        );
                      },
                      child: Text('View all ${rewardsInfo.availableRewards.length} rewards'),
                    ),
                  ),
              ],

              // Earned Rewards Section
              if (rewardsInfo.earnedRewards.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'My Earned Rewards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...rewardsInfo.activeEarnedRewards.take(3).map((reward) => _buildEarnedRewardTile(context, reward)),
                if (rewardsInfo.activeEarnedRewards.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to full earned rewards page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Full earned rewards page coming soon!')),
                        );
                      },
                      child: Text('View all ${rewardsInfo.activeEarnedRewards.length} earned rewards'),
                    ),
                  ),
              ],

              // Empty State
              if (rewardsInfo.availableRewards.isEmpty && rewardsInfo.earnedRewards.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.card_giftcard_outlined, size: 64, color: SwiftLyftTheme.mediumGray.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No rewards yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: SwiftLyftTheme.mediumGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Complete rides to earn loyalty points and unlock rewards!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: SwiftLyftTheme.mediumGray),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTile(BuildContext context, Reward reward, int userPoints) {
    final canAfford = userPoints >= reward.pointsCost;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canAfford ? Color(reward.colorValue).withOpacity(0.05) : SwiftLyftTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford ? Color(reward.colorValue).withOpacity(0.3) : SwiftLyftTheme.mediumGray.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(reward.colorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(reward.iconName),
              color: Color(reward.colorValue),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SwiftLyftTheme.mediumGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.stars, size: 14, color: canAfford ? SwiftLyftTheme.warmOrange : SwiftLyftTheme.mediumGray),
                  const SizedBox(width: 2),
                  Text(
                    '${reward.pointsCost}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canAfford ? SwiftLyftTheme.deepCharcoal : SwiftLyftTheme.mediumGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: canAfford ? SwiftLyftTheme.successGreen : SwiftLyftTheme.mediumGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  canAfford ? 'Redeem' : 'Locked',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedRewardTile(BuildContext context, Reward reward) {
    final daysUntilExpiry = reward.expiresAt?.difference(DateTime.now()).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.successGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(reward.iconName),
              color: SwiftLyftTheme.successGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                if (daysUntilExpiry != null && daysUntilExpiry > 0)
                  Text(
                    'Expires in $daysUntilExpiry days',
                    style: const TextStyle(
                      fontSize: 12,
                      color: SwiftLyftTheme.mediumGray,
                    ),
                  )
                else
                  const Text(
                    'No expiry',
                    style: TextStyle(
                      fontSize: 12,
                      color: SwiftLyftTheme.mediumGray,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: SwiftLyftTheme.successGreen, size: 20),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'percent':
        return Icons.percent;
      case 'directions_car':
        return Icons.directions_car;
      case 'star':
        return Icons.star;
      case 'fast_forward':
        return Icons.fast_forward;
      default:
        return Icons.card_giftcard;
    }
  }
}

