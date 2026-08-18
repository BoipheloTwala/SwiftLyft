# Vehicle Category Filtering

## Overview
This document describes the category filtering feature that allows users to filter vehicles by category (sedan, SUV, luxury, van, hybrid) when clicking on category cards on the home screen.

## Features Implemented

### 1. Dynamic Vehicle Category Cards
- Home screen displays 5 category cards:
  - **Luxury Sedans** (sedan)
  - **SUVs** (suv)
  - **Luxury Vans** (van)
  - **Sports Cars** (luxury)
  - **Hybrid Cars** (hybrid) ✨ **NEW**
  
- Each card shows:
  - Category name and description
  - Dynamic vehicle count fetched from backend
  - Category-specific icon and color

### 2. Category Filtering
When a user clicks on a category card:
- Navigates to Vehicle Listing Screen
- Automatically filters vehicles by the selected category
- Updates the AppBar title to show the category name
- Displays a "Clear Filter" button to remove the filter

### 3. State Management

#### VehicleState Updates
**File**: `swiftlyft/lib/providers/vehicle_state.dart`

Added:
```dart
String? _selectedCategory; // null means 'All categories'

void updateCategory(String? category) {
  _selectedCategory = category;
  _applyFilters();
  // Analytics tracking
  notifyListeners();
}

void clearCategoryFilter() {
  _selectedCategory = null;
  _applyFilters();
  notifyListeners();
}
```

#### AppState Proxy Methods
**File**: `swiftlyft/lib/providers/app_state.dart`

Added:
```dart
void updateCategory(String? category) => vehicles.updateCategory(category);
void clearCategoryFilter() => vehicles.clearCategoryFilter();
```

### 4. Filter Logic
**File**: `swiftlyft/lib/providers/vehicle_state.dart` - `_applyFilters()` method

Added category filtering before other filters:
```dart
// Category filter
if (_selectedCategory != null && vehicle.category != _selectedCategory) {
  return false;
}
```

This ensures that:
1. Category filter is applied first
2. Works alongside city filters
3. Compatible with search and advanced filters
4. Maintains sorting preferences

### 5. Navigation with Arguments

#### Home Screen
**File**: `swiftlyft/lib/screens/home_screen.dart`

Each category card navigates with:
```dart
Navigator.pushNamed(
  context,
  AppRoutes.vehicleListing,
  arguments: {
    'category': category['category'],      // Database value (e.g., 'sedan')
    'categoryName': category['name'],      // Display name (e.g., 'Luxury Sedans')
  },
);
```

#### Vehicle Listing Screen
**File**: `swiftlyft/lib/screens/vehicle_listing_screen.dart`

On screen initialization:
1. Extracts category from route arguments
2. Applies category filter via `appState.updateCategory()`
3. Updates AppBar title with category name
4. Shows "Clear Filter" button if category is active
5. Loads filtered vehicles

## User Experience

### 1. Browsing by Category
1. User sees category cards on home screen with dynamic counts
2. Clicks on a category (e.g., "Hybrid Cars")
3. Navigates to Vehicle Listing Screen
4. Sees only hybrid vehicles
5. AppBar shows "Hybrid Cars" as title
6. Can still filter by city using tabs
7. Can use search and advanced filters

### 2. Clearing Filter
1. Click "Clear Filter" button in AppBar
2. Returns to home screen
3. Category filter is removed
4. Next visit to Vehicle Listing shows all vehicles

### 3. Combined Filtering
Users can combine multiple filters:
- **Category**: Hybrid Cars
- **City**: Johannesburg
- **Search**: "Tesla"
- **Price Range**: R100 - R200
- **Features**: Air Conditioning, Bluetooth

All filters work together seamlessly.

## Backend Integration

### Vehicle Model
**File**: `Swiftlyft_backend/models/Vehicle.js`

Categories enum:
```javascript
category: {
  type: String,
  required: true,
  enum: ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle', 'electric', 'hybrid']
}
```

### API Endpoints
1. **GET /api/vehicles/available**
   - Returns vehicles with category field
   - Supports filtering via query params

2. **GET /api/vehicles/categories**
   - Returns category counts for home screen cards

## Analytics
Category filter usage is tracked via:
```dart
_analyticsService.trackEvent(
  eventType: 'vehicle_category_filter',
  eventData: {'category': category ?? 'all'},
);
```

## Testing

