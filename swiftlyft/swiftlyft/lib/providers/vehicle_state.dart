import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/vehicle_api_service.dart';
import '../services/analytics_api_service.dart';

/// Vehicle state management
class VehicleState extends ChangeNotifier {
  final VehicleService _vehicleService;
  final AnalyticsService _analyticsService;

  VehicleState(this._vehicleService, this._analyticsService);

  // State
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = false;
  String? _error;

  // Search and filter state
  String _searchQuery = '';
  final List<String> _searchHistory = [];
  String _selectedFilter = 'All';
  String _selectedCity = 'Johannesburg';
  String? _selectedCategory; // null means 'All categories'
  Map<String, dynamic> _advancedFilters = {};

  // Favorites state
  final Set<String> _favoriteVehicleIds = {};

  // Getters
  List<Vehicle> get vehicles => _vehicles;
  List<Vehicle> get filteredVehicles => _filteredVehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<String> get searchHistory => _searchHistory;
  String get selectedFilter => _selectedFilter;
  String get selectedCity => _selectedCity;
  String? get selectedCategory => _selectedCategory;
  Map<String, dynamic> get advancedFilters => _advancedFilters;

  // Favorites
  bool isVehicleFavorited(String vehicleId) => _favoriteVehicleIds.contains(vehicleId);
  void toggleVehicleFavorite(String vehicleId) {
    if (_favoriteVehicleIds.contains(vehicleId)) {
      _favoriteVehicleIds.remove(vehicleId);
    } else {
      _favoriteVehicleIds.add(vehicleId);
    }
    notifyListeners();
  }

