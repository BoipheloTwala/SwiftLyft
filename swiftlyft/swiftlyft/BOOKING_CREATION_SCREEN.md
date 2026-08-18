# Booking Creation Screen Documentation

## Overview
The Booking Creation Screen is a comprehensive interface that allows users to create new ride bookings directly from the app. It provides a complete end-to-end booking experience with real-time price calculation and validation.

**Location:** `lib/screens/booking_creation_screen.dart`  
**Route:** `/booking-creation`  
**Access:** Available from Home Screen via "Book Now" button and Floating Action Button

---

## Features

### ✅ Complete Booking Form
- Vehicle selection (optional pre-selection via parameters)
- Pickup and dropoff location inputs
- Date and time scheduling with pickers
- Flexible time windows (5-60 minutes)
- Passenger and luggage counters
- Service type selection
- Special features (Close Protection Officer)
- Additional notes field
- Real-time price calculation
- Price breakdown display

### ✅ User Experience
- Responsive design for mobile, tablet, and desktop
- Form validation with error messages
- Loading states during booking creation
- Success/error notifications
- Auto-navigation to home screen after booking
- Default locations pre-populated (Johannesburg → Sandton)

### ✅ Integration
- Uses updated `BookingService` aligned with backend API
- Works for both regular and corporate users
- Proper error handling and user feedback
- Debug logging for troubleshooting

---

## Navigation

### From Home Screen

#### Mobile/Tablet
1. **Floating Action Button (FAB)**
   - Located at bottom-right corner
   - Blue button with "Book Now" label
   - Direct navigation to booking creation

2. **Quick Booking Button**
   - Prominent gradient button below search box
   - "Book a Ride" with description
   - Full-width, eye-catching design

#### Desktop
1. **Hero Section Buttons**
   - Primary: "Book Now" (white button)
   - Secondary: "Browse Vehicles" (outlined button)
   - Located in main hero section

2. **Quick Booking Button**
   - Same as mobile/tablet
   - Positioned in left column

### With Vehicle Pre-selection

Navigate with vehicle details:
```dart
Navigator.pushNamed(
  context,
  AppRoutes.bookingCreation,
  arguments: {
    'vehicleId': 'abc123',
    'vehicleName': 'Mercedes-Benz S-Class',
    'vehicleType': 'luxury',
  },
);
```

### Without Pre-selection

Direct navigation (user selects vehicle later):
```dart
Navigator.pushNamed(context, AppRoutes.bookingCreation);
```

---

## Screen Sections

### 1. Vehicle Selection
**Icon:** 🚗 Car  
**Purpose:** Select or view selected vehicle

**Features:**
- Shows selected vehicle (if pre-selected)
- Vehicle name and type display
- "Change" button to browse other vehicles
- "Select Vehicle" button if none chosen
- Validates vehicle is selected before booking

### 2. Trip Details (Locations)
**Icon:** 📍 Location Pin  
**Purpose:** Enter pickup and dropoff locations

**Fields:**
- **Pickup Location**
  - Text input with validation
  - Default: "Johannesburg City Center, Gauteng"
  - Blue location icon (my_location)
  - Required field

- **Dropoff Location**
  - Text input with validation
  - Default: "Sandton, Gauteng"
  - Red location icon (location_on)
  - Required field
  - Triggers price recalculation on change

**Default Coordinates:**
- Pickup: `-26.2041, 28.0473` (JHB City Center)
- Dropoff: `-26.1076, 28.0567` (Sandton)

### 3. Schedule
**Icon:** 🕐 Clock  
**Purpose:** Set date and time for pickup

**Features:**
- **Date Picker**
  - Shows: "EEE, MMM d, yyyy" (e.g., "Mon, Jan 15, 2024")
  - Min date: Today
  - Max date: 1 year from today
  - Custom theme with primary blue color

- **Time Picker**
  - Shows: "h:mm a" (e.g., "2:30 PM")
  - Custom theme with primary blue color
  - Default: 2 hours from now

