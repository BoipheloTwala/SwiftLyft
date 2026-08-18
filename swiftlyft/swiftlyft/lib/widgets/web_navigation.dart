import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import 'unified_navigation.dart';
import '../providers/app_state.dart';
import '../utils/routes.dart';

class WebNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const WebNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  // Static helper method for navigation handling
  static void handleNavigation(BuildContext context, int index) {
    if (index >= 0 && index < UnifiedNavigation.allNavigationItems.length) {
      final route = UnifiedNavigation.allNavigationItems[index].route;
      if (route.isNotEmpty) {
        Navigator.pushReplacementNamed(context, route);
      }
    }
  }

  @override
  State<WebNavigation> createState() => _WebNavigationState();
}

class _WebNavigationState extends State<WebNavigation> with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: 280.0,
      end: 80.0, // Increased minimum width to prevent overflow
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!SwiftLyftTheme.isWeb) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletSize = screenWidth < SwiftLyftTheme.desktopBreakpoint && screenWidth >= SwiftLyftTheme.tabletBreakpoint;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        final currentWidth = isTabletSize && !_isExpanded ? 80.0 : _widthAnimation.value;
        final safeWidth = currentWidth < 60 ? 60.0 : currentWidth; // Ensure minimum safe width
        
        return Container(
          width: safeWidth,
          decoration: BoxDecoration(
            color: SwiftLyftTheme.pureWhite,
            boxShadow: [
              BoxShadow(
                color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with logo and toggle button
              _buildHeader(),
              
              // Navigation items
              Expanded(
                child: _buildNavigationItems(),
              ),
              
              // Footer
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        border: Border(
          bottom: BorderSide(
            color: SwiftLyftTheme.lightGray,
            width: 1,
          ),
        ),
      ),
      child: Row(
            children: [
              // Logo
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isExpanded ? 40 : 32,
            height: _isExpanded ? 40 : 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SwiftLyftTheme.primaryBlue, SwiftLyftTheme.accentPurple],
              ),
              borderRadius: BorderRadius.circular(_isExpanded ? 12 : 8),
            ),
            child: const Icon(
                  Icons.local_taxi,
                  color: SwiftLyftTheme.pureWhite,
              size: 20,
            ),
          ),
          
          if (_isExpanded) ...[
            const SizedBox(width: 12),
            const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                        'SwiftLyft',
                        style: TextStyle(
                      fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: SwiftLyftTheme.deepCharcoal,
                        ),
                      ),
                        Text(
                          'Premium Transport',
                          style: TextStyle(
                      fontSize: 12,
                            color: SwiftLyftTheme.mediumGray,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
          // Toggle button
          IconButton(
            onPressed: _toggleSidebar,
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: SwiftLyftTheme.primaryBlue,
            ),
            tooltip: _isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: UnifiedNavigation.allNavigationItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isSelected = widget.currentIndex == index;
        
        return _buildNavigationItem(
          icon: item.icon,
          label: item.label,
          isSelected: isSelected,
          onTap: () {
            widget.onTap?.call(index);
          },
        );
      }).toList(),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 16 : 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
                    children: [
                Icon(
                          icon,
                  size: 24,
                          color: isSelected 
                              ? SwiftLyftTheme.primaryBlue
                              : SwiftLyftTheme.mediumGray,
                      ),
                      if (_isExpanded) ...[
                  const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected 
                                  ? SwiftLyftTheme.primaryBlue
                                  : SwiftLyftTheme.deepCharcoal,
                            ),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        border: Border(
          top: BorderSide(
            color: SwiftLyftTheme.lightGray,
            width: 1,
          ),
        ),
      ),
      child: _isExpanded
          ? Column(
              children: [
                // User info
                Row(
                  children: [
                Container(
                      width: 40,
                      height: 40,
                  decoration: BoxDecoration(
                        color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                        Icons.person,
                        color: SwiftLyftTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<AppState>(
                      builder: (context, appState, _) {
                    final user = appState.currentUser;
                        final displayName = (user?.name?.isNotEmpty ?? false)
                            ? user!.name!
                            : (user?.email ?? 'Guest');
                        final displayTier = user != null
                            ? '${user.loyaltyTier} Member'
                            : 'Not signed in';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: SwiftLyftTheme.deepCharcoal,
                              ),
                            ),
                            Text(
                              displayTier,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: SwiftLyftTheme.mediumGray,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                      ],
                ),
                const SizedBox(height: 16),
                
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await Provider.of<AppState>(context, listen: false).signOut();
                      } catch (_) {}
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SwiftLyftTheme.mediumGray,
                      side: const BorderSide(color: SwiftLyftTheme.lightGray),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // User avatar only
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                        child: const Icon(
                    Icons.person,
                          color: SwiftLyftTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Logout icon
                IconButton(
                onPressed: () async {
                  try {
                    await Provider.of<AppState>(context, listen: false).signOut();
                  } catch (_) {}
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                },
                  icon: const Icon(
                    Icons.logout,
                    color: SwiftLyftTheme.mediumGray,
                    size: 20,
                  ),
                  tooltip: 'Logout',
                ),
              ],
            ),
    );
  }
} 