import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/vehicle_category_card.dart';
import '../widgets/promotion_banner.dart';
import '../widgets/unified_navigation.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCity = 'Johannesburg';
  bool _isLoadingCategories = true;
  Map<String, int> _categoryCounts = {};

  final List<Map<String, dynamic>> _vehicleCategories = [
    {
      'id': '1',
      'name': 'Luxury Sedans',
      'description': 'Premium comfort for business and leisure',
      'icon': Icons.directions_car,
      'category': 'sedan', // Database category mapping
      'vehicleCount': 0, // Will be updated from API
      'color': SwiftLyftTheme.primaryBlue,
    },
    {
      'id': '2',
      'name': 'SUVs',
      'description': 'Spacious and versatile for groups',
      'icon': Icons.local_shipping,
      'category': 'suv', // Database category mapping
      'vehicleCount': 0, // Will be updated from API
      'color': SwiftLyftTheme.secondaryTeal,
    },
    {
      'id': '3',
      'name': 'Luxury Vans',
      'description': 'Perfect for corporate events',
      'icon': Icons.airport_shuttle,
      'category': 'van', // Database category mapping
      'vehicleCount': 0, // Will be updated from API
      'color': SwiftLyftTheme.accentPurple,
    },
    {
      'id': '4',
      'name': 'Sports Cars',
      'description': 'High-performance luxury vehicles',
      'icon': Icons.sports_motorsports,
      'category': 'luxury', // Database category mapping
      'vehicleCount': 0, // Will be updated from API
      'color': SwiftLyftTheme.warmOrange,
    },
    {
      'id': '5',
      'name': 'Hybrid Cars',
      'description': 'Eco-friendly and efficient vehicles',
      'icon': Icons.electric_car,
      'category': 'hybrid', // Database category mapping
      'vehicleCount': 0, // Will be updated from API
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicleCategoryCounts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadVehicleCategoryCounts() async {
    try {
      debugPrint('🔄 Loading vehicle category counts...');
      
      // Load vehicles from backend
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadVehicles();
      
      // Get loaded vehicles
      final vehicles = appState.vehicles.vehicles;
      debugPrint('📊 Loaded ${vehicles.length} vehicles');
      
      // Count vehicles by category
      final counts = <String, int>{};
      for (var vehicle in vehicles) {
        final category = vehicle.category;
        counts[category] = (counts[category] ?? 0) + 1;
        debugPrint('  - ${vehicle.name} (${vehicle.category})');
      }
      
      debugPrint('📈 Category counts: $counts');
      
      // Update UI
      if (!mounted) return;
      setState(() {
        _categoryCounts = counts;
        _isLoadingCategories = false;
        
        // Update each category's vehicle count
        for (var category in _vehicleCategories) {
          final dbCategory = category['category'] as String;
          category['vehicleCount'] = counts[dbCategory] ?? 0;
          debugPrint('✅ ${category['name']}: ${category['vehicleCount']} vehicles');
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to load vehicle category counts: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageBody = ResponsiveLayout(
      mobile: _buildMobileBody(),
      tablet: _buildTabletBody(),
      desktop: _buildDesktopBody(),
    );

    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.home,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: _getGreeting(),
        subtitle: 'Welcome to SwiftLyft',
        showBackButton: false,
      ),
      body: pageBody,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Only show FAB on mobile/tablet for quick booking
    if (SwiftLyftTheme.isDesktop(context)) return null;
    
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.bookingCreation);
      },
      icon: const Icon(Icons.add),
      label: const Text('Book Now'),
      backgroundColor: SwiftLyftTheme.primaryBlue,
      foregroundColor: SwiftLyftTheme.pureWhite,
    );
  }

  Widget _buildMobileBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationSelector(),
          const SizedBox(height: 24),
          _buildQuickBookingButton(),
          const SizedBox(height: 24),
          _buildVehicleCategories(),
          const SizedBox(height: 24),
          _buildPromotions(),
          const SizedBox(height: 80), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildTabletBody() {
    return WebContainer(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Search and categories
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationSelector(),
                      const SizedBox(height: 24),
                      _buildQuickBookingButton(),
                      const SizedBox(height: 32),
                      _buildVehicleCategories(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right column - Promotions
                Expanded(
                  flex: 1,
                  child: _buildPromotions(),
                ),
              ],
            ),
            const SizedBox(height: 80), // Extra space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopBody() {
    return WebContainer(
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section with search
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SwiftLyftTheme.gradientStart, SwiftLyftTheme.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Where would you like to go?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: SwiftLyftTheme.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Book your premium ride with just a few clicks',
                          style: TextStyle(
                            fontSize: 18,
                            color: SwiftLyftTheme.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildLocationSelector(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.bookingCreation);
                              },
                              icon: const Icon(Icons.event_available),
                              label: const Text('Book Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SwiftLyftTheme.pureWhite,
                                foregroundColor: SwiftLyftTheme.primaryBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.vehicleListing);
                              },
                              icon: const Icon(Icons.search),
                              label: const Text('Browse Vehicles'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: SwiftLyftTheme.pureWhite,
                                side: const BorderSide(color: SwiftLyftTheme.pureWhite),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 120,
                        color: SwiftLyftTheme.pureWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Vehicle categories
            _buildVehicleCategories(),
            const SizedBox(height: 40),
            // Promotions
            _buildPromotions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: SwiftLyftTheme.isDesktop(context) ? [
          BoxShadow(
            color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: SwiftLyftTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: SwiftLyftTheme.deepCharcoal,
                ),
                items: ['Johannesburg', 'Cape Town'].map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCity = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Vehicle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: SwiftLyftTheme.isWeb ? 250 : 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _vehicleCategories.length,
            itemBuilder: (context, index) {
              final category = _vehicleCategories[index];
              return Container(
                width: SwiftLyftTheme.isDesktop(context) ? 200 : 160,
                margin: EdgeInsets.only(
                  right: index < _vehicleCategories.length - 1 ? 16 : 0,
                ),
                child: VehicleCategoryCard(
                  name: category['name'],
                  description: category['description'],
                  icon: category['icon'],
                  vehicleCount: category['vehicleCount'],
                  color: category['color'],
                  onTap: () {
                    // Navigate with category filter
                    Navigator.pushNamed(
                      context,
                      AppRoutes.vehicleListing,
                      arguments: {
                        'category': category['category'],
                        'categoryName': category['name'],
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromotions() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Offers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        PromotionBanner(),
      ],
    );
  }

  Widget _buildQuickBookingButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SwiftLyftTheme.primaryBlue, SwiftLyftTheme.secondaryTeal],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.bookingCreation);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: SwiftLyftTheme.pureWhite,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book a Ride',
                        style: TextStyle(
                          color: SwiftLyftTheme.pureWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Schedule your premium transportation',
                        style: TextStyle(
                          color: SwiftLyftTheme.pureWhite,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: SwiftLyftTheme.pureWhite,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 