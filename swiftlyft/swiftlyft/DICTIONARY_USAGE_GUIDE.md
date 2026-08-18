# Dictionary (Map) Usage Guide for SwiftLyft Frontend

## Overview
Dictionaries (`Map<String, dynamic>` in Dart) are key-value data structures that provide flexible storage and fast lookups. This guide shows where they're currently used and where they can be further implemented.

---

## ✅ Current Dictionary Usage

### 1. **Vehicle Models**
**Location:** `lib/models/vehicle.dart`

**Current Usage:**
- `specifications` - Vehicle specs (engine, transmission, etc.)
- `currentLocation` - GPS coordinates and location metadata
- `maintenance` - Maintenance records and schedules
- `insurance` - Insurance details
- `documents` - Vehicle documentation
- `surgePricing` - Time-based pricing multipliers
- `discounts` - Discount codes and amounts

**Example:**
```dart
final Vehicle vehicle = Vehicle(
  specifications: {
    'engine': 'V8',
    'transmission': 'Automatic',
    'fuelType': 'Petrol',
    'year': 2023,
  },
  surgePricing: {
    'peak_hours': 1.5,
    'weekend': 1.2,
    'holiday': 2.0,
  },
);
```

---

### 2. **Booking Models**
**Location:** `lib/models/booking.dart`

**Current Usage:**
- `routeInfo` - Navigation and route details
- `pricing` - Price breakdown (base, fees, discounts)
- `categoryRatings` - Multi-category ratings (driver, vehicle, service)
- `bookingsByMonth` - Monthly booking statistics
- `bookingsByStatus` - Status-based booking counts
- `serviceDetails` - Receipt/service details
- `originalData` / `requestedChanges` - Booking modification tracking

**Example:**
```dart
final Booking booking = Booking(
  routeInfo: {
    'distance': 15.5,
    'duration': 25,
    'waypoints': [...],
    'tollCost': 25.0,
  },
  pricing: {
    'baseFare': 150.0,
    'distanceCharge': 77.5,
    'timeCharge': 12.5,
    'tollFee': 25.0,
    'discount': -20.0,
    'total': 245.0,
  },
);
```

---

### 3. **Vehicle State Management**
**Location:** `lib/providers/vehicle_state.dart`

**Current Usage:**
- `_advancedFilters` - Complex filter criteria
- `_categoryCounts` - Vehicle counts by category

**Example:**
```dart
Map<String, dynamic> _advancedFilters = {
  'minPrice': 100.0,
  'maxPrice': 500.0,
  'minSeating': 4,
  'maxSeating': 8,
  'features': ['GPS', 'AC', 'Leather Seats'],
  'availability': true,
};
```

---

### 4. **User Analytics**
**Location:** `lib/models/analytics.dart`

**Current Usage:**
- `bookingsByMonth` - Booking frequency by month
- `spendingByCategory` - Spending per vehicle category
- `activityByHour` - User activity patterns
- `activityByDay` - Activity by day of week

**Example:**
```dart
final UserAnalytics analytics = UserAnalytics(
  bookingsByMonth: {
    '2024-01': 5,
    '2024-02': 8,
    '2024-03': 12,
  },
  spendingByCategory: {
    'sedan': 2500.0,
    'suv': 1800.0,
    'luxury': 5000.0,
  },
  activityByHour: {
    '08': 12,
    '09': 15,
    '17': 20,
  },
);
```

---

### 5. **Home Screen**
**Location:** `lib/screens/home_screen.dart`

**Current Usage:**
- `_categoryCounts` - Real-time vehicle counts per category
- `_vehicleCategories` - Category metadata and configuration

**Example:**
```dart
Map<String, int> _categoryCounts = {
  'sedan': 12,
  'suv': 8,
  'van': 6,
  'luxury': 4,
};
```

---

### 6. **Trip History Queue**
**Location:** `lib/providers/trip_history_queue_provider.dart`

**Current Usage:**
- `_processingItems` - Queue items currently being processed
- `_completedItems` - Completed queue operations
- `data` - Operation-specific data payloads

**Example:**
```dart
Map<String, TripHistoryQueueItem> _processingItems = {
  'booking-123': TripHistoryQueueItem(
    operation: TripQueueOperation.cancelBooking,
    data: {
      'reason': 'User cancelled',
      'refundAmount': 150.0,
    },
  ),
};
```

---

### 7. **Navigation & Routing**
**Location:** `lib/utils/routes.dart`

