import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../providers/app_state.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/error_handler.dart';
import '../widgets/batch_booking_stack_badge.dart';
import '../providers/batch_booking_stack_provider.dart';
import '../models/vehicle.dart';

class VehicleListingScreen extends StatefulWidget {
  const VehicleListingScreen({super.key});

  @override
  State<VehicleListingScreen> createState() => _VehicleListingScreenState();
}

class _VehicleListingScreenState extends State<VehicleListingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDisposed = false;
  bool _hasAppliedFilter = false; // Track if filter has been applied
  bool _initialLoadRequested = false; // Ensure we trigger a load once when needed
  // String _selectedCity = 'Johannesburg';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_isDisposed) {
        final appState = Provider.of<AppState>(context, listen: false);
        switch (_tabController.index) {
          case 0:
            appState.updateCity('Johannesburg');
            break;
          case 1:
            appState.updateCity('Cape Town');
            break;
          case 2:
            appState.updateCity('All');
            break;
        }
        if (mounted) {
          setState(() {});
        }
      }
    });

    // Always load vehicles when screen is shown to ensure fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isDisposed) return;

      // Prevent duplicate loads
      if (_initialLoadRequested) {
        return;
      }

      _initialLoadRequested = true;

      final appState = Provider.of<AppState>(context, listen: false);

      // If vehicles are already loaded and not loading, just do a background refresh
      // But still allow the UI to render with existing data
      if (appState.allVehicles.isNotEmpty && !appState.isLoadingVehicles) {
        debugPrint('✅ Vehicles already loaded (${appState.allVehicles.length}) - doing background refresh');
        // Trigger background refresh but don't wait for it
        appState.loadVehicles().catchError((e) {
          debugPrint('⚠️ Background refresh failed: $e');
        });
        return;
      }

      // Always load fresh when screen appears for the first time
      debugPrint('🚀 Loading vehicles for first time - Current state: Vehicles: ${appState.allVehicles.length}, Loading: ${appState.isLoadingVehicles}');

      try {
        await appState.loadVehicles();
        debugPrint('✅ Initial vehicle load completed');
      } catch (e) {
        debugPrint('❌ Initial vehicle load failed: $e');
        // Don't rethrow - let the UI handle error state
      }

      // Safety timeout: if vehicles are still empty after 3 seconds, force another load
      // This handles edge cases where the initial load might have failed silently
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted || _isDisposed) return;

        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.allVehicles.isEmpty && !appState.isLoadingVehicles && appState.vehicleError == null) {
          debugPrint('⚠️ Safety timeout triggered - vehicles still empty, forcing reload');
          appState.loadVehicles(force: true).catchError((e) {
            debugPrint('❌ Safety reload failed: $e');
          });
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Apply filter only once when screen first loads
    if (!_hasAppliedFilter && !_isDisposed) {
      _hasAppliedFilter = true;
      
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Check for category filter from navigation arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      // If we have a category filter, apply it synchronously
      if (args != null && args['category'] != null) {
        final category = args['category'] as String;
        final categoryName = args['categoryName'] as String?;
        debugPrint('🔍 Applying category filter EARLY: $category ($categoryName)');
        appState.updateCategory(category);
      } else {
        // Clear category filter if no argument
        appState.clearCategoryFilter();
        debugPrint('📋 No category filter - showing all vehicles');
      }
      
      // Don't trigger another load here - let initState handle it
      // Just log if vehicles are already available
      if (appState.allVehicles.isNotEmpty) {
        debugPrint('✅ Vehicles already loaded (${appState.allVehicles.length}), using existing data with filter');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    // Reset flags when screen is disposed so it reloads when navigated back to
    _initialLoadRequested = false;
    _hasAppliedFilter = false;
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    // Get category name from arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final categoryName = args?['categoryName'] as String?;
    final category = args?['category'] as String?;
    
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return UnifiedNavigation.buildScaffold(
          context: context,
          currentRoute: AppRoutes.vehicleListing,
          appBar: AppBar(
            title: Text(categoryName != null ? categoryName : 'Available Vehicles'),
            backgroundColor: SwiftLyftTheme.pureWhite,
            foregroundColor: SwiftLyftTheme.deepCharcoal,
            elevation: SwiftLyftTheme.isWeb ? 2 : 0,
            actions: category != null ? [
              TextButton.icon(
                onPressed: () {
                  appState.clearCategoryFilter();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filter'),
              ),
            ] : null,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Johannesburg'),
                Tab(text: 'Cape Town'),
                Tab(text: 'All Cities'),
              ],
            ),
          ),
          body: Builder(
            builder: (context) {
          if (appState.isLoadingVehicles) {
            return _buildLoadingState();
          }

          if (appState.vehicleError != null) {
            return _buildErrorState(appState.vehicleError!);
          }

          // If no vehicles are loaded yet and we're not loading, show loading state
          // This handles the initial load case when vehicles haven't been fetched yet
          if (appState.allVehicles.isEmpty) {
            debugPrint('📭 No vehicles loaded yet - showing loading state (Loading: ${appState.isLoadingVehicles})');
            return _buildLoadingState();
          }
          
          // Show stack badge only for corporate users
          final isCorporateUser = appState.corporateInfo != null;
          
          return Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _buildVehicleList(appState, 'Johannesburg'),
                  _buildVehicleList(appState, 'Cape Town'),
                  _buildVehicleList(appState, 'All'),
                ],
              ),
              // Batch booking stack badge (only for corporate users)
              if (isCorporateUser)
                BatchBookingStackBadge(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.batchBookingStack);
                  },
                ),
            ],
          );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: VehicleCardSkeleton(),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load vehicles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 16,
              color: SwiftLyftTheme.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              appState.loadVehicles();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(AppState appState, String city) {
    debugPrint('🏗️ Building vehicle list for city: $city');
    debugPrint('📊 AppState.allVehicles count: ${appState.allVehicles.length}');
    debugPrint('📊 AppState.filteredVehicles count: ${appState.filteredVehicles.length}');
    debugPrint('🎯 Current category filter: ${appState.vehicles.selectedCategory}');
    debugPrint('🔄 Loading state: ${appState.isLoadingVehicles}');
    
    // Safety: if somehow still loading at this point, show loading (should not happen due to top-level check)
    if (appState.isLoadingVehicles) {
      return _buildLoadingState();
    }
    
    List<Vehicle> filteredVehicles = appState.filteredVehicles.where((vehicle) {
      if (city == 'All') return true;
      return vehicle.city == city;
    }).toList().cast<Vehicle>();

    debugPrint('✅ Final filtered vehicles for display: ${filteredVehicles.length}');
    if (filteredVehicles.isNotEmpty) {
      debugPrint('📝 Vehicle names: ${filteredVehicles.take(5).map((v) => '${v.name} (${v.category})').join(', ')}...');
    }

    if (filteredVehicles.isEmpty) {
      // If we have vehicles but none match filter, show empty with filter message
      if (appState.allVehicles.isNotEmpty) {
        return EmptyStateWidget(
          message: 'No vehicles match the current filters for $city',
          icon: Icons.filter_alt_outlined,
          onAction: () {
            // Clear filters and reload
            appState.clearCategoryFilter();
            appState.loadVehicles();
          },
          actionLabel: 'Clear Filters',
        );
      }
      // If no vehicles at all, show empty with refresh
      return EmptyStateWidget(
        message: 'No vehicles available in $city',
        icon: Icons.directions_car,
        onAction: () {
          // Refresh or change filters
          appState.loadVehicles();
        },
        actionLabel: 'Refresh',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await appState.loadVehicles();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getResponsiveCrossAxisCount(),
          childAspectRatio: _getResponsiveAspectRatio(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
      itemCount: filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = filteredVehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final bool selectMode = args?['selectMode'] == true;
          if (selectMode) {
            Navigator.pop(context, {
              'vehicleId': vehicle.id,
              'vehicleName': vehicle.name,
              'vehicleType': vehicle.category,
            });
          } else {
            _navigateToVehicleDetails(vehicle);
          }
        },
        onLongPress: () {
          // Add to batch booking stack on long press (corporate users only)
          final appState = Provider.of<AppState>(context, listen: false);
          if (appState.corporateInfo != null) {
            final stackProvider = Provider.of<BatchBookingStackProvider>(context, listen: false);
            stackProvider.addVehicle(vehicle);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${vehicle.name} added to fleet selection'),
                    ),
                  ],
                ),
                backgroundColor: SwiftLyftTheme.successGreen,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'View Fleet',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.batchBookingStack);
                  },
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SwiftLyftTheme.pureWhite,
                SwiftLyftTheme.lightGray.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: _buildResponsiveVehicleCard(vehicle),
        ),
      ),
    );
  }

  Widget _buildResponsiveVehicleCard(Vehicle vehicle) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Use height-based breakpoints for better adaptation
    if (screenWidth < 600 || screenHeight < 600) {
      return _buildCompactVehicleCard(vehicle);
    }
    // Medium screens
    else if (screenWidth < 1200) {
      return _buildMediumVehicleCard(vehicle);
    }
    // Large screens
    else {
      return _buildFullVehicleCard(vehicle);
    }
  }

  Widget _buildCompactVehicleCard(Vehicle vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle image section
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                  SwiftLyftTheme.accentPurple.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Vehicle placeholder image
                Center(
                  child: Icon(
                    Icons.directions_car,
                    size: 50,
                    color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                
                // Price badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'R${vehicle.displayPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                
                // Availability badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: vehicle.isAvailable 
                          ? SwiftLyftTheme.successGreen 
                          : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vehicle.isAvailable ? 'Available' : 'Unavailable',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.pureWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Ultra-compact details section
        Container(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vehicle name and category in one line
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${vehicle.seatingCapacity}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: SwiftLyftTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 2),
              
              // Category
              Text(
                vehicle.category,
                style: const TextStyle(
                  fontSize: 9,
                  color: SwiftLyftTheme.mediumGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: ElevatedButton(
                    onPressed: vehicle.isAvailable 
                        ? () => _requestQuote(vehicle)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: SwiftLyftTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Request Quote',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediumVehicleCard(Vehicle vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle image section
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                  SwiftLyftTheme.accentPurple.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Vehicle placeholder image
                Center(
                  child: Icon(
                    Icons.directions_car,
                    size: 60,
                    color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                
                // Price badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'R${vehicle.displayPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                
                // Availability badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: vehicle.isAvailable 
                          ? SwiftLyftTheme.successGreen 
                          : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vehicle.isAvailable ? 'Available' : 'Unavailable',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.pureWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Compact details section
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vehicle name and category
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SwiftLyftTheme.mediumGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Seating capacity
                Row(
                  children: [
                    const Icon(
                      Icons.airline_seat_recline_normal,
                      size: 12,
                      color: SwiftLyftTheme.primaryBlue,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${vehicle.seatingCapacity} seats',
                      style: const TextStyle(
                        fontSize: 10,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: OutlinedButton(
                          onPressed: () => _navigateToVehicleDetails(vehicle),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: SwiftLyftTheme.primaryBlue, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Details',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: ElevatedButton(
                          onPressed: vehicle.isAvailable 
                              ? () => _requestQuote(vehicle)
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: SwiftLyftTheme.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Request Quote',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullVehicleCard(Vehicle vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle image section
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                  SwiftLyftTheme.accentPurple.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Vehicle placeholder image
                Center(
                  child: Icon(
                    Icons.directions_car,
                    size: 80,
                    color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                
                // Price badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'R${vehicle.displayPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                
                // Availability badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: vehicle.isAvailable 
                          ? SwiftLyftTheme.successGreen 
                          : Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      vehicle.isAvailable ? 'Available' : 'Unavailable',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.pureWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Full details section
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle name and category
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  vehicle.category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: SwiftLyftTheme.mediumGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Features and capacity
                Row(
                  children: [
                    const Icon(
                      Icons.airline_seat_recline_normal,
                      size: 18,
                      color: SwiftLyftTheme.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${vehicle.seatingCapacity} seats',
                      style: const TextStyle(
                        fontSize: 14,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                    const Spacer(),
                    if (vehicle.features.isNotEmpty)
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: SwiftLyftTheme.warmOrange,
                      ),
                  ],
                ),
                
                const Spacer(),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _navigateToVehicleDetails(vehicle),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: SwiftLyftTheme.primaryBlue),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: vehicle.isAvailable 
                            ? () => _requestQuote(vehicle)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: SwiftLyftTheme.primaryBlue,
                        ),
                        child: const Text(
                          'Request Quote',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToVehicleDetails(Vehicle vehicle) {
              Navigator.pushNamed(
                context,
      AppRoutes.vehicleDetails,
                arguments: {
                  'vehicleId': vehicle.id,
                  'vehicleName': vehicle.name,
                },
              );
  }

  void _requestQuote(Vehicle vehicle) {
              Navigator.pushNamed(
                context,
      AppRoutes.quoteRequest,
                arguments: {
                  'vehicleId': vehicle.id,
                  'vehicleName': vehicle.name,
                },
              );
  }

  // Add responsive methods
  int _getResponsiveCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 1; // Mobile: 1 column
    if (screenWidth < 900) return 2; // Small tablet: 2 columns
    if (screenWidth < 1200) return 3; // Large tablet: 3 columns
    return 4; // Desktop: 4 columns
  }

  double _getResponsiveAspectRatio() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // More conservative aspect ratios to prevent overflow
    if (screenWidth < 600 || screenHeight < 600) return 0.7; // Compact: very short cards
    if (screenWidth < 900) return 0.75; // Small tablet
    if (screenWidth < 1200) return 0.8; // Large tablet
    return 0.85; // Desktop: still conservative
  }
} 