- **Flexible Time Toggle**
  - Switch to enable/disable
  - When enabled, shows slider for window (5-60 min)
  - Updates subtitle dynamically
  - Default: OFF, 15 minutes

### 4. Passengers & Luggage
**Icon:** 👥 People  
**Purpose:** Specify passenger and luggage count

**Passenger Count:**
- Min: 1
- Max: 8
- Increment/decrement buttons
- Default: 1

**Luggage Count:**
- Min: 0
- Max: 10
- Increment/decrement buttons
- Default: 0

### 5. Service Type
**Icon:** 📋 Category  
**Purpose:** Select type of transportation service

**Options:**
- **Point to Point** - Direct A to B transportation
- **Hourly Rental** - Vehicle rental by the hour
- **Airport Transfer** - Specialized airport service
- **Corporate Event** - Business event transportation

**Note:** Changing service type triggers price recalculation

### 6. Special Features
**Icon:** ⭐ Star  
**Purpose:** Add premium features to booking

**Features:**
- **Close Protection Officer**
  - Toggle switch
  - Adds R200 to service fee
  - Shows "(+R200)" in subtitle
  - Triggers price recalculation

### 7. Additional Notes
**Icon:** 📝 Note  
**Purpose:** Add special instructions or requirements

**Field:**
- Multi-line text input (3 rows)
- Optional
- Label: "Special Instructions"
- Placeholder: "Any special requirements or instructions"
- Sent to driver/operator

### 8. Price Breakdown
**Icon:** 💳 Payment  
**Purpose:** Show detailed pricing breakdown

**Items:**
- **Base Fare**: Fixed starting price (R50.00)
- **Distance**: Calculated based on locations (R15/km)
- **Time**: Estimated time cost (R120/hour)
- **Service Fee**: Base fee + CPO if selected (R5.00 + R200.00)
- **Discount**: Applied if any (shown in green with negative)
- **Taxes (15%)**: VAT calculation
- **Total**: Final amount to pay (bold, blue)

**Calculation Logic:**
```dart
// Distance fare
distance (km) × R15.00

// Time fare
(distance ÷ 60) × R120.00 per hour

// Subtotal
baseFare + distanceFare + timeFare + serviceFee

// Taxes
subtotal × 0.15 (15% VAT)

// Total
subtotal + taxes - discount
```

**Note:** Prices recalculate when:
- Dropoff location changes
- Service type changes
- Close Protection Officer toggled

---

## Booking Creation Flow

### 1. User Opens Screen
```
→ Screen initializes
→ Default locations set (JHB → Sandton)
→ Default date/time set (+2 hours)
→ Price calculated automatically
→ Form ready for input
```

### 2. User Fills Form
```
→ Select/confirm vehicle (required)
→ Enter pickup location (validated)
→ Enter dropoff location (validated)
→ Choose date & time (future only)
→ Set passenger/luggage counts
→ Select service type
→ Toggle special features
→ Add notes (optional)
→ Review price breakdown
```

### 3. User Clicks "Create Booking"
```
→ Form validation runs
→ Check vehicle selected
→ Check locations valid
→ Show loading indicator
→ Call appState.createBooking()
→ Send complete payload to backend
```

### 4. Success Response
```
→ Hide loading indicator
→ Show success SnackBar
→ Navigate to HomeScreen
→ User returns to home screen
```

### 5. Error Response
```
→ Hide loading indicator
→ Show error SnackBar
→ Display error message
→ User can retry
→ Form data preserved
```

---

## API Integration

### Backend Endpoint
**POST** `/api/bookings`