**Current Usage:**
- Screen navigation arguments - Pass data between screens

**Example:**
```dart
Navigator.pushNamed(
  context,
  AppRoutes.bookingCreation,
  arguments: {
    'vehicleId': 'veh-123',
    'vehicleName': 'BMW 7 Series',
    'vehicleType': 'sedan',
    'preSelected': true,
  },
);
```

---

### 8. **Location Models**
**Location:** `lib/models/location.dart`

**Current Usage:**
- `details` - Place-specific information (NearbyPlace)
- `suggestions` - Address validation suggestions
- `correctedAddress` - Auto-corrected address data

---

## 🚀 Recommended Additional Dictionary Usage

### 1. **Caching & Performance**
**Where:** Create `lib/utils/vehicle_cache.dart`

**Use Case:** Cache vehicle data with metadata
```dart
class VehicleCache {
  static final Map<String, Map<String, dynamic>> _cache = {};
  
  static void cacheVehicle(String id, Vehicle vehicle, {
    DateTime? expiresAt,
    String? source,
  }) {
    _cache[id] = {
      'vehicle': vehicle.toJson(),
      'cachedAt': DateTime.now().toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'source': source ?? 'api',
      'accessCount': 0,
    };
  }
  
  static Map<String, dynamic>? getVehicle(String id) {
    final cached = _cache[id];
    if (cached != null) {
      cached['accessCount'] = (cached['accessCount'] as int) + 1;
      return cached;
    }
    return null;
  }
  
  static Map<String, int> getCacheStats() {
    return {
      'totalVehicles': _cache.length,
      'totalAccesses': _cache.values
          .fold(0, (sum, item) => sum + (item['accessCount'] as int)),
    };
  }
}
```

---

### 2. **User Preferences**
**Where:** Create `lib/models/user_preferences.dart`

**Use Case:** Store user settings and preferences
```dart
class UserPreferences {
  final Map<String, dynamic> displaySettings = {
    'theme': 'light',
    'language': 'en',
    'currency': 'ZAR',
    'dateFormat': 'dd/MM/yyyy',
  };
  
  final Map<String, bool> notificationSettings = {
    'bookingConfirmed': true,
    'driverAssigned': true,
    'driverEnRoute': false,
    'promotions': true,
    'marketing': false,
  };
  
  final Map<String, dynamic> searchPreferences = {
    'defaultCity': 'Johannesburg',
    'preferredCategories': ['sedan', 'suv'],
    'priceRange': {'min': 100, 'max': 500},
    'sortBy': 'rating',
  };
  
  final Map<String, int> usageStats = {
    'totalSearches': 0,
    'totalFiltersApplied': 0,
    'favoriteCategories': {},
  };
}
```

---

### 3. **Error Handling & Logging**
**Where:** Enhance `lib/utils/error_handler.dart`

**Use Case:** Structured error tracking
```dart
class ErrorTracker {
  static final Map<String, Map<String, dynamic>> _errorLog = {};
  
  static void logError(String errorId, {
    required String errorType,
    required String message,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
  }) {
    _errorLog[errorId] = {
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace?.toString(),
      'context': context ?? {},
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'occurrenceCount': (_errorLog[errorId]?['occurrenceCount'] ?? 0) + 1,
    };
  }
  
  static Map<String, int> getErrorSummary() {
    final summary = <String, int>{};
    _errorLog.values.forEach((error) {
      final type = error['errorType'] as String;
      summary[type] = (summary[type] ?? 0) + 1;
    });
    return summary;
  }
}
```

---

### 4. **Booking Search Filters**
**Where:** Enhance `lib/providers/booking_state.dart`

**Use Case:** Complex booking search criteria
```dart
class BookingFilters {
  final Map<String, dynamic> filters = {
    'status': [],  // List of statuses to filter
    'dateRange': {
      'start': null,
      'end': null,
    },
    'priceRange': {
      'min': null,
      'max': null,
    },
    'vehicleCategories': [],
    'cities': [],
    'drivers': [],
    'sortBy': 'createdAt',
    'sortOrder': 'desc',
  };
  
  Map<String, dynamic> toApiParams() {
    return {
      'status': filters['status'],
      'startDate': filters['dateRange']['start']?.toIso8601String(),
      'endDate': filters['dateRange']['end']?.toIso8601String(),
      'minPrice': filters['priceRange']['min'],
      'maxPrice': filters['priceRange']['max'],
      'categories': filters['vehicleCategories'],
      'cities': filters['cities'],
      'sort': '${filters['sortBy']}_${filters['sortOrder']}',
    };
  }
}
```

