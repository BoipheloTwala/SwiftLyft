# SwiftLyft Backend API Tests

This directory contains comprehensive test suites for the SwiftLyft backend APIs (6-11) as specified in the "Core API Requirements for SwiftLyft" document.

## Test Structure

```
tests/
├── setup.js                 # Test environment setup and utilities
├── testUtils.js             # Shared test utilities and helpers
├── quotes.test.js           # Quote Request APIs (API 6) tests
├── drivers.test.js          # Driver Management APIs (API 7) tests
├── notifications.test.js    # Notification APIs (API 8) tests
├── analytics.test.js        # Analytics APIs (API 9) tests
├── support.test.js          # Support APIs (API 10) tests
├── special-features.test.js # Special Features APIs (API 11) tests
├── integration.test.js      # End-to-end integration tests
└── README.md               # This file
```

## Test Coverage

### API 6: Quote Request APIs ✅
- **POST /api/quotes** - Create quote with validation
- **GET /api/quotes/:id** - Retrieve quote details
- **PUT /api/quotes/:id** - Update quote status
- **GET /api/users/:userId/quotes** - Get user quote history
- **POST /api/quotes/estimate** - Price estimation
- **DELETE /api/quotes/:id** - Admin quote deletion

### API 7: Driver Management APIs ✅
- **POST /api/drivers** - Driver registration/onboarding
- **GET /api/drivers/:id** - Get driver profile
- **PUT /api/drivers/:id/availability** - Update availability
- **PUT /api/drivers/:id/location** - Update location
- **GET /api/drivers/:id/assignments** - Current assignments
- **GET /api/drivers/:id/performance** - Performance metrics
- **GET /api/drivers/available** - Find available drivers
- **PUT /api/drivers/:id/status** - Admin status updates

### API 8: Notification & Communication APIs ✅
- **POST /api/notifications/send** - Send notifications
- **GET /api/users/:userId/notifications** - Get notifications
- **PUT /api/users/:userId/notifications/:id/read** - Mark as read
- **POST /api/users/:userId/notifications/mark-all-read** - Bulk read
- **GET /api/users/:userId/notification-settings** - Get settings
- **PUT /api/users/:userId/notification-settings** - Update settings
- **POST /api/users/:userId/fcm-token** - Register FCM token
- **POST /api/notifications/sms** - Send SMS
- **DELETE /api/users/:userId/notifications/:id** - Delete notification

### API 9: Analytics & Reporting APIs ✅
- **GET /api/analytics/users/:userId** - User behavior analytics
- **GET /api/analytics/bookings** - Booking performance metrics
- **GET /api/analytics/revenue** - Revenue and financial reporting
- **GET /api/analytics/drivers** - Driver performance metrics
- **POST /api/analytics/events** - Track user interactions
- **GET /api/analytics/dashboard** - Dashboard overview

### API 10: Support & Help APIs ✅
- **POST /api/support/tickets** - Create support tickets
- **GET /api/users/:userId/support-tickets** - Get user tickets
- **GET /api/support/tickets/:id** - Get ticket details
- **POST /api/support/tickets/:id/messages** - Add messages
- **PUT /api/support/tickets/:id/status** - Update status
- **POST /api/support/tickets/:id/resolve** - Resolve tickets
- **GET /api/support/faq** - FAQ search
- **POST /api/support/faq/:id/helpful** - Mark FAQ helpful
- **GET /api/support/contact** - Contact information

### API 11: Special Features APIs ✅
- **GET /api/offers** - Available promotional offers
- **POST /api/offers/validate** - Validate promo codes
- **POST /api/corporate/bookings** - Corporate bulk bookings
- **GET /api/users/:userId/corporate/bookings** - Get corporate bookings
- **POST /api/bookings/security** - Security service requests
- **GET /api/services/airport** - Airport services info
- **POST /api/bookings/airport** - Airport transfer bookings

## Integration Tests ✅
- **Complete user journey** - Registration to booking flow
- **Driver onboarding flow** - Registration to active driver status
- **Support ticket lifecycle** - Creation to resolution
- **Notification system** - Settings to delivery
- **Analytics tracking** - Event tracking to reporting
- **Corporate features** - Booking creation to approval
- **Quote to booking flow** - Estimation to quote acceptance
- **Error handling** - Authentication, validation, and edge cases
- **Performance simulation** - Concurrent operations and load testing

## Running Tests

### Prerequisites
```bash
npm install
```

### Run All Tests
```bash
npm test
```

### Run Specific Test Suite
```bash
# Run only quote tests
npm test quotes.test.js

# Run only integration tests
npm test integration.test.js
```

### Run Tests with Coverage
```bash
npm run test:coverage
```

### Run Tests in Watch Mode
```bash
npm run test:watch
```

## Test Environment

The tests use:
- **MongoDB Memory Server** - In-memory database for isolated testing
- **Supertest** - HTTP endpoint testing
- **Jest** - Test framework with custom matchers
- **Mock services** - Email, SMS, and push notification mocks

## Test Utilities

### Setup Functions
- `createTestUser()` - Create test user with default data
- `createTestDriver()` - Create test driver profile
- `createTestQuote()` - Create test quote request
- `createTestOffer()` - Create test promotional offer

### Request Helpers
- `authenticatedRequest()` - Create authenticated request
- `adminRequest()` - Create admin-level request
- `expectSuccess()` - Assert successful response
- `expectError()` - Assert error response

### Validation Helpers
- `validateQuoteResponse()` - Validate quote object structure
- `validateDriverResponse()` - Validate driver object structure
- `validateNotificationResponse()` - Validate notification structure

## Key Testing Features

### Authentication & Authorization
- JWT token validation
- Role-based access control
- Admin-only endpoints
- User permission checks

### Data Validation
- Input validation for all endpoints
- Business rule enforcement
- Error message verification
- Edge case handling

### Business Logic
- Pricing calculations
- Status transitions
- Permission checks
- Data relationships

### Integration Flows
- End-to-end user journeys
- Cross-service interactions
- Error recovery scenarios
- Performance under load

### Mock Services
- Email delivery simulation
- SMS sending mocks
- Push notification stubs
- External API integrations

## Test Data

Default test data includes:
- **Users**: Regular users, corporate users, admin users
- **Drivers**: Complete driver profiles with vehicles and documents
- **Quotes**: Various quote scenarios with different vehicle/service types
- **Offers**: Promotional codes, discounts, and conditions
- **Locations**: Johannesburg and Pretoria coordinates
- **Dates**: Past, present, and future timestamps

## Coverage Goals

- **Branches**: 70% minimum
- **Functions**: 75% minimum
- **Lines**: 80% minimum
- **Statements**: 80% minimum

## Continuous Integration

Tests are designed to run in CI/CD pipelines with:
- Isolated test environments
- Fast execution times
- Comprehensive error reporting
- Coverage reporting integration

## Contributing

When adding new tests:
1. Follow existing naming conventions
2. Use descriptive test names
3. Include both positive and negative test cases
4. Add appropriate mocks for external dependencies
5. Update this README for new test suites

## Troubleshooting

### Common Issues
- **Database connection errors**: Ensure MongoDB Memory Server is available
- **Timeout errors**: Increase Jest timeout in `jest.config.js`
- **Mock failures**: Check mock implementations in test files
- **Import errors**: Verify file paths and module exports

### Debug Mode
```bash
DEBUG=test npm test
```

This comprehensive test suite ensures the reliability, security, and functionality of all SwiftLyft APIs 6-11, providing confidence in the production deployment of the ride-hailing platform.
