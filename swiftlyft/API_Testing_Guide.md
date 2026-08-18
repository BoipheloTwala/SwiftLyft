# SwiftLyft API Testing Guide

## Overview
This guide provides comprehensive testing instructions for the SwiftLyft API using the updated Postman collection and environment files.

## Files Included
- `SwiftLyft_API_Tests_Updated.postman_collection.json` - Complete API test collection
- `SwiftLyft_Environment_Updated.postman_environment.json` - Environment variables
- `API_Testing_Guide.md` - This documentation

## Setup Instructions

### 1. Import Files into Postman
1. Open Postman
2. Click "Import" button
3. Import both JSON files:
   - `SwiftLyft_API_Tests_Updated.postman_collection.json`
   - `SwiftLyft_Environment_Updated.postman_environment.json`

### 2. Configure Environment
1. Select the "SwiftLyft Environment - Comprehensive" environment
2. Verify the `baseUrl` is set to your API server (default: `http://localhost:3000`)
3. Update test data variables if needed (emails, phone numbers, etc.)

### 3. Start Your Backend Server
Ensure your SwiftLyft backend is running on the configured port.

## Test Collection Structure

### 1. Health Check
- **API Health Check** - Tests basic server connectivity
- **API Root Endpoint** - Tests root endpoint response

### 2. Authentication
- **User Registration** - Creates new user account
- **User Login** - Authenticates user and saves tokens
- **Get Current User** - Retrieves authenticated user profile
- **Refresh Token** - Renews access token
- **Forgot Password** - Initiates password reset
- **Logout** - Invalidates refresh token

### 3. Users
- **Get User Profile** - Retrieves user profile
- **Update User Profile** - Updates user information
- **Get User Addresses** - Lists saved addresses
- **Add User Address** - Adds new saved address
- **Get User Loyalty Info** - Retrieves loyalty program data
- **Get User Stats** - Gets user statistics
- **Get User Quotes** - Lists user's quotes
- **Get User Notifications** - Lists user notifications

### 4. Quotes
- **Create Quote Request** - Creates new ride quote
- **Get Quote Details** - Retrieves specific quote
- **Get User Quotes** - Lists user's quotes
- **Get Price Estimate** - Gets price estimate without creating quote

### 5. Bookings
- **Create Booking** - Creates new ride booking
- **Get Booking Details** - Retrieves specific booking
- **Update Booking** - Updates booking information
- **Get User Bookings** - Lists user's bookings
- **Cancel Booking** - Cancels existing booking
- **Rate Trip** - Submits trip rating and review

### 6. Drivers
- **Register Driver** - Registers new driver account
- **Get Driver Details** - Retrieves driver information
- **Update Driver Availability** - Updates driver status
- **Update Driver Location** - Updates driver location
- **Get Driver Performance** - Gets driver performance metrics
- **Get Driver Bookings** - Lists driver's bookings

### 7. Vehicles
- **Get Available Vehicles** - Lists vehicles by location
- **Get Vehicle Categories** - Lists vehicle categories
- **Search Vehicles** - Searches vehicles with criteria
- **Create Vehicle** - Adds new vehicle
- **Get Vehicle Details** - Retrieves vehicle information
- **Check Vehicle Availability** - Checks vehicle status
- **Update Vehicle Status** - Updates vehicle availability

### 8. Payments
- **Add Payment Method** - Adds new payment method
- **Get Payment Methods** - Lists user's payment methods
- **Process Payment** - Processes payment transaction
- **Get Payment History** - Lists payment history
- **Check Payment Status** - Checks payment status
- **Process Refund** - Processes refund

### 9. Location Services
- **Geocode Address** - Converts address to coordinates
- **Reverse Geocode** - Converts coordinates to address
- **Calculate Route** - Calculates route between points
- **Search Places** - Searches for places
- **Find Nearby Places** - Finds places near location
- **Check Service Area** - Checks if location is in service area
- **Get Service Areas** - Lists all service areas
- **Validate Location** - Validates location data

### 10. Notifications
- **Get User Notifications** - Lists user notifications
- **Mark Notification as Read** - Marks notification as read
- **Create Notification** - Creates new notification
- **Get Notification Settings** - Gets notification preferences
- **Update Notification Settings** - Updates notification preferences