### Manual Testing Checklist
- [ ] Click each category card on home screen
- [ ] Verify filtered vehicles match selected category
- [ ] Check AppBar title shows category name
- [ ] Test "Clear Filter" button functionality
- [ ] Combine category filter with city tabs
- [ ] Verify search works with category filter
- [ ] Check advanced filters work alongside category filter
- [ ] Confirm vehicle counts update on home screen
- [ ] Test navigation back button behavior

### Edge Cases
- [ ] Empty category (no vehicles available)
- [ ] All vehicles filtered out by combined filters
- [ ] Switching categories multiple times
- [ ] Category filter + search with no results
- [ ] Network errors during vehicle load

## Files Modified

### Frontend
1. `swiftlyft/lib/screens/home_screen.dart`
   - Added hybrid car category card
   - Updated navigation to pass category arguments

2. `swiftlyft/lib/screens/vehicle_listing_screen.dart`
   - Extract category from route arguments
   - Apply category filter on init
   - Dynamic AppBar title
   - Clear filter button

3. `swiftlyft/lib/providers/vehicle_state.dart`
   - Added `_selectedCategory` state
   - Added `updateCategory()` method
   - Added `clearCategoryFilter()` method
   - Updated `_applyFilters()` logic

4. `swiftlyft/lib/providers/app_state.dart`
   - Added category method proxies

### Backend
No backend changes required - existing category field and endpoints support this feature.

## Future Enhancements

### Potential Improvements
1. **Category Chips**: Show active filters as removable chips
2. **Multi-Category**: Allow selecting multiple categories
3. **Saved Filters**: Remember user's preferred categories
4. **Quick Filter Bar**: Category buttons on Vehicle Listing Screen
5. **Category Badges**: Visual indicators on vehicle cards
6. **Filter History**: Track and suggest frequently used filters
7. **Smart Suggestions**: "Based on your bookings, try SUVs"

### Performance Optimizations
1. Cache category counts
2. Prefetch filtered vehicles
3. Lazy load vehicle images by category
4. Background refresh of category data

## Known Limitations
1. Category filter resets when app restarts (not persisted)
2. Cannot select multiple categories simultaneously
3. No visual indication of active filter on home screen

## Bug Fixes

### Issue #1: Category Filter Persisting Between Navigations
**Problem**: When clicking different category cards, the filter from the previous selection would persist, showing incorrect vehicles.

**Initial Solution**: Clear filter in both `initState()` and `dispose()`

**Issue #2: Filter Showing One Step Behind**
**Problem**: UI was displaying vehicles from the previous category selection, appearing "one step behind" the actual filter.

**Root Cause #1**: The `dispose()` method was clearing the filter AFTER the new screen's `initState()` had already applied the new filter.

**Solution #1**: Removed `clearCategoryFilter()` from `dispose()`

**Root Cause #2**: Using `WidgetsBinding.instance.addPostFrameCallback()` to apply the filter caused it to be applied AFTER the first frame was built, showing all vehicles initially:
1. Navigate to VehicleListingScreen
2. **`build()` runs → Shows all 8 vehicles** (filter is still `null`) ❌
3. `initState()` → `addPostFrameCallback()` → Filter is applied ❌
4. Next build → Shows filtered vehicles

**Final Solution**:
Use `didChangeDependencies()` instead of `addPostFrameCallback()` to apply the filter BEFORE the first build.

**Implementation**:
```dart
class _VehicleListingScreenState extends State<VehicleListingScreen> {
  bool _hasAppliedFilter = false; // Prevent re-applying on rebuild
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Apply filter only once when screen first loads
    if (!_hasAppliedFilter) {
      _hasAppliedFilter = true;
      
      final appState = Provider.of<AppState>(context, listen: false);
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null && args['category'] != null) {
        // Apply new category filter BEFORE first build
        appState.updateCategory(args['category'] as String);
      } else {
        // Clear if no category specified
        appState.clearCategoryFilter();
      }
      
      // Load vehicles with filter applied
      appState.loadVehicles();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    super.dispose(); // NO filter clearing
  }
}
```

This ensures:
- Filter is applied BEFORE the first frame renders
- UI immediately shows correct filtered vehicles
- No "flash" of unfiltered vehicles
- Clean, instant category transitions

## Conclusion
The category filtering feature provides an intuitive way for users to browse vehicles by type, enhancing the user experience and making it easier to find the right vehicle for their needs. The implementation is scalable, maintainable, and follows Flutter best practices.