### Request Payload
```json
{
  "vehicleId": "string (required)",
  "vehicleName": "string (required)",
  "vehicleType": "sedan|suv|van|luxury (required)",
  "serviceType": "point-to-point|hourly|airport|corporate",
  "pickupLocation": {
    "address": "string",
    "coordinates": {
      "latitude": number,
      "longitude": number
    }
  },
  "dropoffLocation": {
    "address": "string",
    "coordinates": {
      "latitude": number,
      "longitude": number
    }
  },
  "pickupAddress": "string",
  "dropoffAddress": "string",
  "scheduledDate": "ISO8601 datetime",
  "pickupTime": "ISO8601 datetime",
  "passengerCount": number,
  "luggageCount": number,
  "isFlexibleTime": boolean,
  "flexibleWindow": number (minutes),
  "pricing": {
    "baseFare": number,
    "distanceFare": number,
    "timeFare": number,
    "serviceFee": number,
    "taxes": number,
    "discount": number,
    "total": number,
    "currency": "ZAR"
  },
  "basePrice": number,
  "finalPrice": number,
  "specialNotes": "string",
  "customerNotes": "string",
  "closeProtectionOfficer": boolean,
  "paymentMethod": "card"
}
```

### Success Response
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "id": "string",
    "bookingId": "string",
    "status": "pending",
    ...
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error"
}
```

---

## Validation Rules

### Required Fields
- ✅ Vehicle ID (must be selected)
- ✅ Vehicle Name
- ✅ Vehicle Type
- ✅ Pickup Location (text + coordinates)
- ✅ Dropoff Location (text + coordinates)
- ✅ Scheduled Date (must be in future)
- ✅ Passenger Count (min: 1)
- ✅ Pricing information

### Optional Fields
- Luggage Count (default: 0)
- Flexible Time (default: false)
- Flexible Window (default: 15 min)
- Special Notes
- Customer Notes
- Close Protection Officer (default: false)

### Date/Time Validation
- Scheduled date must be in the future
- Date picker: Today to +365 days
- Time picker: Any time (validated against current time)
- Combined DateTime must be > now

### Location Validation
- Pickup address: Cannot be empty
- Dropoff address: Cannot be empty
- Coordinates must be valid LatLng
- Addresses update coordinates (currently using defaults)

---

## User Types Support

### Regular Users
- ✅ Can create individual bookings
- ✅ Full access to all features
- ✅ Normal pricing applies
- ✅ Loyalty discounts may apply

### Corporate Users
- ✅ Can create individual bookings (same screen)
- ✅ Full access to all features
- ✅ Corporate pricing may apply
- ✅ Can also use Bulk Bookings screen separately
- ✅ Same API endpoint, different pricing tier

---

## Design & UI

### Theme Colors
- **Primary Action**: `SwiftLyftTheme.primaryBlue`
- **Secondary**: `SwiftLyftTheme.secondaryTeal`
- **Success**: `Colors.green`
- **Error**: `SwiftLyftTheme.errorRed`
- **Background**: `SwiftLyftTheme.pureWhite`
- **Text**: `SwiftLyftTheme.deepCharcoal`

### Card Style
- Elevation: 2
- Border radius: 16
- Padding: 16
- Section headers with icons

### Buttons
- **Create Booking**: Full-width, 56px height, primary blue
- **Date/Time**: Outlined, icon + label
- **Increment/Decrement**: Icon buttons
- **Toggle**: Switch with activeColor blue

### Spacing
- Section gap: 24px
- Internal padding: 16px
- Form fields: 16px apart
- Button height: 48-56px

---

## Error Handling

### Form Validation Errors
```dart
if (!_formKey.currentState!.validate()) {
  // Shows inline validation errors
  return;
}
```

### Location Validation
```dart
if (_pickupLocation == null || _dropoffLocation == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Please select both locations')),
  );
  return;
}
```

### Vehicle Validation
```dart
if (_selectedVehicleId == null || _selectedVehicleId!.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Please select a vehicle first')),
  );
  return;
}
```

### API Errors
```dart
try {
  final booking = await appState.createBooking(...);
  // Success handling
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to create booking: $e')),
  );
}
```

---

## Testing

### Manual Testing Steps

1. **Access Screen**
   - ✅ From Home → "Book Now" FAB
   - ✅ From Home → "Book a Ride" button
   - ✅ From Home → Desktop "Book Now" button
   - ✅ Direct navigation with vehicle params
   - ✅ Direct navigation without params

2. **Form Interaction**
   - ✅ Change pickup location
   - ✅ Change dropoff location
   - ✅ Select date (future dates only)
   - ✅ Select time
   - ✅ Toggle flexible time
   - ✅ Adjust flexible window
   - ✅ Increment/decrement passengers
   - ✅ Increment/decrement luggage
   - ✅ Change service type
   - ✅ Toggle close protection officer
   - ✅ Enter special notes

3. **Price Calculation**
   - ✅ Verify initial price
   - ✅ Change dropoff → price updates
   - ✅ Toggle CPO → fee adds R200
   - ✅ Change service type → recalculates
   - ✅ Verify all price components shown

4. **Validation**
   - ✅ Try submit without vehicle → error
   - ✅ Try submit with empty pickup → error
   - ✅ Try submit with empty dropoff → error
   - ✅ All validations show appropriate messages

5. **Booking Creation**
   - ✅ Regular user creates booking → success
   - ✅ Corporate user creates booking → success
   - ✅ Successful booking navigates to home
   - ✅ Failed booking shows error, stays on form
   - ✅ Backend receives correct payload

### Test Cases

```dart
// Test 1: Default state
- Verify form initializes with defaults
- Verify price is calculated automatically
- Verify all fields are populated correctly

