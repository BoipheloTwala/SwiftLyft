# Bulk Bookings Management System

## Overview
The Bulk Bookings feature allows corporate users to manage multiple transportation bookings efficiently. This feature is designed specifically for business accounts that need to coordinate transportation for multiple employees, events, or departments.

## Features

### 1. **Bulk Booking Management**
- Create and manage multiple vehicle bookings in a single request
- Track booking status (draft, pending, confirmed, completed, cancelled)
- View comprehensive summaries of all bookings
- Filter bookings by status
- Paginated list view for efficient data loading

### 2. **Booking Information**
Each bulk booking contains:
- **Title & Description**: Clear identification of the booking purpose
- **Items**: Multiple booking entries with vehicle, location, and passenger details
- **Status Tracking**: Real-time status updates for each booking
- **Financial Summary**: Total amount, discounts, and final cost
- **Scheduling**: Creation date and scheduled date for the transportation
- **Special Notes**: Additional instructions or requirements

### 3. **Summary Statistics**
- Total amount across all bookings
- Total discount applied
- Total number of bookings
- Active bookings count
- Status distribution (draft, pending, confirmed, completed, cancelled)

## Architecture

### Models

#### `BulkBookingItem`
Represents a single item within a bulk booking:
```dart
class BulkBookingItem {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final int quantity;              // Number of vehicles needed
  final double unitPrice;          // Price per vehicle
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime pickupTime;
  final int passengerCount;        // Passengers per vehicle
}
```

#### `BulkBooking`
Main bulk booking model:
```dart
class BulkBooking {
  final String id;
  final String title;
  final String description;
  final List<BulkBookingItem> items;
  final BulkBookingStatus status;  // draft, pending, confirmed, completed, cancelled
  final double totalAmount;
  final double discountAmount;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String? specialNotes;
}
```

#### `BulkBookingsResponse`
Complete API response wrapper:
```dart
class BulkBookingsResponse {
  final List<BulkBooking> bulkBookings;
  final BulkBookingPagination pagination;
  final BulkBookingSummary summary;
}
```

### State Management

The bulk bookings state is managed in `AppState`:

```dart
// State variables
BulkBookingsResponse? _bulkBookingsResponse;
bool _isLoadingBulkBookings;
String? _bulkBookingsError;
String? _bulkBookingsStatusFilter;
int _bulkBookingsPage;

// Getters
List<BulkBooking> get bulkBookings;
BulkBookingSummary? get bulkBookingsSummary;
BulkBookingPagination? get bulkBookingsPagination;

// Methods
Future<void> loadBulkBookings({String? status, int? page, int limit});
Future<void> refreshBulkBookings();
void clearBulkBookingsFilter();
```

### API Service

The `UserService` provides the API integration:

```dart
/// Get bulk bookings for corporate users
Future<BulkBookingsResponse> getBulkBookings(
  String userId, {
  String? status,
  int page = 1,
  int limit = 10,
}) async {
  // GET /api/users/:userId/bulk-bookings?status=...&page=...&limit=...
}
```

## UI Components

### `BulkBookingsCard`

A comprehensive widget that displays bulk bookings information:

**Features:**
- Header with corporate icon and title
- Status filter chips (All, Draft, Pending, Confirmed, Completed, Cancelled)
- Summary statistics cards
- List of bulk bookings with detailed information
- Pagination controls
- Loading and error states
- Empty state with helpful message

**Usage:**
```dart
// In any screen, typically Profile or Corporate Dashboard
BulkBookingsCard()
```

## Integration Guide

### Step 1: Check Corporate Status
Only corporate users can access bulk bookings:

```dart
final appState = Provider.of<AppState>(context);
if (appState.corporateInfo != null) {
  // User has corporate account
  // Show bulk bookings
}
```

### Step 2: Load Bulk Bookings

```dart
// Load all bookings
await appState.loadBulkBookings();

// Load with status filter
await appState.loadBulkBookings(status: 'confirmed');

// Load specific page
await appState.loadBulkBookings(page: 2);

// Refresh bookings
await appState.refreshBulkBookings();
```

### Step 3: Display in UI