---

### 5. **Local Storage / SharedPreferences Wrapper**
**Where:** Create `lib/utils/local_storage.dart`

**Use Case:** Structured local data persistence
```dart
class LocalStorage {
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData));
  }
  
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('userData');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }
  
  static Future<void> saveFilters(Map<String, dynamic> filters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehicleFilters', jsonEncode(filters));
  }
  
  static Future<Map<String, dynamic>> getFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('vehicleFilters');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return {};
  }
}
```

---

### 6. **Real-time Tracking State**
**Where:** Create `lib/providers/tracking_state.dart`

**Use Case:** Track multiple active bookings
```dart
class TrackingState extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _activeTrackings = {};
  
  void updateLocation(String bookingId, LatLng location, {
    double? speed,
    double? heading,
    Duration? eta,
  }) {
    _activeTrackings[bookingId] = {
      'location': {'lat': location.latitude, 'lng': location.longitude},
      'speed': speed,
      'heading': heading,
      'eta': eta?.inSeconds,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
    notifyListeners();
  }
  
  Map<String, dynamic>? getTracking(String bookingId) {
    return _activeTrackings[bookingId];
  }
  
  Map<String, LatLng> getAllLocations() {
    return Map.fromEntries(
      _activeTrackings.entries.map((e) => MapEntry(
        e.key,
        LatLng(
          e.value['location']['lat'],
          e.value['location']['lng'],
        ),
      )),
    );
  }
}
```

---

### 7. **Form State Management**
**Where:** Enhance `lib/screens/booking_creation_screen.dart`

**Use Case:** Manage complex form data
```dart
class BookingFormState {
  final Map<String, dynamic> formData = {
    'vehicleId': null,
    'pickupAddress': null,
    'dropoffAddress': null,
    'pickupTime': null,
    'passengerCount': 1,
    'specialNotes': null,
    'closeProtectionOfficer': false,
    'paymentMethodId': null,
  };
  
  final Map<String, String?> validationErrors = {};
  
  bool get isValid {
    return validationErrors.isEmpty &&
        formData['vehicleId'] != null &&
        formData['pickupAddress'] != null &&
        formData['dropoffAddress'] != null;
  }
  
  Map<String, dynamic> toBookingPayload() {
    return {
      'vehicleId': formData['vehicleId'],
      'pickupAddress': formData['pickupAddress'],
      'dropoffAddress': formData['dropoffAddress'],
      'pickupTime': (formData['pickupTime'] as DateTime?)?.toIso8601String(),
      'passengerCount': formData['passengerCount'],
      'specialNotes': formData['specialNotes'],
      'closeProtectionOfficer': formData['closeProtectionOfficer'],
    };
  }
}
```

---

### 8. **Feature Flags**
**Where:** Create `lib/utils/feature_flags.dart`

**Use Case:** Remote configuration and A/B testing
```dart
class FeatureFlags {
  static final Map<String, dynamic> _flags = {
    'enableBookingStack': true,
    'enableQueueSystem': true,
    'enableAdvancedFilters': false,
    'enableRealTimeTracking': true,
    'enablePushNotifications': false,
    'experimentalFeatures': {
      'newCheckoutFlow': false,
      'aiRecommendations': true,
    },
    'rateLimits': {
      'searchPerMinute': 10,
      'bookingsPerHour': 5,
    },
  };
  
  static bool isEnabled(String flag) {
    return _flags[flag] == true;
  }
  
  static Map<String, dynamic> getExperimentalFeatures() {
    return _flags['experimentalFeatures'] as Map<String, dynamic>;
  }
  
  static void updateFlags(Map<String, dynamic> newFlags) {
    _flags.addAll(newFlags);
  }
}
```

---

### 9. **API Request/Response Metadata**
**Where:** Enhance API services