// Test 2: Vehicle selection
- Pre-select vehicle via params → shows correctly
- No vehicle selected → shows "Select Vehicle"
- Change vehicle → updates display

// Test 3: Date/Time
- Cannot select past date
- Time picker works correctly
- Flexible time toggle works
- Window slider updates value

// Test 4: Price calculation
- Initial calculation correct
- Updates on location change
- Updates on service type change
- Updates on CPO toggle
- Breakdown shows all components

// Test 5: Form submission
- Valid form → creates booking
- Invalid form → shows errors
- API success → navigates away
- API error → shows error message
- Loading state displays correctly
```

---

## Future Enhancements

### Potential Improvements
1. **Google Maps Integration**
   - Interactive map for location selection
   - Route visualization
   - Real-time distance calculation
   - Address autocomplete

2. **Real-time Price Quotes**
   - Call pricing API for accurate quotes
   - Dynamic surge pricing
   - Loyalty discount application
   - Promotional code support

3. **Payment Integration**
   - Select payment method on screen
   - Save card during booking
   - Split payment options
   - Corporate billing

4. **Advanced Features**
   - Multiple waypoints support
   - Round trip booking
   - Recurring bookings
   - Favorite locations
   - Recent locations

5. **Enhanced Validation**
   - Address geocoding
   - Distance limits
   - Time slot availability
   - Vehicle capacity checking

---

## Troubleshooting

### Issue: Booking creation fails
**Solution:**
1. Check backend is running
2. Verify authentication token is valid
3. Check console for API errors
4. Verify all required fields populated
5. Check backend logs for detailed error

### Issue: Price not calculating
**Solution:**
1. Verify `_calculatePrice()` is called
2. Check pickup/dropoff locations are set
3. Verify distance calculation logic
4. Check for null values in pricing fields

### Issue: Navigation doesn't work
**Solution:**
1. Verify route is defined in `routes.dart`
2. Check route name spelling
3. Verify screen is imported
4. Check for navigation context issues

### Issue: Form validation not working
**Solution:**
1. Verify `_formKey` is set on Form widget
2. Check validators are defined on TextFormFields
3. Call `_formKey.currentState!.validate()`
4. Check validator return values (null = valid)

---

## Related Documentation

- **Backend API**: See `BOOKING_API_ALIGNMENT.md`
- **Booking Service**: See `lib/services/booking_api_service.dart`
- **App State**: See `lib/providers/app_state.dart`
- **Routes**: See `lib/utils/routes.dart`
- **Theme**: See `lib/utils/theme.dart`
- **Bulk Bookings**: See `BULK_BOOKINGS.md` (corporate users)

---

**Last Updated:** November 2024  
**Status:** ✅ Ready for Testing  
**Works For:** Both Regular and Corporate Users  
**Platform Support:** Mobile, Tablet, Desktop (Web)

