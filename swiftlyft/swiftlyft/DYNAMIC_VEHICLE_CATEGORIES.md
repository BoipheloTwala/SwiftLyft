# Dynamic Vehicle Categories - Home Screen

## Overview
Updated the Home Screen vehicle category cards to display **real-time vehicle counts** from the backend database instead of hardcoded values.

**Date:** November 2024  
**Status:** ✅ Implemented

---

## Problem

The home screen displayed **hardcoded vehicle counts** that didn't match the actual database:

| Category | Old (Hardcoded) | Actual (Database) |
|----------|----------------|-------------------|
| Luxury Sedans | 12 | 2 |
| SUVs | 8 | 2 |
| Luxury Vans | 6 | 2 |
| Sports Cars | 4 | 2 |

**Total Displayed:** 30 vehicles  
**Total Actual:** 8 vehicles

---

## Solution

### ✅ Changes Made

#### 1. **Added Category Mapping**
Each home screen category now maps to a database category:

```dart
final List<Map<String, dynamic>> _vehicleCategories = [
  {
    'name': 'Luxury Sedans',
    'category': 'sedan',  // ← Database mapping
    'vehicleCount': 0,    // ← Will be updated from API
    ...
  },
  {
    'name': 'SUVs',
    'category': 'suv',     // ← Database mapping
    'vehicleCount': 0,     // ← Will be updated from API
    ...
  },
  {
    'name': 'Luxury Vans',
    'category': 'van',     // ← Database mapping
    'vehicleCount': 0,     // ← Will be updated from API
    ...
  },
  {
    'name': 'Sports Cars',
    'category': 'luxury',  // ← Database mapping
    'vehicleCount': 0,     // ← Will be updated from API
    ...
  },
];
```

#### 2. **Added State Variables**
```dart
bool _isLoadingCategories = true;
Map<String, int> _categoryCounts = {};
```

#### 3. **Added initState() Method**
Fetches vehicle counts when the home screen loads:

```dart
@override
void initState() {
  super.initState();
  _loadVehicleCategoryCounts();
}
```

#### 4. **Implemented _loadVehicleCategoryCounts()**
Loads vehicles from backend and calculates category counts:

```dart
Future<void> _loadVehicleCategoryCounts() async {
  try {
    // Load vehicles from backend
    await Provider.of<AppState>(context, listen: false)
        .vehicles
        .loadVehicles();
    
    // Get loaded vehicles
    final vehicleService = Provider.of<AppState>(context, listen: false).vehicles;
    final vehicles = vehicleService.vehicles;
    
    // Count vehicles by category
    final counts = <String, int>{};
    for (var vehicle in vehicles) {
      final category = vehicle.category;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    
    // Update UI
    setState(() {
      _categoryCounts = counts;
      _isLoadingCategories = false;
      
      // Update each category's vehicle count
      for (var category in _vehicleCategories) {
        final dbCategory = category['category'] as String;
        category['vehicleCount'] = counts[dbCategory] ?? 0;
      }
    });
  } catch (e) {
    debugPrint('Failed to load vehicle category counts: $e');
    setState(() {
      _isLoadingCategories = false;
    });
  }
}
```

---

## Database Schema

### Vehicle Categories Enum
From `Swiftlyft_backend/models/Vehicle.js`:

```javascript
category: {
  type: String,
  required: true,
  enum: [
    'sedan',
    'suv',
    'luxury',
    'van',
    'truck',
    'motorcycle',
    'electric',
    'hybrid'
  ]
}
```

### Mock Data (setupVehiclesDatabase.js)
Creates **8 vehicles** with these categories:

```javascript
const categories = ['sedan', 'suv', 'luxury', 'van'];

// Distribution (cycling through):
// Index 0: sedan    (Toyota Corolla)
// Index 1: suv      (VW Polo)
// Index 2: luxury   (BMW X5)
// Index 3: van      (Mercedes C200)
// Index 4: sedan    (Toyota Corolla)
// Index 5: suv      (VW Polo)
// Index 6: luxury   (BMW X5)
// Index 7: van      (Mercedes C200)
```

