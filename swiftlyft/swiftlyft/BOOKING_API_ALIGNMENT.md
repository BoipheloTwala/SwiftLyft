# Booking API Alignment Documentation

## Overview
This document describes the alignment between the SwiftLyft frontend booking service and the backend `/api/bookings` endpoints. The booking system works seamlessly for **both regular and corporate users**.

## ✅ Updated: November 2024
## 🔧 Fixed: Coordinate field transformation (latitude/longitude → lat/lng)

---

## Backend Endpoints (`/api/bookings`)

### ⚠️ Important Note: Coordinate Format
The backend expects coordinates in `lat`/`lng` format, but the frontend uses `latitude`/`longitude`. The `BookingService` automatically transforms coordinates to match the backend format.

### 1. Create Booking
**POST** `/api/bookings`

Creates a new booking for any authenticated user (regular or corporate).

**Request Body:**
```json
{
  "vehicleId": "string (required)",
  "vehicleName": "string (required)",
  "vehicleType": "sedan|suv|van|luxury (required)",
  "serviceType": "string (required)",
  "pickupLocation": {
    "address": "string (required)",
    "coordinates": {
      "latitude": "number (required)",
      "longitude": "number (required)"
    }
  },
  "dropoffLocation": {
    "address": "string (required)",
    "coordinates": {
      "latitude": "number (required)",
      "longitude": "number (required)"
    }
  },
  "pickupAddress": "string (optional)",
  "dropoffAddress": "string (optional)",
  "waypoints": "array (optional)",
  "scheduledDate": "ISO8601 datetime (required)",
  "pickupTime": "ISO8601 datetime (optional)",
  "passengerCount": "number (required)",
  "luggageCount": "number (optional)",
  "isFlexibleTime": "boolean (optional)",
  "flexibleWindow": "number (minutes, optional)",
  "pricing": {
    "baseFare": "number (required)",
    "distanceFare": "number (required)",
    "timeFare": "number (required)",
    "serviceFee": "number (optional)",
    "taxes": "number (required)",
    "discount": "number (optional)",
    "loyaltyDiscount": "number (optional)",
    "surgeMultiplier": "number (optional)",
    "total": "number (required)"
  },
  "specialNotes": "string (optional)",
  "closeProtectionOfficer": "boolean (optional)",
  "customerNotes": "string (optional)",
  "paymentMethod": "string (optional)",
  "emergencyContact": "object (optional)",
  "quoteId": "string (optional)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "id": "string",
    "bookingId": "string",
    "userId": "string",
    "vehicleId": "string",
    "vehicleName": "string",
    "status": "pending|confirmed|driverAssigned|...",
    "paymentStatus": "pending|completed|failed",
    "pickupAddress": "string",
    "dropoffAddress": "string",
    "pickupLocation": {"latitude": number, "longitude": number},
    "dropoffLocation": {"latitude": number, "longitude": number},
    "pickupTime": "ISO8601 datetime",
    "passengerCount": number,
    "basePrice": number,
    "finalPrice": number,
    "specialNotes": "string",
    "closeProtectionOfficer": boolean,
    "createdAt": "ISO8601 datetime",
    "updatedAt": "ISO8601 datetime"
  }
}
```

**Frontend Usage:**
```dart
final booking = await appState.createBooking(
  vehicleId: 'abc123',
  vehicleName: 'Mercedes-Benz S-Class',
  vehicleType: 'luxury',
  serviceType: 'point-to-point',
  pickupLocation: {
    'address': '123 Main St, Johannesburg',
    'coordinates': {'latitude': -26.2041, 'longitude': 28.0473}
  },
  dropoffLocation: {
    'address': '456 Park Ave, Sandton',
    'coordinates': {'latitude': -26.1076, 'longitude': 28.0567}
  },
  scheduledDate: DateTime.now().add(Duration(hours: 2)),
  passengerCount: 2,
  pricing: {
    'baseFare': 50.0,
    'distanceFare': 25.0,
    'timeFare': 10.0,
    'serviceFee': 5.0,
    'taxes': 10.0,
    'total': 100.0
  },
);
```

---

### 2. Get Booking by ID
**GET** `/api/bookings/{id}`