### 11. Support
- **Create Support Ticket** - Creates new support ticket
- **Get Support Tickets** - Lists support tickets
- **Get Support Ticket Details** - Gets specific ticket
- **Update Support Ticket** - Updates ticket status
- **Add Support Message** - Adds message to ticket

### 12. Special Features
- **Get Special Features** - Lists available special features
- **Get Feature Details** - Gets specific feature details
- **Request Special Feature** - Requests special feature for booking
- **Get Feature Pricing** - Gets pricing for special features

### 13. Analytics
- **Get User Analytics** - Gets user analytics data
- **Get Driver Analytics** - Gets driver analytics data
- **Get Vehicle Analytics** - Gets vehicle analytics data
- **Get Booking Analytics** - Gets booking analytics data
- **Get Revenue Analytics** - Gets revenue analytics data

### 14. Error Handling Tests
- **Invalid Endpoint** - Tests 404 error handling
- **Unauthorized Access** - Tests 401 error handling
- **Invalid Registration Data** - Tests validation errors
- **Invalid Booking Data** - Tests booking validation
- **Invalid Payment Data** - Tests payment validation

## Test Execution Order

### Recommended Test Sequence:
1. **Health Check** - Verify server is running
2. **Authentication** - Register and login user
3. **Users** - Test user profile operations
4. **Quotes** - Create and manage quotes
5. **Bookings** - Create and manage bookings
6. **Payments** - Test payment operations
7. **Location Services** - Test location features
8. **Other Features** - Test remaining endpoints

### Driver Testing Sequence:
1. **Authentication** - Register driver account
2. **Drivers** - Complete driver registration
3. **Vehicles** - Add and manage vehicles
4. **Driver Operations** - Test driver-specific features

## Environment Variables

### Core Variables:
- `baseUrl` - API server URL
- `accessToken` - JWT access token (auto-populated)
- `refreshToken` - JWT refresh token (auto-populated)
- `userId` - Current user ID (auto-populated)

### Test Data Variables:
- `testEmail` - Test user email
- `testPassword` - Test user password
- `testPhone` - Test phone number
- `testLatitude`/`testLongitude` - Test coordinates
- `testAddress` - Test address

### ID Variables (Auto-populated):
- `bookingId` - Booking ID from created bookings
- `quoteId` - Quote ID from created quotes
- `driverId` - Driver ID from driver registration
- `vehicleId` - Vehicle ID from created vehicles
- `paymentMethodId` - Payment method ID
- `paymentId` - Payment transaction ID

## Test Data Management

### User Test Data:
- Email: `testuser@example.com`
- Password: `TestPassword123`
- Phone: `+27123456789`

### Driver Test Data:
- Email: `driver@example.com`
- Password: `DriverPassword123`
- License: `DL123456789`

### Location Test Data:
- Pickup: Johannesburg (-26.2041, 28.0473)
- Dropoff: Sandton (-26.1076, 28.0567)

### Payment Test Data:
- Card: `4111111111111111` (Visa test card)
- Expiry: 12/2025
- Amount: R150.00

## Troubleshooting

### Common Issues:
1. **401 Unauthorized** - Check if access token is valid
2. **404 Not Found** - Verify endpoint URL and server running
3. **400 Bad Request** - Check request body format and required fields
4. **500 Server Error** - Check server logs for detailed error

### Token Management:
- Tokens are automatically saved and used by the collection
- If tokens expire, run the "Refresh Token" request
- For new sessions, start with "User Login" to get fresh tokens

### Data Cleanup:
- Test data persists between runs
- Use different email addresses for multiple test runs
- Consider database cleanup for production testing

## API Response Format

All API responses follow this format:
```json
{
  "success": true/false,
  "message": "Response message",
  "data": { /* Response data */ },
  "pagination": { /* Pagination info if applicable */ }
}
```

## Security Notes

- Test data uses safe, non-sensitive values
- Real payment processing is not performed in test mode
- All sensitive data is properly masked in responses
- Authentication tokens are handled securely

## Support

For issues with the API or test collection:
1. Check server logs for detailed error messages
2. Verify all required environment variables are set
3. Ensure database is properly seeded with test data
4. Check network connectivity and server status
