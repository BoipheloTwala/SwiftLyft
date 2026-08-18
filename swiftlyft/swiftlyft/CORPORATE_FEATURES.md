# Corporate Account Features

This document explains how to integrate and use the corporate account features in the SwiftLyft app.

## Overview

Corporate accounts allow businesses to:
- Manage company-wide travel budgets
- Get corporate discounts on rides
- Create bulk bookings for multiple trips
- Track spending and usage
- Authorize multiple users

## Backend Structure

The backend already has corporate account support:
- **GET /api/users/corporate** - Get corporate account info and bulk bookings
- **POST /api/corporate/bookings** - Create bulk bookings (corporate users only)
- **GET /api/users/:userId/corporate/bookings** - Get corporate bookings with pagination

## Frontend Implementation

### 1. Models (`lib/models/corporate.dart`)

Three main models:
- **`CorporateAccount`** - Company info, budget, discount, status
- **`BulkBooking`** - Collection of trips for corporate use
- **`BulkBookingTrip`** - Individual trip within a bulk booking
- **`CorporateInfo`** - Wrapper containing account + bookings

### 2. Services (`lib/services/user_api_service.dart`)

Added methods:
```dart
// Get corporate account info (returns null if no corporate account)
Future<CorporateInfo?> getCorporateInfo()

// Check if user has corporate account
Future<bool> hasCorporateAccount()

// Create bulk booking (corporate users only)
Future<BulkBooking> createBulkBooking({...})

// Get corporate bookings with pagination
Future<List<BulkBooking>> getCorporateBookings({...})
```

### 3. State Management (`lib/providers/app_state.dart`)

Added to AppState:
```dart
// Getters
CorporateInfo? get corporateInfo
bool get isLoadingCorporate
String? get corporateError
bool get isCorporateUser  // true if user has active corporate account

// Methods
Future<void> loadCorporate()  // Load corporate data
Future<BulkBooking> createBulkBooking({...})  // Create booking
```

### 4. Widgets (`lib/widgets/corporate_account_card.dart`)

Pre-built widget `CorporateAccountCard` displays:
- Company name and status
- Contact information
- Budget usage with progress bar
- Corporate discount percentage
- Recent bulk bookings

## Integration Examples

### Display Corporate Account in Settings

Add to `settings_screen.dart`:

```dart
import '../widgets/corporate_account_card.dart';

// In your build method, add:
Consumer<AppState>(
  builder: (context, appState, _) {
    if (appState.isCorporateUser) {
      return Column(
        children: [
          const SizedBox(height: 20),
          const CorporateAccountCard(),
        ],
      );
    }
    return const SizedBox.shrink();
  },
)
```

### Create Bulk Booking

```dart
final appState = Provider.of<AppState>(context, listen: false);

try {
  final booking = await appState.createBulkBooking(
    title: 'Weekly Team Transport',
    description: 'Daily commute for sales team',
    bookingType: 'recurring',
    trips: [
      {
        'pickupLocation': {
          'address': 'Office A',
          'coordinates': {'latitude': -26.2, 'longitude': 28.04}
        },
        'dropoffLocation': {
          'address': 'Client Site B',
          'coordinates': {'latitude': -26.1, 'longitude': 28.05}
        },
        'passengerName': 'John Doe',
        'passengerPhone': '+27821234567',
        'scheduledTime': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
      },
      // ... more trips
    ],
    specialInstructions: 'Please arrive 5 minutes early',
  );
  
  print('Bulk booking created: ${booking.id}');
} catch (e) {
  print('Failed to create bulk booking: $e');
}
```

### Check Corporate Status

```dart
Consumer<AppState>(
  builder: (context, appState, _) {
    if (appState.isCorporateUser) {
      final corp = appState.corporateInfo!.corporateAccount;
      return Text('You have ${corp.discountPercentage}% corporate discount!');
    }
    return const Text('Regular user account');
  },
)
```

### Show Budget Warning

```dart
final corp = appState.corporateInfo?.corporateAccount;
if (corp != null && corp.budgetUsagePercentage > 0.9) {
  return AlertDialog(
    title: Text('Budget Alert'),
    content: Text('Your company has used ${(corp.budgetUsagePercentage * 100).toStringAsFixed(1)}% of the monthly budget.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  );
}
```

## UI Placements

### Recommended locations for corporate features:

1. **Settings/Profile Screen** - Show `CorporateAccountCard` for corporate users
2. **Booking Screen** - Add "Create Bulk Booking" button for corporate users
3. **Home Screen** - Display corporate discount badge
4. **Navigation Menu** - Add "Corporate" or "Bulk Bookings" menu item if `isCorporateUser` is true

### Example: Conditional Menu Item

```dart
if (appState.isCorporateUser)
  ListTile(
    leading: Icon(Icons.business),
    title: Text('Corporate Bookings'),
    onTap: () {
      Navigator.pushNamed(context, AppRoutes.corporateBookings);
    },
  ),
```

## Data Flow

1. **On Login**: `AppState._initializeUserData()` calls `loadCorporate()`
2. **Load Corporate**: Calls `UserService.getCorporateInfo()`
3. **API Response**: Backend returns corporate account + bulk bookings (or 404 if not corporate)
4. **State Update**: `corporateInfo` is populated, `notifyListeners()` triggers UI rebuild
5. **UI Display**: Widgets using `Consumer<AppState>` automatically show corporate features

## Corporate Account Properties

```dart
class CorporateAccount {
  String id;
  String companyName;
  String companyEmail;
  String contactPerson;
  String contactPhone;
  double discountPercentage;    // e.g., 15.0 = 15% discount
  double monthlyBudget;         // e.g., 50000.0
  double usedBudget;            // e.g., 32500.0
  String status;                // 'active', 'suspended', 'pending'
  DateTime createdAt;
  DateTime? expiresAt;
  List<String> authorizedUsers; // User IDs who can use this account
  
  // Computed properties
  double remainingBudget;       // monthlyBudget - usedBudget
  double budgetUsagePercentage; // 0.0 to 1.0
  bool isActive;                // status == 'active'
  bool isSuspended;             // status == 'suspended'
  bool isPending;               // status == 'pending'
}
```

## Testing

To test corporate features:

1. **Create a corporate user in the backend** (database or admin panel)
2. **Set corporate account fields** in User document:
   ```javascript
   {
     corporateAccount: {
       companyName: 'Test Corp',
       companyEmail: 'corp@test.com',
       contactPerson: 'Jane Smith',
       contactPhone: '+27821234567',
       discountPercentage: 15,
       monthlyBudget: 50000,
       usedBudget: 25000,
       status: 'active'
     }
   }
   ```
3. **Login as corporate user** in the app
4. **Verify**:
   - `appState.isCorporateUser` is true
   - `CorporateAccountCard` displays correctly
   - Budget progress bar shows correct percentage
   - Discount badge appears

## Notes

- Corporate features are automatically hidden for regular users (no corporate account)
- The `loadCorporate()` method handles 404 gracefully - it's not an error if user isn't corporate
- All corporate API calls require authentication
- Budget tracking is managed by the backend when bookings are completed
- Frontend only displays data - it doesn't enforce budget limits (backend handles that)

## Future Enhancements

Consider adding:
- Dedicated corporate bookings screen with full list
- Budget history/analytics charts
- Ability to filter bookings by date range
- Export corporate booking reports
- Multi-company support for users in multiple organizations
- Real-time budget notifications