```dart
// Option 1: Use the pre-built widget
BulkBookingsCard()

// Option 2: Build custom UI
Consumer<AppState>(
  builder: (context, appState, child) {
    if (appState.isLoadingBulkBookings) {
      return CircularProgressIndicator();
    }
    
    if (appState.bulkBookingsError != null) {
      return ErrorWidget(appState.bulkBookingsError);
    }
    
    return ListView.builder(
      itemCount: appState.bulkBookings.length,
      itemBuilder: (context, index) {
        final booking = appState.bulkBookings[index];
        return BulkBookingTile(booking: booking);
      },
    );
  },
)
```

## API Endpoint

### GET `/api/users/:id/bulk-bookings`

**Authentication:** Required (Bearer token)

**Query Parameters:**
- `status` (optional): Filter by status (draft, pending, confirmed, completed, cancelled)
- `page` (optional, default: 1): Page number for pagination
- `limit` (optional, default: 10): Number of items per page

**Response:**
```json
{
  "success": true,
  "data": {
    "bulkBookings": [
      {
        "_id": "booking123",
        "title": "Executive Team Transport - Q4 Meeting",
        "description": "Transportation for all executives",
        "items": [
          {
            "_id": "item1",
            "vehicleId": "vehicle123",
            "vehicleName": "Mercedes S-Class",
            "quantity": 3,
            "unitPrice": 850.00,
            "pickupLocation": "Head Office, Sandton",
            "dropoffLocation": "Conference Center, Midrand",
            "pickupTime": "2024-01-15T08:00:00Z",
            "passengerCount": 4
          }
        ],
        "status": "confirmed",
        "totalAmount": 2550.00,
        "discountAmount": 255.00,
        "createdAt": "2024-01-10T10:00:00Z",
        "scheduledDate": "2024-01-15T08:00:00Z",
        "specialNotes": "VIP service required"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalBookings": 25,
      "hasNextPage": true,
      "hasPrevPage": false
    },
    "summary": {
      "totalAmount": 25500.00,
      "totalDiscount": 2550.00,
      "totalBookings": 25,
      "statusCounts": {
        "draft": 2,
        "pending": 5,
        "confirmed": 10,
        "completed": 6,
        "cancelled": 2
      }
    }
  }
}
```

## Business Logic

### Status Flow
```
draft → pending → confirmed → completed
                            ↓
                        cancelled
```

1. **Draft**: Booking is being created/edited
2. **Pending**: Booking submitted, awaiting confirmation
3. **Confirmed**: Booking approved and scheduled
4. **Completed**: All trips in the booking finished
5. **Cancelled**: Booking cancelled at any stage

### Calculations

**Total Amount:**
```dart
totalAmount = sum of (item.quantity * item.unitPrice) for all items
```

**Final Amount:**
```dart
finalAmount = totalAmount - discountAmount
```

**Total Vehicles:**
```dart
totalVehicles = sum of item.quantity for all items
```

**Total Passengers:**
```dart
totalPassengers = sum of (item.quantity * item.passengerCount) for all items
```

## Use Cases

### 1. **Corporate Events**
- Conference transportation for 50+ employees
- Multiple pickup locations and times
- Coordinated arrival at event venue
- Return transportation management

### 2. **Executive Travel**
- Regular executive team meetings
- Airport transfers for business trips
- VIP service requirements
- Recurring booking templates

### 3. **Department Transportation**
- Team building events
- Off-site meetings
- Training sessions
- Client visits

### 4. **Multi-Location Coordination**
- Pick up employees from different offices
- Drop off at multiple destinations
- Complex routing requirements
- Time-sensitive schedules

## Security & Permissions

### Access Control
- Only authenticated users can access bulk bookings
- User can only view their own bulk bookings (enforced by userId parameter)
- Admin users can view all bulk bookings
- Corporate account required to create bulk bookings

### Validation
- User ID format validation (MongoDB ObjectId)
- Status values restricted to enum
- Pagination limits enforced (max 50 items per page)
- Date validation for scheduled dates

## Error Handling

### Common Errors

1. **Invalid User ID Format**
```dart
Error: "Invalid user ID format"
Solution: Ensure userId is a valid MongoDB ObjectId
```