**Use Case:** Track API calls and responses
```dart
class ApiCallTracker {
  static final Map<String, Map<String, dynamic>> _apiCalls = {};
  
  static void trackRequest(String requestId, {
    required String endpoint,
    required String method,
    Map<String, dynamic>? params,
  }) {
    _apiCalls[requestId] = {
      'endpoint': endpoint,
      'method': method,
      'params': params,
      'startedAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    };
  }
  
  static void trackResponse(String requestId, {
    required int statusCode,
    required Duration duration,
    dynamic response,
    String? error,
  }) {
    if (_apiCalls.containsKey(requestId)) {
      _apiCalls[requestId]!.addAll({
        'statusCode': statusCode,
        'duration': duration.inMilliseconds,
        'completedAt': DateTime.now().toIso8601String(),
        'status': statusCode < 400 ? 'success' : 'error',
        'error': error,
      });
    }
  }
  
  static Map<String, int> getApiStats() {
    final stats = <String, int>{
      'totalCalls': _apiCalls.length,
      'successful': 0,
      'failed': 0,
    };
    
    _apiCalls.values.forEach((call) {
      if (call['status'] == 'success') {
        stats['successful'] = (stats['successful'] ?? 0) + 1;
      } else if (call['status'] == 'error') {
        stats['failed'] = (stats['failed'] ?? 0) + 1;
      }
    });
    
    return stats;
  }
}
```

---

### 10. **Vehicle Comparison**
**Where:** Enhance `lib/screens/booking_stack_screen.dart`

**Use Case:** Compare multiple vehicles side-by-side
```dart
class VehicleComparison {
  final Map<String, Map<String, dynamic>> _comparison = {};
  
  void addVehicle(Vehicle vehicle) {
    _comparison[vehicle.id] = {
      'name': vehicle.name,
      'category': vehicle.category,
      'basePrice': vehicle.basePrice,
      'seatingCapacity': vehicle.seatingCapacity,
      'rating': vehicle.rating,
      'features': vehicle.features,
      'specifications': vehicle.specifications,
    };
  }
  
  Map<String, dynamic> getComparison() {
    return {
      'vehicles': _comparison,
      'priceRange': {
        'min': _comparison.values
            .map((v) => v['basePrice'] as double)
            .reduce((a, b) => a < b ? a : b),
        'max': _comparison.values
            .map((v) => v['basePrice'] as double)
            .reduce((a, b) => a > b ? a : b),
      },
      'averageRating': _comparison.values
          .map((v) => v['rating'] as double)
          .reduce((a, b) => a + b) / _comparison.length,
    };
  }
}
```

---

## 📊 Dictionary Usage Best Practices

### 1. **Type Safety**
```dart
// ❌ Bad - No type safety
Map<String, dynamic> data = {'count': 5};
int count = data['count']; // Runtime error risk

// ✅ Good - Type checking
Map<String, dynamic> data = {'count': 5};
int count = (data['count'] as int? ?? 0); // Safe
```

### 2. **Null Safety**
```dart
// ❌ Bad - Can throw null error
final price = vehicle.specifications['price'];

// ✅ Good - Null safe
final price = vehicle.specifications['price'] as double? ?? 0.0;
```

### 3. **Immutable Maps**
```dart
// ✅ Create unmodifiable maps for public APIs
Map<String, dynamic> get publicData {
  return Map.unmodifiable(_internalData);
}
```

### 4. **Nested Maps**
```dart
// ✅ Use helper methods for nested access
double? getNestedValue(Map<String, dynamic> map, List<String> keys) {
  dynamic current = map;
  for (final key in keys) {
    if (current is Map<String, dynamic>) {
      current = current[key];
    } else {
      return null;
    }
  }
  return current as double?;
}
```

---

## 📈 Performance Considerations

1. **Small Maps (< 10 items)**: Direct access is fast
2. **Medium Maps (10-100 items)**: Consider using typed keys
3. **Large Maps (> 100 items)**: Consider using `LinkedHashMap` for ordered access or specialized data structures

---

## 🔄 Migration Patterns

### From Lists to Maps (for faster lookups)
```dart
// ❌ Before - O(n) lookup
List<Vehicle> vehicles = [...];
Vehicle? findVehicle(String id) {
  return vehicles.firstWhere((v) => v.id == id, orElse: () => null);
}

// ✅ After - O(1) lookup
Map<String, Vehicle> vehicles = {};
Vehicle? findVehicle(String id) {
  return vehicles[id];
}
```

---

## 📝 Summary

**Current Usage:**
- ✅ Vehicle specifications and metadata
- ✅ Booking route and pricing info
- ✅ Filter criteria
- ✅ Analytics data
- ✅ Navigation arguments
- ✅ Queue management

**Recommended Additional Usage:**
- 🚀 Caching layer
- 🚀 User preferences
- 🚀 Error tracking
- 🚀 Form state
- 🚀 Real-time tracking
- 🚀 Feature flags
- 🚀 API metadata
- 🚀 Vehicle comparison

Dictionaries are perfect for flexible, key-value data structures where you need fast lookups and dynamic schema!

