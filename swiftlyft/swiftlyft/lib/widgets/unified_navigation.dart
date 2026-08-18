import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import 'web_navigation.dart';
import 'bottom_navigation.dart';

class UnifiedNavigation {
  // Navigation items configuration - Primary items for mobile bottom nav
  static const List<NavigationItem> primaryNavigationItems = [
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Home',
      route: AppRoutes.home,
    ),
    NavigationItem(
      icon: Icons.directions_car_rounded,
      label: 'Vehicles',
      route: AppRoutes.vehicleListing,
    ),
    NavigationItem(
      icon: Icons.local_offer_rounded,
      label: 'Offers',
      route: AppRoutes.specialOffers,
    ),
    NavigationItem(
      icon: Icons.history_rounded,
      label: 'History',
      route: AppRoutes.tripHistory,
    ),
    NavigationItem(
      icon: Icons.more_horiz_rounded,
      label: 'More',
      route: '', // Special route for more menu
    ),
  ];

  // All navigation items for sidebar and more menu
  static const List<NavigationItem> allNavigationItems = [
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Home',
      route: AppRoutes.home,
    ),
    NavigationItem(
      icon: Icons.directions_car_rounded,
      label: 'Vehicles',
      route: AppRoutes.vehicleListing,
    ),
    NavigationItem(
      icon: Icons.local_offer_rounded,
      label: 'Offers',
      route: AppRoutes.specialOffers,
    ),
    NavigationItem(
      icon: Icons.history_rounded,
      label: 'History',
      route: AppRoutes.tripHistory,
    ),
    NavigationItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: AppRoutes.settings,
    ),
    NavigationItem(
      icon: Icons.payment_rounded,
      label: 'Payment Methods',
      route: AppRoutes.paymentMethods,
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      route: AppRoutes.profile,
    ),
  ];

  // Get current navigation index based on route
  static int getCurrentIndex(String currentRoute) {
    for (int i = 0; i < allNavigationItems.length; i++) {
      if (allNavigationItems[i].route == currentRoute) {
        return i;
      }
    }
    return 0; // Default to home
  }

  // Handle navigation
  static void navigateTo(BuildContext context, int index) {
    if (index >= 0 && index < allNavigationItems.length) {
      final route = allNavigationItems[index].route;
      final currentRoute = ModalRoute.of(context)?.settings.name;
      
      // Don't navigate if already on the same route
      if (route == currentRoute) return;
      
      // Use pushReplacementNamed for consistent navigation
      if (route.isNotEmpty) {
        Navigator.pushReplacementNamed(context, route);
      }
    }
  }

  // Build scaffold with consistent navigation
  static Widget buildScaffold({
    required BuildContext context,
    required String currentRoute,
    required PreferredSizeWidget appBar,
    required Widget body,
    Widget? floatingActionButton,
    Widget? drawer,
    Widget? endDrawer,
    bool extendBody = false,
    bool extendBodyBehindAppBar = false,
  }) {
    final isWeb = SwiftLyftTheme.isWeb;
    final isDesktop = SwiftLyftTheme.isDesktop(context);
    final isTablet = SwiftLyftTheme.isTablet(context);

    if (isWeb && isDesktop) {
      // Desktop layout with sidebar
      return Scaffold(
        body: Row(
          children: [
            // Sidebar navigation
            WebNavigation(
              currentIndex: getCurrentIndex(currentRoute),
              onTap: (index) => navigateTo(context, index),
            ),
            // Main content
            Expanded(
              child: Scaffold(
                appBar: appBar,
                body: body,
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    } else if (isWeb && isTablet) {
      // Tablet layout with bottom navigation
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: SwiftLyftBottomNavigation(
          currentIndex: getCurrentIndex(currentRoute),
        ),
      );
    } else {
      // Mobile layout with bottom navigation
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: SwiftLyftBottomNavigation(
          currentIndex: getCurrentIndex(currentRoute),
        ),
      );
    }
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

// Enhanced AppBar builder for consistent design
class UnifiedAppBar {
  static PreferredSizeWidget build({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    PreferredSizeWidget? bottom,
  }) {
    final isWeb = SwiftLyftTheme.isWeb;
    final isDesktop = SwiftLyftTheme.isDesktop(context);

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: isWeb ? (isDesktop ? 24 : 20) : 18,
          fontWeight: FontWeight.w600,
          color: SwiftLyftTheme.deepCharcoal,
        ),
      ),
      leading: leading,
      actions: actions,
      backgroundColor: SwiftLyftTheme.pureWhite,
      foregroundColor: SwiftLyftTheme.deepCharcoal,
      elevation: isWeb ? 2 : 0,
      centerTitle: centerTitle,
      surfaceTintColor: SwiftLyftTheme.pureWhite,
      toolbarHeight: isWeb ? (isDesktop ? 80 : 64) : 56,
      bottom: bottom,
      iconTheme: const IconThemeData(
        color: SwiftLyftTheme.primaryBlue,
      ),
    );
  }

  // Build responsive app bar with context-aware content
  static PreferredSizeWidget buildResponsive({
    required BuildContext context,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    Widget? leading,
    bool showBackButton = true,
  }) {
    final isDesktop = SwiftLyftTheme.isDesktop(context);
    final isTablet = SwiftLyftTheme.isTablet(context);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
              fontWeight: FontWeight.w600,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                color: SwiftLyftTheme.mediumGray,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      leading: showBackButton ? leading : null,
      actions: actions,
      backgroundColor: SwiftLyftTheme.pureWhite,
      foregroundColor: SwiftLyftTheme.deepCharcoal,
      elevation: SwiftLyftTheme.isWeb ? 2 : 0,
      centerTitle: false,
      surfaceTintColor: SwiftLyftTheme.pureWhite,
      toolbarHeight: isDesktop ? 80 : (isTablet ? 64 : 56),
      iconTheme: const IconThemeData(
        color: SwiftLyftTheme.primaryBlue,
      ),
    );
  }
} 