  Future<void> loadVehicles({bool force = false}) async {
    // Prevent duplicate loads, unless forced
    if (_isLoading && !force) {
      debugPrint('⚠️ Vehicle load already in progress, skipping duplicate request');
      return;
    }
    
    // If forced and currently loading, reset the loading state first
    if (force && _isLoading) {
      debugPrint('🔄 Force reload requested - resetting loading state');
      _setLoading(false);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _setLoading(true);
    _clearError();
    notifyListeners();
    
    // Small delay to ensure UI updates before async operation
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      debugPrint('📡 Loading vehicles from API...');
      // Load vehicles from both Johannesburg and Cape Town
      final jhbVehicles = await _vehicleService.getAvailableVehicles(
        latitude: -26.2041, // Johannesburg coordinates
        longitude: 28.0473,
      );
      debugPrint('✅ Loaded ${jhbVehicles.length} vehicles from Johannesburg');

      List<Vehicle> cptVehicles = [];
      try {
        cptVehicles = await _vehicleService.getAvailableVehicles(
          latitude: -33.9249, // Cape Town coordinates
          longitude: 18.4241,
        );
        debugPrint('✅ Loaded ${cptVehicles.length} vehicles from Cape Town');
      } catch (e) {
        debugPrint('⚠️ Failed to load Cape Town vehicles from API: $e');
      }

      // Check for any Cape Town vehicles that might be in the Johannesburg list
      final capeTownVehiclesInList = jhbVehicles.where((v) => v.city == 'Cape Town').toList();
      if (capeTownVehiclesInList.isNotEmpty) {
        // Remove Cape Town vehicles from Johannesburg list and add to Cape Town list
        jhbVehicles.removeWhere((v) => v.city == 'Cape Town');
        cptVehicles = [...cptVehicles, ...capeTownVehiclesInList];
      }

      // Combine all vehicles
      final allVehicles = [...jhbVehicles, ...cptVehicles];
      debugPrint('✅ Total vehicles loaded: ${allVehicles.length} (${jhbVehicles.length} JHB, ${cptVehicles.length} CPT)');
      
      _vehicles = allVehicles;
      _applyFilters();

      // Track successful load (fire and forget - don't await)
      _analyticsService.trackEvent(
        eventType: 'vehicles_loaded',
        eventData: {'count': allVehicles.length},
      ).catchError((e) => debugPrint('⚠️ Analytics tracking failed: $e'));

    } catch (e) {
      debugPrint('❌ Failed to load vehicles: $e');
      final errorMessage = 'Failed to load vehicles: ${e.toString()}';
      _setError(errorMessage);

      // Track load failure (fire and forget - don't await)
      _analyticsService.trackEvent(
        eventType: 'vehicles_load_failed',
        eventData: {'error': errorMessage},
      ).catchError((err) => debugPrint('⚠️ Analytics tracking failed: $err'));
    } finally {
      // Always clear loading state, even on error
      _setLoading(false);
      // Ensure filters are applied even if empty
      _applyFilters();
      notifyListeners();
      debugPrint('✅ Vehicle loading completed. Total vehicles: ${_vehicles.length}, Filtered: ${_filteredVehicles.length}, Loading: $_isLoading');
      
      // Safety check: if loading is somehow still true, force it to false
      if (_isLoading) {
        debugPrint('⚠️ WARNING: Loading state still true after completion - forcing false');
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();

    // Track search query
    _analyticsService.trackEvent(
      eventType: 'vehicle_search',
      eventData: {'query': query},
    );

    notifyListeners();
  }

  void updateFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();

    _analyticsService.trackEvent(
      eventType: 'vehicle_filter_applied',
      eventData: {'filter': filter},
    );

    notifyListeners();
  }

  void updateCity(String city) {
    _selectedCity = city;
    _applyFilters();

    _analyticsService.trackEvent(
      eventType: 'vehicle_city_filter',
      eventData: {'city': city},
    );

    notifyListeners();
  }

  void updateCategory(String? category) {
    debugPrint('🎯 VehicleState: Setting category filter to: $category');
    _selectedCategory = category;
    _applyFilters();
    debugPrint('✅ VehicleState: Filtered vehicles count: ${_filteredVehicles.length}');

    _analyticsService.trackEvent(
      eventType: 'vehicle_category_filter',
      eventData: {'category': category ?? 'all'},
    );

    notifyListeners();
  }

  void clearCategoryFilter() {
    debugPrint('🧹 VehicleState: Clearing category filter (was: $_selectedCategory)');
    _selectedCategory = null;
    _applyFilters();
    debugPrint('✅ VehicleState: Filtered vehicles count after clear: ${_filteredVehicles.length}');
    notifyListeners();
  }

  void updateAdvancedFilters(Map<String, dynamic> filters) {
    _advancedFilters = filters;
    _applyFilters();

    _analyticsService.trackEvent(
      eventType: 'vehicle_advanced_filters',
      eventData: filters,
    );

    notifyListeners();
  }

  void _applyFilters() {
    debugPrint('🔧 Applying filters - Category: $_selectedCategory, City: $_selectedCity');
    
    _filteredVehicles = _vehicles.where((vehicle) {
      // City filter
      if (_selectedCity != 'All' && vehicle.city != _selectedCity) {
        return false;
      }

      // Category filter
      if (_selectedCategory != null && vehicle.category != _selectedCategory) {
        debugPrint('  ❌ Filtered out: ${vehicle.name} (category: ${vehicle.category}, looking for: $_selectedCategory)');
        return false;
      } else if (_selectedCategory != null) {
        debugPrint('  ✅ Matched: ${vehicle.name} (category: ${vehicle.category})');
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!vehicle.name.toLowerCase().contains(query) &&
            !vehicle.category.toLowerCase().contains(query) &&
            !vehicle.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Advanced filters
      if (_advancedFilters.isNotEmpty) {
        // Price filter
        if (_advancedFilters['minPrice'] != null &&
            vehicle.basePrice < _advancedFilters['minPrice']) {
          return false;
        }
        if (_advancedFilters['maxPrice'] != null &&
            vehicle.basePrice > _advancedFilters['maxPrice']) {
          return false;
        }

        // Seating capacity filter
        if (_advancedFilters['minSeating'] != null &&
            vehicle.seatingCapacity < _advancedFilters['minSeating']) {
          return false;
        }
        if (_advancedFilters['maxSeating'] != null &&
            vehicle.seatingCapacity > _advancedFilters['maxSeating']) {
          return false;
        }

        // Features filter
        if (_advancedFilters['features'] != null) {
          final requiredFeatures = _advancedFilters['features'] as List<String>;
          for (final feature in requiredFeatures) {
            if (!vehicle.features.contains(feature)) {
              return false;
            }
          }
        }
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredVehicles.sort((a, b) {
      switch (_selectedFilter) {
        case 'Price':
          return a.basePrice.compareTo(b.basePrice);
        case 'Seating':
          return b.seatingCapacity.compareTo(a.seatingCapacity);
        case 'Rating':
          return _calculateVehicleRating(b).compareTo(_calculateVehicleRating(a));
        default: // 'Name' or 'All'
          return a.name.compareTo(b.name);
      }
    });
  }

  double _calculateVehicleRating(Vehicle vehicle) {
    double rating = 4.0;

    // Adjust rating based on vehicle category
    switch (vehicle.category) {
      case 'Luxury Sedan':
        rating += 0.8;
        break;
      case 'SUV':
        rating += 0.6;
        break;
      case 'Sports Car':
        rating += 0.9;
        break;
      case 'Luxury Van':
        rating += 0.5;
        break;
    }

    // Bonus for premium features
    if (vehicle.features.contains('Leather Interior')) rating += 0.2;
    if (vehicle.features.contains('Wi-Fi')) rating += 0.1;
    if (vehicle.features.contains('Climate Control')) rating += 0.1;
    if (vehicle.features.contains('Premium Audio')) rating += 0.1;
    if (vehicle.features.contains('Massage Seats')) rating += 0.3;

    // Bonus for badges
    if (vehicle.badges.contains('Top Choice')) rating += 0.5;
    if (vehicle.badges.contains('Popular')) rating += 0.3;

    return rating.clamp(0.0, 5.0);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all vehicle data (used on logout)
  void clearAllData() {
    _vehicles = [];
    _filteredVehicles = [];
    _isLoading = false;
    _error = null;
    _searchQuery = '';
    _selectedFilter = 'All';
    _selectedCity = 'Johannesburg';
    _selectedCategory = null;
    _advancedFilters = {};
    _favoriteVehicleIds.clear();
    notifyListeners();
    debugPrint('🧹 Vehicle data cleared');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }
}
