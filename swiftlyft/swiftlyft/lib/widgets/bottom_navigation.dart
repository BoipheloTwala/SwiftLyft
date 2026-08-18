import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../providers/app_state.dart';

class SwiftLyftBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const SwiftLyftBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure currentIndex is within valid range
    final safeCurrentIndex = currentIndex.clamp(0, 4);
    
    return Container(
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        boxShadow: [
          BoxShadow(
            color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                isSelected: safeCurrentIndex == 0,
              ),
              _buildNavItem(
                context,
                icon: Icons.directions_car_rounded,
                label: 'Vehicles',
                index: 1,
                isSelected: safeCurrentIndex == 1,
              ),
              _buildNavItem(
                context,
                icon: Icons.local_offer_rounded,
                label: 'Offers',
                index: 2,
                isSelected: safeCurrentIndex == 2,
              ),
              _buildNavItem(
                context,
                icon: Icons.history_rounded,
                label: 'History',
                index: 3,
                isSelected: safeCurrentIndex == 3,
              ),
              _buildNavItem(
                context,
                icon: Icons.more_horiz_rounded,
                label: 'More',
                index: 4,
                isSelected: safeCurrentIndex == 4,
                isMoreTab: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    bool isMoreTab = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isMoreTab) {
              _showMoreMenu(context);
            } else {
            _handleNavigation(context, index);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: isSelected 
                  ? SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? SwiftLyftTheme.primaryBlue
                        : SwiftLyftTheme.mediumGray,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? SwiftLyftTheme.primaryBlue
                          : SwiftLyftTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return; // Already on this screen
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.vehicleListing);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.specialOffers);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.tripHistory);
        break;
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MoreMenuSheet(),
    );
  }
}

class _MoreMenuSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SwiftLyftTheme.mediumGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'More Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SwiftLyftTheme.deepCharcoal,
              ),
            ),
          ),
          
          // Navigation items
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Settings
                _buildMoreMenuItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  route: AppRoutes.settings,
                ),

                // Payment Methods
                _buildMoreMenuItem(
                  context,
                  icon: Icons.payment_rounded,
                  label: 'Payment Methods',
                  route: AppRoutes.paymentMethods,
                ),

                // Profile
                _buildMoreMenuItem(
                  context,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  route: AppRoutes.profile,
                ),

                // About Us
                _buildMoreMenuItem(
                  context,
                  icon: Icons.info_rounded,
                  label: 'About Us',
                  route: AppRoutes.aboutUs,
                ),

                // Logout
                _buildLogoutMenuItem(context),
              ],
            ),
          ),
          
          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMoreMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Close the modal
            Navigator.pushReplacementNamed(context, route);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: SwiftLyftTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: SwiftLyftTheme.deepCharcoal,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: SwiftLyftTheme.mediumGray,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutMenuItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Capture context and navigator before any modal operations
            final currentContext = context;
            final navigator = Navigator.of(currentContext);

            final confirm = await showDialog<bool>(
              context: currentContext,
              builder: (context) => AlertDialog(
                title: const Text('Sign out?'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
                ],
              ),
            );

            if (confirm == true) {
              // Close the modal first
              Navigator.pop(currentContext);

              // Call signOut and clear all user data
              final appState = Provider.of<AppState>(currentContext, listen: false);
              await appState.signOut();
              await appState.onSignOut(); // Clear all cached data
              navigator.pushReplacementNamed(AppRoutes.login);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SwiftLyftTheme.errorRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: SwiftLyftTheme.errorRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: SwiftLyftTheme.errorRed,
                    ),
                  ),
                ),
                const Icon(
                  Icons.logout_rounded,
                  color: SwiftLyftTheme.errorRed,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 