Retrieves a specific booking. Only the booking owner or admin can access.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "string",
    "bookingId": "string",
    ...
  }
}
```

**Frontend Usage:**
```dart
final booking = await appState.getBookingById('booking-id');
```

---

### 3. Update Booking
**PUT** `/api/bookings/{id}`

Updates specific fields of a booking. Only the booking owner can update.

**Allowed Fields:**
- `specialNotes`
- `customerNotes`
- `paymentMethod`
- `emergencyContact`
- `closeProtectionOfficer`

**Request Body:**
```json
{
  "specialNotes": "Please call when you arrive",
  "closeProtectionOfficer": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Booking updated successfully",
  "data": {...}
}
```

**Frontend Usage:**
```dart
final updatedBooking = await bookingService.updateBooking(
  'booking-id',
  {
    'specialNotes': 'Updated notes',
    'closeProtectionOfficer': true,
  },
);
```

---

### 4. Cancel Booking
**DELETE** `/api/bookings/{id}`

Cancels a booking with automatic cancellation fee calculation based on timing.

**Cancellation Fee Logic:**
- Less than 2 hours before trip: 50% of total price
- Less than 24 hours before trip: 25% of total price
- More than 24 hours before trip: No fee

**Request Body:**
```json
{
  "reason": "Change of plans" // optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Booking cancelled successfully",
  "data": {
    "bookingId": "string",
    "cancellationFee": number,
    "cancelledAt": "ISO8601 datetime"
  }
}
```

**Frontend Usage:**
```dart
final result = await appState.cancelBooking('booking-id');
// Returns Map with bookingId, cancellationFee, and cancelledAt
```

---

### 5. Update Booking Status
**PUT** `/api/bookings/{id}/status`

Updates the booking status with tracking.

**Request Body:**
```json
{
  "status": "confirmed|cancelled|completed|...",
  "notes": "string (optional)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Booking status updated successfully",
  "data": {...}
}
```

**Frontend Usage:**
```dart
final updatedBooking = await bookingService.updateBookingStatus(
  'booking-id',
  'completed',
  notes: 'Trip completed successfully',
);
```

---

### 6. Rate Booking
**POST** `/api/bookings/{id}/rating`

Submits rating and review for a completed booking. Also awards loyalty points to the user.

**Request Body:**
```json
{
  "rating": 4.5, // required, 1-5
  "review": "Great driver, smooth ride!", // optional
  "categories": { // optional
    "punctuality": 5.0,
    "cleanliness": 4.5,
    "driving": 5.0
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Rating submitted successfully",
  "data": {...}
}
```

**Frontend Usage:**
```dart
final success = await appState.rateDriver(
  'driver-id',
  bookingId: 'booking-id',
  rating: 4.5,
  review: 'Excellent service!',
  criteria: {
    'punctuality': 5.0,
    'cleanliness': 4.5,
  },
);
```

---

### 7. Assign Driver
**POST** `/api/bookings/{id}/assign-driver`

Assigns an available driver to a booking. Typically used by admin/system.

**Request Body:**
```json
{
  "driverId": "string"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Driver assigned successfully",
  "data": {...}
}
```

**Frontend Usage:**
```dart
final success = await appState.assignDriver('booking-id', 'driver-id');
```

---

## User Booking Endpoints (via UserService)

User bookings are fetched via the UserService, which calls:

**GET** `/api/users/{userId}/bookings`

Query Parameters:
- `status`: Filter by status (optional)
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20)

**Frontend Usage:**
```dart
// In BookingState:
await _userService.getUserBookings(); // Fetches current user's bookings
```

---

## Frontend Service Structure

### BookingService (`lib/services/booking_api_service.dart`)

Methods:
- ✅ `createBooking()` - Creates booking (all users)
- ✅ `getBooking()` - Get booking by ID
- ✅ `updateBooking()` - Update allowed fields
- ✅ `cancelBooking()` - Cancel with fee calculation
- ✅ `updateBookingStatus()` - Update status with tracking
- ✅ `rateBooking()` - Submit rating/review
- ✅ `assignDriver()` - Assign driver (admin)

### BookingState (`lib/providers/booking_state.dart`)

Methods:
- ✅ `loadBookings()` - Loads user bookings via UserService
- ✅ `getBookingById()` - Get specific booking
- ✅ `createBooking()` - Create new booking
- ✅ `cancelBooking()` - Cancel booking
- ✅ `rateDriver()` - Rate driver/booking

### AppState (`lib/providers/app_state.dart`)

Exposes booking methods through centralized state management.

---

## Corporate vs Regular Users

### Key Points:

1. **All booking endpoints work for BOTH user types**
   - Regular users: Create individual bookings
   - Corporate users: Can create individual bookings AND bulk bookings

2. **Authentication & Authorization**
   - All endpoints require authentication (`authenticateToken` middleware)
   - Users can only access their own bookings (checked via `userId`)
   - Admin users can access all bookings

3. **Bulk Bookings**
   - Corporate users have additional endpoints via `/api/users/{userId}/bulk-bookings`
   - Regular bookings and bulk bookings are separate systems
   - See `BULK_BOOKINGS.md` for bulk booking documentation

4. **Pricing & Payment**
   - Corporate users may have different pricing tiers
   - Loyalty discounts apply to both user types
   - Payment processing is the same for all users

---

## Data Flow

```
User Action (UI)
    ↓
AppState.createBooking()
    ↓
BookingState.createBooking()
    ↓
BookingService.createBooking()
    ↓
HTTP POST /api/bookings
    ↓
Backend validates & creates booking
    ↓
Response with booking data
    ↓
BookingState updates local cache
    ↓
UI updates with new booking
```

---

## Error Handling

All booking methods include proper error handling:

```dart
try {
  final booking = await appState.createBooking(...);
  // Success
} catch (e) {
  // Handle error
  if (e is ApiException) {
    if (e.statusCode == 400) {
      // Validation error
    } else if (e.statusCode == 403) {
      // Permission denied
    }
  }
}
```

Common error codes:
- `400`: Validation error (missing/invalid fields)
- `401`: Not authenticated
- `403`: Permission denied (not booking owner)
- `404`: Booking not found
- `500`: Server error

---

## Testing

### Manual Testing Steps:

1. **Create Booking (Regular User)**
   ```dart
   // Login as regular user
   // Navigate to vehicle selection
   // Select vehicle and create booking
   // Verify booking appears in My Bookings
   ```

2. **Create Booking (Corporate User)**
   ```dart
   // Login as corporate user
   // Navigate to vehicle selection
   // Select vehicle and create booking
   // Verify booking appears in My Bookings
   // Verify separate bulk bookings are unaffected
   ```

3. **Cancel Booking**
   ```dart
   // Open booking details
   // Click cancel
   // Verify cancellation fee is displayed
   // Confirm cancellation
   // Verify booking status updates to 'cancelled'
   ```

4. **Rate Booking**
   ```dart
   // Complete a trip
   // Open completed booking
   // Submit rating and review
   // Verify loyalty points are awarded
   ```

---

## Migration Notes

### Changes from Previous Version:

1. **createBooking() signature updated**
   - Added required: `vehicleType`, `pricing` (Map)
   - Removed: direct `basePrice`, `finalPrice` (now in pricing map)
   - Added optional: `pickupAddress`, `dropoffAddress`, `waypoints`, etc.

2. **cancelBooking() return type changed**
   - Previously returned `Booking`
   - Now returns `Map<String, dynamic>` with cancellation details

3. **rateBooking() method added**
   - Replaces previous rating logic
   - Awards loyalty points automatically
   - Updates driver performance metrics

4. **Removed deprecated methods**
   - `getUserBookings()` - Use `UserService.getUserBookings()` instead
   - `getBookingHistory()` - Use `UserService.getUserBookings()` with filter
   - `getActiveBookings()` - Use `UserService.getUserBookings()` with status filter

---

## Backend Alignment Checklist

✅ POST /api/bookings - Create booking
✅ GET /api/bookings/{id} - Get booking
✅ PUT /api/bookings/{id} - Update booking
✅ DELETE /api/bookings/{id} - Cancel booking
✅ PUT /api/bookings/{id}/status - Update status
✅ POST /api/bookings/{id}/rating - Rate booking
✅ POST /api/bookings/{id}/assign-driver - Assign driver
✅ Works for regular users
✅ Works for corporate users
✅ Proper error handling
✅ Debug logging
✅ Documentation complete

---

## Support

For issues or questions:
- Check backend logs for API errors
- Check frontend debug logs (debug mode)
- Verify authentication token is valid
- Confirm user has proper permissions
- Review `COMPREHENSIVE_DOCUMENTATION.md` for backend details
- Review `BULK_BOOKINGS.md` for corporate bulk booking features

---

**Last Updated:** November 2024
**Status:** ✅ Production Ready
**Compatibility:** Frontend v1.0+ | Backend v1.0+

