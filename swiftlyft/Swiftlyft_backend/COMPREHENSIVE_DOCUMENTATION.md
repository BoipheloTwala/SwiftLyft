# SwiftLyft Backend - Comprehensive Documentation

## 📋 Table of Contents
1. [Overview](#overview)
2. [Quick Start Guide](#quick-start-guide)
3. [API Documentation](#api-documentation)
4. [Database Schema](#database-schema)
5. [Security & Authentication](#security--authentication)
6. [Location & Mapping System](#location--mapping-system)
7. [Payment System](#payment-system)
8. [User Management](#user-management)
9. [Development & Deployment](#development--deployment)
10. [Testing](#testing)
11. [Troubleshooting](#troubleshooting)

---

## 🚀 Overview

The SwiftLyft API is a comprehensive ride-sharing and logistics platform backend built with Node.js, Express, and MongoDB. This system provides a complete solution for managing users, vehicles, bookings, payments, and location services.

### Key Features
- **User Management**: Registration, authentication, profiles, loyalty programs
- **Vehicle Management**: Vehicle registration, availability tracking, driver management
- **Booking System**: Trip booking, real-time tracking, status management
- **Payment Processing**: Multiple payment methods, transaction tracking
- **Location Services**: Geospatial queries, route calculation, service areas
- **Analytics**: Comprehensive reporting and statistics
- **Security**: JWT authentication, input validation, rate limiting

### Technology Stack
- **Backend**: Node.js, Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens)
- **Security**: Helmet, CORS, Rate Limiting
- **Documentation**: Swagger/OpenAPI
- **Testing**: Jest, Supertest
- **Email**: Nodemailer

---

## 🚀 Quick Start Guide

### Prerequisites
- Node.js 16+
- MongoDB 4.4+
- npm or yarn

### 1. Installation
```bash
# Clone the repository
git clone <repository-url>
cd Swiftlyft_backend

# Install dependencies
npm install
```

### 2. Environment Setup
Create a `.env` file in the root directory:
```env
# Server Configuration
NODE_ENV=development
PORT=3000

# Database
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/swiftlyft-auth

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here-make-it-long-and-random-at-least-32-characters
JWT_EXPIRE=24h
JWT_REFRESH_SECRET=your-super-secret-refresh-jwt-key-here-make-it-long-and-random-at-least-32-characters
JWT_REFRESH_EXPIRE=7d

# Security
BCRYPT_SALT_ROUNDS=12

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@example.com
SMTP_PASS=your-app-password-here
FROM_EMAIL=noreply@swiftlyft.co.za
```

### 3. Database Setup
```bash
# Setup database with indexes
npm run db:setup

# Create database indexes for performance
npm run db:indexes

# Seed database with sample data
npm run db:seed

# Validate database setup
npm run db:validate
```

### 4. Start the Server
```bash
# Development mode
npm run dev

# Production mode
npm start
```

### 5. Access the API
- **API Base URL**: `http://localhost:3000/api`
- **API Documentation**: `http://localhost:3000/api-docs`
- **Health Check**: `http://localhost:3000/api/health`

---

## 📚 API Documentation

### Authentication
The SwiftLyft API uses JWT (JSON Web Tokens) for authentication with two types of tokens:
- **Access Token**: Short-lived (24h) for API requests
- **Refresh Token**: Long-lived (7d) for refreshing access tokens

#### Authentication Endpoints (`/api/auth`)
- `POST /register` - Register a new user
- `POST /login` - Login user
- `POST /refresh-token` - Refresh access token
- `POST /logout` - Logout user
- `POST /forgot-password` - Send password reset email
- `POST /reset-password/:token` - Reset password
- `GET /me` - Get current user information
- `POST /verify-email/:token` - Verify email address
- `POST /send-phone-verification` - Send phone verification code

#### User Management Endpoints (`/api/users`)
- `GET /:id` - Get user profile
- `PUT /:id` - Update user profile
- `GET /:id/loyalty` - Get loyalty program data
- `GET /:id/rewards` - Get available and earned rewards
- `GET /:id/referrals` - Get referral tracking data
- `GET /:id/corporate` - Get corporate account details
- `GET /:id/bulk-bookings` - Get corporate bulk bookings

#### Vehicle Management Endpoints (`/api/vehicles`)
- `GET /available` - List available vehicles by location
- `GET /categories` - Get vehicle type categories
- `GET /search` - Search vehicles by criteria
- `GET /:id` - Get detailed vehicle information
- `GET /:id/availability` - Check real-time availability
- `POST /` - Create a new vehicle
- `PUT /:id` - Update vehicle information
- `PUT /:id/status` - Update vehicle status

#### Booking Management Endpoints (`/api/bookings`)
- `POST /` - Create a new booking
- `GET /` - Get user bookings
- `GET /:id` - Get booking details
- `PUT /:id` - Update booking
- `PUT /:id/status` - Update booking status
- `POST /:id/cancel` - Cancel booking
- `POST /:id/rate` - Rate a completed trip

#### Payment Endpoints (`/api/payments`)
- `GET /methods` - Get user payment methods
- `POST /methods` - Add payment method
- `PUT /methods/:id` - Update payment method
- `DELETE /methods/:id` - Remove payment method
- `POST /process` - Process payment
- `GET /history` - Get payment history

#### Location Services (`/api/location`)
- `POST /geocode` - Convert address to coordinates
- `POST /reverse-geocode` - Convert coordinates to address
- `POST /route` - Calculate route between points
- `GET /service-areas` - Get available service areas
- `GET /nearby` - Find nearby locations

### API Response Format
All API responses follow a consistent format:
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { /* response data */ },
  "errors": [ /* validation errors if any */ ]
}
```

---

## 🗄️ Database Schema

### Core Collections

#### Users Collection
```javascript
{
  _id: ObjectId,
  email: String (unique, required),
  password: String (hashed),
  name: String,
  phoneNumber: String,
  role: String (enum: ['user', 'admin']),
  loyaltyTier: String (enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond']),
  loyaltyPoints: Number,
  savedAddresses: [{
    label: String,
    address: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    },
    isDefault: Boolean
  }],
  corporateAccount: {
    companyName: String,
    companyEmail: String,
    discountPercentage: Number,
    monthlyBudget: Number
  },
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

#### Vehicles Collection
```javascript
{
  _id: ObjectId,
  vehicleId: String (unique),
  driverId: ObjectId (ref: 'Driver'),
  name: String,
  make: String,
  model: String,
  year: Number,
  category: String (enum: ['sedan', 'suv', 'luxury', 'van', 'truck']),
  passengerCapacity: Number,
  currentLocation: {
    address: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    },
    city: String,
    province: String
  },
  pricing: {
    baseFare: Number,
    perKmRate: Number,
    perMinuteRate: Number,
    minimumFare: Number,
    currency: String
  },
  status: String (enum: ['available', 'busy', 'offline', 'maintenance']),
  availability: {
    isAvailable: Boolean,
    availableFrom: Date,
    availableUntil: Date
  },
  features: [String],
  performance: {
    rating: Number,
    totalTrips: Number,
    totalEarnings: Number
  }
}
```

#### Bookings Collection
```javascript
{
  _id: ObjectId,
  bookingId: String (unique),
  userId: ObjectId (ref: 'User'),
  driverId: ObjectId (ref: 'Driver'),
  vehicleId: ObjectId (ref: 'Vehicle'),
  pickupLocation: {
    address: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  dropoffLocation: {
    address: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  passengerCount: Number,
  pricing: {
    baseFare: Number,
    distanceFare: Number,
    timeFare: Number,
    total: Number,
    currency: String
  },
  status: String (enum: ['pending', 'confirmed', 'inProgress', 'completed', 'cancelled']),
  scheduledDate: Date,
  pickupTime: Date,
  tripDetails: {
    estimatedDistance: Number,
    estimatedDuration: Number,
    actualDistance: Number,
    actualDuration: Number
  },
  paymentStatus: String (enum: ['pending', 'paid', 'failed', 'refunded']),
  createdAt: Date,
  updatedAt: Date
}
```

#### Payment Methods Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: 'User'),
  type: String (enum: ['credit_card', 'debit_card', 'digital_wallet', 'cash']),
  provider: String (enum: ['visa', 'mastercard', 'paypal', 'apple_pay']),
  lastFourDigits: String,
  cardholderName: String,
  isDefault: Boolean,
  isActive: Boolean,
  externalId: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Database Indexes
The system includes comprehensive indexing for optimal performance:
- **Users**: email, referralCode, refreshTokens.token, resetPasswordToken
- **Vehicles**: vehicleId, driverId, currentLocation.coordinates (2dsphere), status
- **Bookings**: bookingId, userId, driverId, pickupLocation.coordinates (2dsphere), status
- **Payment Methods**: userId, externalId, isDefault

---

## 🔐 Security & Authentication

### JWT Token Management
- **Access Token**: 24-hour expiration, used for API requests
- **Refresh Token**: 7-day expiration, used for token renewal
- **Token Rotation**: Automatic refresh token rotation on use
- **Secure Storage**: Tokens stored securely with proper validation

### Security Features
- **Password Hashing**: bcrypt with 12 salt rounds
- **Input Validation**: Comprehensive validation on all endpoints
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **CORS Protection**: Configured for specific origins
- **Helmet Security**: Security headers for protection
- **Environment Variables**: Secure credential management

### Authentication Flow
1. User registers/logs in
2. Server generates access and refresh tokens
3. Client stores tokens securely
4. Access token included in API requests
5. Token automatically refreshed when expired
6. Secure logout clears all tokens

---

## 🗺️ Location & Mapping System

### Geospatial Features
- **Geocoding**: Address to coordinate conversion
- **Reverse Geocoding**: Coordinate to address conversion
- **Route Calculation**: Distance and duration estimation
- **Service Areas**: Defined operating regions
- **Real-time Tracking**: Vehicle location updates

### Location Collections
- **locations**: Main location data storage
- **service_areas**: Service area definitions
- **geocoding_cache**: Cached geocoding results
- **route_cache**: Cached route calculations

### Geospatial Queries
```javascript
// Find vehicles near location
{
  'currentLocation.coordinates': {
    $near: {
      $geometry: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      $maxDistance: 10000 // meters
    }
  }
}
```

---

## 💳 Payment System

### Payment Methods
- **Credit/Debit Cards**: Visa, Mastercard, American Express
- **Digital Wallets**: PayPal, Apple Pay, Google Pay
- **Bank Transfers**: EFT and other bank methods
- **Cash**: Traditional cash payments

### Payment Processing
- **Secure Storage**: Encrypted payment data
- **External Integration**: Support for payment processors
- **Transaction Tracking**: Complete payment history
- **Refund Management**: Automated refund processing
- **Fraud Detection**: Fingerprinting and validation

### Payment Flow
1. User adds payment method
2. Payment method encrypted and stored
3. Booking payment processed
4. Transaction recorded and tracked
5. Receipt generated and sent

---

## 👥 User Management

### User Features
- **Profile Management**: Complete user profiles
- **Loyalty Program**: Tiered rewards system
- **Referral System**: User referral tracking
- **Corporate Accounts**: Business account management
- **Bulk Bookings**: Corporate booking management

### Loyalty Program
- **Tiers**: Bronze, Silver, Gold, Platinum, Diamond
- **Points**: Earned through trips and activities
- **Rewards**: Discounts, free rides, upgrades
- **Tracking**: Complete loyalty history

### Corporate Features
- **Account Management**: Company profile setup
- **Budget Control**: Monthly spending limits
- **User Authorization**: Employee access management
- **Bulk Operations**: Mass booking capabilities

---

## 🛠️ Development & Deployment

### Development Commands
```bash
# Start development server
npm run dev

# Run tests
npm test

# Run tests with coverage
npm run test:coverage

# Setup database
npm run db:setup

# Create indexes
npm run db:indexes

# Seed database
npm run db:seed
```

### Production Deployment
1. **Environment Setup**: Configure production environment variables
2. **Database Setup**: Run database setup and indexing
3. **Security Configuration**: Ensure all security measures are enabled
4. **Monitoring**: Set up logging and monitoring
5. **SSL/TLS**: Configure secure connections
6. **Load Balancing**: Set up for high availability

### Environment Variables
```env
NODE_ENV=production
PORT=3000
MONGODB_URI=<production-mongodb-uri>
JWT_SECRET=<strong-secret-key>
JWT_REFRESH_SECRET=<strong-refresh-secret>
SMTP_HOST=<email-server>
SMTP_USER=<email-username>
SMTP_PASS=<email-password>
```

---

## 🧪 Testing

### Test Structure
- **Unit Tests**: Individual function testing
- **Integration Tests**: API endpoint testing
- **Database Tests**: Database operation testing
- **Security Tests**: Authentication and authorization testing

### Running Tests
```bash
# Run all tests
npm test

# Run specific test file
npm test -- tests/users.test.js

# Run tests with watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### Test Coverage
- **Minimum Coverage**: 70% branches, 75% functions, 80% lines
- **Critical Paths**: 100% coverage for authentication and payment
- **Security Tests**: Comprehensive security validation

---

## 🔧 Troubleshooting

### Common Issues

#### Database Connection Issues
```bash
# Check MongoDB connection
npm run db:health

# Verify environment variables
echo $MONGODB_URI

# Test database connectivity
node test-connection.js
```

#### Authentication Issues
- Verify JWT secrets are properly configured
- Check token expiration settings
- Ensure proper token format in requests

#### Performance Issues
- Run database index creation: `npm run db:indexes`
- Check query performance in MongoDB logs
- Monitor memory usage and response times

#### Email Issues
- Verify SMTP configuration
- Check email service credentials
- Test email sending functionality

### Logging
The system includes comprehensive logging for:
- **Authentication Events**: Login, logout, token refresh
- **API Requests**: Request/response logging
- **Database Operations**: Query performance and errors
- **Security Events**: Failed authentication attempts
- **Payment Processing**: Transaction logging

### Monitoring
- **Health Checks**: `/api/health` endpoint
- **Performance Metrics**: Response times and throughput
- **Error Tracking**: Comprehensive error logging
- **Security Monitoring**: Failed authentication attempts

---

## 📞 Support

### Documentation
- **API Documentation**: Available at `/api-docs`
- **Database Schema**: Detailed in this document
- **Security Guidelines**: Comprehensive security practices

### Contact
For technical support or questions:
- **Email**: support@swiftlyft.co.za
- **Documentation**: This comprehensive guide
- **API Reference**: Swagger documentation

---

*Last Updated: December 2024*
*Version: 1.0.0*
