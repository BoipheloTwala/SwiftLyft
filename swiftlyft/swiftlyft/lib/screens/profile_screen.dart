import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/rewards_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: WebContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            const RewardsCard(),
            const SizedBox(height: 24),
            _buildProfileActions(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );

    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.profile,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Profile',
        subtitle: 'Manage your account',
        showBackButton: true,
      ),
      body: content,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SwiftLyftTheme.gradientStart, SwiftLyftTheme.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Profile picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: SwiftLyftTheme.pureWhite,
            ),
          ),
          const SizedBox(width: 20),
          
          // User info
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, _) {
                final user = appState.currentUser;
                final displayName = (user?.name?.isNotEmpty ?? false) ? user!.name! : (user?.email ?? 'Guest');
                final email = user?.email ?? '';
                final tier = user?.loyaltyTier ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.pureWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: SwiftLyftTheme.pureWhite,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (tier.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: SwiftLyftTheme.warmOrange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$tier Member',
                          style: const TextStyle(
                            color: SwiftLyftTheme.pureWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final l = appState.loyaltyInfo;
                        if (appState.isLoadingLoyalty) {
                          return const SizedBox(
                            height: 8,
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              valueColor: AlwaysStoppedAnimation(SwiftLyftTheme.pureWhite),
                              backgroundColor: Color(0x33FFFFFF),
                            ),
                          );
                        }
                        if (l == null) {
                          // Trigger load once if missing
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            Provider.of<AppState>(context, listen: false).loadLoyalty();
                          });
                          return const SizedBox(
                            height: 8,
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              valueColor: AlwaysStoppedAnimation(SwiftLyftTheme.pureWhite),
                              backgroundColor: Color(0x33FFFFFF),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: l.tierProgress.clamp(0.0, 1.0),
                                ),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    backgroundColor: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation(SwiftLyftTheme.pureWhite),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${l.loyaltyPoints} pts • ${l.pointsToNextTier} to ${user?.nextTier ?? 'next tier'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: SwiftLyftTheme.pureWhite,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Edit button
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
            icon: const Icon(
              Icons.edit,
              color: SwiftLyftTheme.pureWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            'Edit Profile',
            'Update your personal information',
            Icons.person_outline,
            () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          _buildActionItem(
            'Payment Methods',
            'Manage your payment options',
            Icons.payment,
            () => Navigator.pushNamed(context, AppRoutes.paymentMethods),
          ),
          _buildActionItem(
            'Trip History',
            'View your past trips',
            Icons.history,
            () => Navigator.pushNamed(context, AppRoutes.tripHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: SwiftLyftTheme.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.tripHistory);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Trip Completed',
            'Mercedes S-Class • Airport Transfer',
            '2 days ago',
            Icons.check_circle,
            SwiftLyftTheme.successGreen,
          ),
          _buildActivityItem(
            'Payment Processed',
            'R1,200 • Credit Card ending in 1234',
            '3 days ago',
            Icons.payment,
            SwiftLyftTheme.primaryBlue,
          ),
          _buildActivityItem(
            'Offer Claimed',
            '20% off your next luxury ride',
            '1 week ago',
            Icons.local_offer,
            SwiftLyftTheme.warmOrange,
          ),
          _buildActivityItem(
            'Account Updated',
            'Profile information updated',
            '2 weeks ago',
            Icons.person,
            SwiftLyftTheme.mediumGray,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SwiftLyftTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
} 