**Actual Counts:**
- `sedan`: 2 vehicles
- `suv`: 2 vehicles
- `luxury`: 2 vehicles
- `van`: 2 vehicles

---

## Category Mapping Logic

| Frontend Display | Database Category | Logic |
|-----------------|-------------------|-------|
| **Luxury Sedans** | `sedan` | Premium sedans for business |
| **SUVs** | `suv` | Sport Utility Vehicles |
| **Luxury Vans** | `van` | Corporate vans for events |
| **Sports Cars** | `luxury` | High-end luxury vehicles |

**Note:** "Sports Cars" maps to `luxury` category since there's no dedicated `sports` category in the database. The `luxury` category represents high-end vehicles which can include sports cars.

---

## Data Flow

```
User Opens Home Screen
    ↓
initState() triggered
    ↓
_loadVehicleCategoryCounts() called
    ↓
Load vehicles via AppState.vehicles.loadVehicles()
    ↓
Backend API: GET /api/vehicles
    ↓
Returns list of vehicles with categories
    ↓
Count vehicles by category
    ↓
Update _vehicleCategories with real counts
    ↓
setState() triggers UI rebuild
    ↓
Cards display actual counts from database
```

---

## Backend API

### Endpoint Used
**GET** `/api/vehicles`

Returns list of all active vehicles.

### Alternative: Stats Endpoint
**GET** `/api/vehicles/stats`

Returns aggregated statistics by category:

```json
{
  "success": true,
  "data": [
    {
      "_id": "sedan",
      "count": 2,
      "available": 1,
      "averageRating": 5.0,
      "totalEarnings": 0
    },
    {
      "_id": "suv",
      "count": 2,
      "available": 1,
      "averageRating": 5.0,
      "totalEarnings": 0
    },
    ...
  ]
}
```

**Future Enhancement:** Could use this stats endpoint directly for better performance instead of counting from the vehicles list.

---

## UI Behavior

### Before (Hardcoded)
- Categories always showed: 12, 8, 6, 4
- Counts never changed
- No relationship to actual database

### After (Dynamic)
- Categories show real counts from database
- Updates on every home screen load
- Reflects actual vehicle availability
- Shows 0 if no vehicles in category

### Loading State
- `_isLoadingCategories` tracks loading state
- Could add loading shimmer/skeleton (future enhancement)
- Gracefully handles errors

---

## Example Output

With current **8 mock vehicles** in database:

```
┌─────────────────┬───────┐
│ Luxury Sedans   │   2   │  ← sedan
├─────────────────┼───────┤
│ SUVs            │   2   │  ← suv
├─────────────────┼───────┤
│ Luxury Vans     │   2   │  ← van
├─────────────────┼───────┤
│ Sports Cars     │   2   │  ← luxury
└─────────────────┴───────┘
Total: 8 vehicles
```

If you add more vehicles via `seedVehiclesDatabase.js` (12 vehicles):

```
┌─────────────────┬───────┐
│ Luxury Sedans   │   2   │  ← sedan
├─────────────────┼───────┤
│ SUVs            │   2   │  ← suv
├─────────────────┼───────┤
│ Luxury Vans     │   2   │  ← van
├─────────────────┼───────┤
│ Sports Cars     │   2   │  ← luxury
├─────────────────┼───────┤
│ (Electric)      │   2   │  ← electric (not shown)
├─────────────────┼───────┤
│ (Hybrid)        │   2   │  ← hybrid (not shown)
└─────────────────┴───────┘
Total: 12 vehicles
```

**Note:** Electric and Hybrid categories exist in DB but aren't displayed on home screen. You could add them if needed.

---

## Future Enhancements

### 1. **Use Stats Endpoint**
Instead of loading all vehicles and counting, call `/api/vehicles/stats`:

```dart
final stats = await vehicleService.getVehicleStats();
// stats already contains counts by category
```

### 2. **Add Loading Indicators**
Show skeleton/shimmer while loading:

```dart
if (_isLoadingCategories) {
  return ShimmerCategoryCards();
}
```

### 3. **Add Pull-to-Refresh**
Allow users to manually refresh counts:

```dart
RefreshIndicator(
  onRefresh: _loadVehicleCategoryCounts,
  child: _buildVehicleCategories(),
)
```

### 4. **Cache Counts**
Store counts locally to show immediately on app start:

```dart
// Save to SharedPreferences
SharedPreferences.setInt('category_sedan_count', count);

// Load from cache on init
final cachedCount = SharedPreferences.getInt('category_sedan_count') ?? 0;
```

### 5. **Add More Categories**
Display electric and hybrid vehicles:

```dart
{
  'name': 'Electric Vehicles',
  'category': 'electric',
  'icon': Icons.electric_car,
  ...
},
{
  'name': 'Hybrid Vehicles',
  'category': 'hybrid',
  'icon': Icons.eco,
  ...
}
```

### 6. **Filter on Click**
When user taps a category, show only those vehicles:

```dart
onTap: () {
  Navigator.pushNamed(
    context,
    AppRoutes.vehicleListing,
    arguments: {'category': category['category']},
  );
}
```

---

## Testing

### Manual Testing

1. **Initial Load**
   ```
   1. Open app
   2. Navigate to Home screen
   3. Verify category counts match database
   4. Check console for any errors
   ```

2. **Add Vehicles**
   ```
   1. Add vehicles to database (run seeder)
   2. Restart app or reload home screen
   3. Verify counts updated
   ```

3. **Empty Database**
   ```
   1. Clear all vehicles from database
   2. Reload home screen
   3. Verify counts show 0
   4. No errors should occur
   ```

4. **Backend Offline**
   ```
   1. Stop backend server
   2. Reload home screen
   3. Verify graceful error handling
   4. Check error message in console
   ```

### Expected Behavior

| Scenario | Expected Result |
|----------|----------------|
| 8 vehicles in DB | Shows 2, 2, 2, 2 |
| 12 vehicles in DB | Shows 2, 2, 2, 2, (+ 4 other) |
| 0 vehicles in DB | Shows 0, 0, 0, 0 |
| Backend offline | Shows 0, 0, 0, 0 (with error log) |
| Loading | Shows previous counts or 0 |

---

## Files Modified

1. **`swiftlyft/lib/screens/home_screen.dart`**
   - Added `Provider` and `AppState` imports
   - Added state variables for loading and counts
   - Added `initState()` method
   - Implemented `_loadVehicleCategoryCounts()` method
   - Added category mapping to vehicle categories
   - Set initial vehicleCount to 0

---

## Database Seeders

To change vehicle counts, use these scripts:

### Add 8 Vehicles (Default)
```bash
cd Swiftlyft_backend
node scripts/setupVehiclesDatabase.js --sample-data
```

### Add 12 Vehicles (Extended)
```bash
cd Swiftlyft_backend
node scripts/seedVehiclesDatabase.js
```

### Clear and Reseed
```javascript
// In seedVehiclesDatabase.js
await seeder.seed({ count: 12, clearExisting: true });
```

---

## Summary

✅ **Dynamic Counts:** Categories now show real vehicle counts  
✅ **Database Mapping:** Each category maps to DB category  
✅ **Auto-Refresh:** Counts update on home screen load  
✅ **Error Handling:** Gracefully handles API failures  
✅ **No Breaking Changes:** Existing functionality preserved  
✅ **Performance:** Uses existing vehicle loading mechanism  

**Result:** Home screen now displays **accurate, real-time vehicle counts** from the backend database!

---

**Last Updated:** November 2024  
**Status:** ✅ Implemented and Tested  
**Platform:** Mobile, Tablet, Desktop (Web)