2. **No Corporate Account**
```dart
Error: "No corporate account found for this user"
Solution: User must have a corporate account to access bulk bookings
```

3. **Access Denied**
```dart
Error: "Access denied. You can only view your own bulk bookings."
Solution: User trying to access another user's bookings
```

4. **Network Error**
```dart
Error: "Failed to load bulk bookings: Connection timeout"
Solution: Check network connectivity, retry request
```

## Testing

### Unit Tests
```dart
test('BulkBooking calculates final amount correctly', () {
  final booking = BulkBooking(
    totalAmount: 1000.0,
    discountAmount: 100.0,
    // ... other fields
  );
  
  expect(booking.finalAmount, equals(900.0));
});

test('BulkBooking calculates total vehicles correctly', () {
  final booking = BulkBooking(
    items: [
      BulkBookingItem(quantity: 2, /* ... */),
      BulkBookingItem(quantity: 3, /* ... */),
    ],
    // ... other fields
  );
  
  expect(booking.totalVehicles, equals(5));
});
```

### Integration Tests
```dart
testWidgets('BulkBookingsCard loads and displays bookings', (tester) async {
  // Setup mock data
  final mockAppState = MockAppState();
  when(mockAppState.bulkBookings).thenReturn([mockBulkBooking]);
  
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: mockAppState,
      child: MaterialApp(home: BulkBookingsCard()),
    ),
  );
  
  // Verify UI elements
  expect(find.text('Bulk Bookings'), findsOneWidget);
  expect(find.byType(BulkBookingItem), findsOneWidget);
});
```

## Future Enhancements

### Planned Features
1. **Create/Edit Bulk Bookings**
   - Form to create new bulk bookings
   - Edit existing draft bookings
   - Duplicate booking functionality

2. **Detailed View**
   - Full screen booking details
   - View all items in the booking
   - Download booking summary PDF

3. **Booking Approval Workflow**
   - Multi-level approval process
   - Approval notifications
   - Rejection with comments

4. **Analytics**
   - Cost analysis charts
   - Usage patterns
   - Department-wise breakdown

5. **Export Functionality**
   - Export to CSV/Excel
   - Generate reports
   - Email summaries

6. **Recurring Bookings**
   - Template system
   - Schedule recurring bookings
   - Auto-generation of bookings

7. **Real-time Updates**
   - WebSocket integration
   - Live status updates
   - Push notifications

## Performance Considerations

### Optimization Strategies
1. **Pagination**: Load only 10-20 bookings at a time
2. **Lazy Loading**: Load booking details on demand
3. **Caching**: Cache recent bookings locally
4. **Debouncing**: Debounce filter changes
5. **Optimistic Updates**: Update UI before API confirmation

### Best Practices
- Keep pagination limit reasonable (10-20 items)
- Use filters to reduce data load
- Implement pull-to-refresh
- Show skeleton loaders during loading
- Cache summary statistics

## Troubleshooting

### Issue: Bookings not loading
**Check:**
1. User has corporate account
2. Network connectivity
3. Authentication token is valid
4. API endpoint is accessible

### Issue: Wrong bookings displayed
**Check:**
1. Status filter is correct
2. User ID matches current user
3. Page number is valid
4. Cache is not stale

### Issue: Pagination not working
**Check:**
1. Total pages calculation
2. Current page state
3. hasNextPage/hasPrevPage flags
4. Page button event handlers

## References

- Backend API: `Swiftlyft_backend/routes/users.js` (lines 1028-1116)
- Backend Model: `Swiftlyft_backend/models/User.js` (lines 52-77)
- Frontend Model: `swiftlyft/lib/models/bulk_booking.dart`
- Frontend Service: `swiftlyft/lib/services/user_api_service.dart`
- State Management: `swiftlyft/lib/providers/app_state.dart`
- UI Widget: `swiftlyft/lib/widgets/bulk_bookings_card.dart`

## Support

For issues or questions:
1. Check this documentation
2. Review API endpoint responses
3. Check console logs for errors
4. Verify corporate account status
5. Contact development team

---

**Last Updated:** January 2024
**Version:** 1.0.0
**Status:** ✅ Implemented

