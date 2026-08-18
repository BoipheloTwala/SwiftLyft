# SwiftLyft - Premium Ride-Sharing Platform

**SwiftLyft** is a comprehensive premium transportation platform designed for Johannesburg and Cape Town, South Africa. This full-stack application provides luxury vehicle booking, real-time tracking, and seamless payment processing for discerning travelers.

##  Project Overview

SwiftLyft combines a sophisticated Flutter mobile application with a robust Node.js backend API to deliver an end-to-end luxury transportation experience. The platform caters to individual travelers, corporate clients, and special event transportation needs.

###  Key Features

- **Premium Vehicle Fleet**: Luxury sedans, SUVs, and specialty vehicles
- **Real-time Booking**: Instant quotes and booking confirmation
- **Location Services**: GPS tracking and route optimization
- **Secure Payments**: Multiple payment methods with fraud protection
- **Corporate Solutions**: Bulk booking and corporate account management
- **Loyalty Program**: Rewards system for repeat customers
- **24/7 Support**: Integrated customer service and emergency assistance

##  Design Philosophy

**Luxury Aesthetic**: Clean, modern design with a color palette of gold (#FFD700), jet black (#000000), platinum white (#FFFFFF), and deep sapphire blue (#1A2A44) for depth and contrast.

**User Experience**: Streamlined navigation and interactions for browsing vehicles, requesting quotes, and booking rides with intuitive touch interfaces.

**Accessibility**: High-contrast text, alt text for images, and keyboard navigation support for inclusivity.

**Performance**: Optimized for smooth animations and fast load times on mobile devices.

##  Architecture & Technology Stack

### System Architecture

SwiftLyft follows a modern microservices-inspired architecture with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│  REST API       │◄──►│   MongoDB       │
│   (Mobile/Web)  │    │  (Node.js)      │    │   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │  External APIs  │
                    │ • Google Maps   │
                    │ • Payment APIs  │
                    │ • FCM/OneSignal │
                    │ • WhatsApp API  │
                    └─────────────────┘
```

### Frontend (Flutter)

- **Framework**: Flutter 3.1+ with Dart SDK
- **State Management**: Provider pattern with ChangeNotifier
- **Networking**: HTTP with custom interceptors and error handling
- **Authentication**: Firebase Auth with JWT tokens
- **Location Services**: Geolocator and Geocoding packages
- **Payments**: Stripe SDK integration
- **Notifications**: Firebase Cloud Messaging + Local notifications
- **Real-time**: WebSocket and Socket.IO for live updates
- **Storage**: SharedPreferences for local data, cached images

### Backend (Node.js)

- **Runtime**: Node.js with Express.js framework
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT with refresh token rotation
- **Validation**: Joi schema validation
- **Security**: Helmet, CORS, rate limiting, input sanitization
- **File Upload**: Multer for image/document handling
- **Email**: Nodemailer with SMTP configuration
- **Testing**: Jest with Supertest for API testing

### Infrastructure & DevOps

- **Version Control**: Git with GitHub
- **Containerization**: Docker support
- **Environment**: Development, staging, production configs
- **API Documentation**: Swagger/OpenAPI specification
- **Monitoring**: Error logging and performance tracking
- **CI/CD**: Automated testing and deployment pipelines

### External Integrations

- **Maps & Location**: Google Maps Platform
- **Payments**: Stripe/Paystack/Yoco payment gateways
- **Notifications**: Firebase Cloud Messaging, OneSignal
- **Communication**: WhatsApp Business API
- **Analytics**: Custom analytics with MongoDB aggregation

##  Project Structure

```
SwiftLyft/
├── swiftlyft/                          # Flutter Frontend Application
│   ├── lib/
│   │   ├── main.dart                   # App entry point
│   │   ├── models/                     # Data models (25 files)
│   │   │   ├── user.dart
│   │   │   ├── booking.dart
│   │   │   ├── vehicle.dart
│   │   │   └── ...
│   │   ├── providers/                  # State management (14 files)
│   │   │   ├── auth_provider.dart
│   │   │   ├── booking_provider.dart
│   │   │   └── ...
│   │   ├── screens/                    # UI screens (24 files)
│   │   │   ├── home_screen.dart
│   │   │   ├── booking_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── ...
│   │   ├── services/                   # API services (24 files)
│   │   │   ├── auth_service.dart
│   │   │   ├── booking_api_service.dart
│   │   │   ├── payment_service.dart
│   │   │   └── ...
│   │   ├── utils/                      # Utilities (15 files)
│   │   │   ├── constants.dart
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   └── ...
│   │   └── widgets/                    # Reusable components (30 files)
│   │       ├── custom_button.dart
│   │       ├── vehicle_card.dart
│   │       ├── loading_indicator.dart
│   │       └── ...
│   ├── assets/
│   │   ├── images/                     # Static images
│   │   └── icons/                      # App icons
│   ├── android/                        # Android platform code
│   ├── ios/                           # iOS platform code
│   ├── web/                           # Web platform code
│   ├── test/                          # Unit and integration tests
│   ├── pubspec.yaml                   # Flutter dependencies
│   └── README.md                      # Frontend-specific docs
│
├── Swiftlyft_backend/                 # Node.js Backend API
│   ├── server.js                      # Main server file
│   ├── package.json                   # Node dependencies
│   ├── models/                        # MongoDB schemas
│   │   ├── User.js
│   │   ├── Booking.js
│   │   ├── Vehicle.js
│   │   ├── Payment.js
│   │   └── ...
│   ├── routes/                        # API route handlers
│   │   ├── auth.js
│   │   ├── bookings.js
│   │   ├── payments.js
│   │   ├── users.js
│   │   └── ...
│   ├── middleware/                    # Express middleware
│   │   ├── auth.js                    # JWT authentication
│   │   ├── validation.js              # Input validation
│   │   └── errorHandler.js            # Error handling
│   ├── utils/                         # Utility functions
│   │   ├── jwt.js
│   │   ├── email.js
│   │   └── locationService.js
│   ├── tests/                         # Backend tests
│   │   ├── auth.test.js
│   │   ├── bookings.test.js
│   │   └── ...
│   ├── scripts/                       # Database setup scripts
│   ├── config/                        # Configuration files
│   ├── docs/                          # API documentation
│   └── README.md                      # Backend-specific docs
│
├── API_Testing_Guide.md              # API testing documentation
├── To-do.md                          # Development task tracking
├── SwiftLyft_API_Tests_Updated.postman_collection.json
└── SwiftLyft_Environment_Updated.postman_environment.json
```

### Directory Breakdown

- **`swiftlyft/`**: Complete Flutter application with modular architecture
- **`Swiftlyft_backend/`**: RESTful API server with comprehensive testing
- **`API_Testing_Guide.md`**: Detailed API testing procedures
- **`To-do.md`**: Team task management and progress tracking
- **Postman Collections**: Pre-configured API testing environments


##  Getting Started

This guide will help you set up both the Flutter frontend and Node.js backend for full-stack development.

### System Requirements

#### Frontend (Flutter)
- Flutter SDK (version 3.1 or higher)
- Dart SDK (comes with Flutter)
- Android Studio or Visual Studio Code with Flutter extension
- For Android: Android SDK (API 21+) and emulator/device
- For iOS: Xcode 14+ (macOS only)
- Minimum 8GB RAM recommended

#### Backend (Node.js)
- Node.js (version 18 or higher)
- npm or yarn package manager
- MongoDB (local installation or cloud instance)
- Git for version control

### Quick Setup (Full Stack)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/BoipheloTwala/SwiftLyft.git
   cd swiftlyft
   ```

2. **Set up the Backend:**
   ```bash
   cd Swiftlyft_backend

   # Install dependencies
   npm install

   # Set up environment variables
   cp env.example .env
   # Edit .env with your MongoDB connection and API keys

   # Set up database
   npm run db:setup
   npm run db:indexes

   # Start backend server
   npm run dev
   ```

3. **Set up the Frontend (in a new terminal):**
   ```bash
   cd ../swiftlyft

   # Install Flutter dependencies
   flutter pub get

   # Configure API endpoints (update AppConstants.baseUrl if needed)
   # Edit lib/utils/constants.dart to point to your backend URL

   # Run the app
   flutter run
   ```

### Detailed Setup Instructions

#### Backend Setup
```bash
cd Swiftlyft_backend

# 1. Install dependencies
npm install

# 2. Environment configuration
cp env.example .env
# Required environment variables:
# - MONGODB_URI: Your MongoDB connection string
# - JWT_SECRET: Secure random string for JWT tokens
# - GOOGLE_MAPS_API_KEY: For location services
# - STRIPE_SECRET_KEY: For payment processing
# - FCM_SERVER_KEY: For push notifications

# 3. Database setup
npm run db:setup      # Create collections
npm run db:indexes    # Create indexes
npm run db:seed       # Optional: seed with sample data

# 4. Start development server
npm run dev           # Runs on http://localhost:3000
```

#### Frontend Setup
```bash
cd swiftlyft

# 1. Install dependencies
flutter pub get

# 2. Configure environment
# Update lib/utils/constants.dart:
# - baseUrl: Point to your backend (http://localhost:3000/api)
# - Add API keys for Google Maps, Firebase, etc.

# 3. Firebase setup (if using Firebase services)
# - Add google-services.json (Android)
# - Add GoogleService-Info.plist (iOS)
# - Configure firebase_options.dart

# 4. Run on desired platform
flutter run                    # Android/iOS default
flutter run -d chrome         # Web browser
flutter run -d <device-id>    # Specific device
```

### API Configuration

Configure the following API keys in your respective environment files:

#### Backend (.env)
```env
# Database
MONGODB_URI=mongodb://localhost:27017/swiftlyft

# Authentication
JWT_SECRET=your-super-secure-jwt-secret
JWT_REFRESH_SECRET=your-refresh-token-secret

# External APIs
GOOGLE_MAPS_API_KEY=your-google-maps-key
STRIPE_SECRET_KEY=your-stripe-secret
PAYSTACK_SECRET_KEY=your-paystack-key
FCM_SERVER_KEY=your-fcm-server-key
ONESIGNAL_APP_ID=your-onesignal-app-id

# Email (optional)
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
```

#### Frontend (constants.dart)
```dart
class AppConstants {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String googleMapsApiKey = 'your-google-maps-key';
  static const String stripePublishableKey = 'your-stripe-publishable-key';
  // Add other API keys as needed
}
```

### Development Workflow

1. **Start Backend**: `cd Swiftlyft_backend && npm run dev`
2. **Start Frontend**: `cd swiftlyft && flutter run`
3. **API Testing**: Use Postman collection in root directory
4. **Database Management**: Use MongoDB Compass or Studio 3T

### Build Commands

#### Backend
```bash
# Production build
npm run build

# Start production server
npm start
```

#### Frontend
```bash
# Android APK
flutter build apk --release

# iOS (macOS only)
flutter build ios --release

# Web build
flutter build web --release
```

### Testing

#### Backend Tests
```bash
cd Swiftlyft_backend
npm test              # Run all tests
npm run test:auth     # Run specific test suite
```

#### Frontend Tests
```bash
cd swiftlyft
flutter test          # Unit tests
flutter drive --target=test_driver/app.dart  # Integration tests
```

### Troubleshooting

- **Backend won't start**: Check MongoDB connection and environment variables
- **Frontend API errors**: Verify backend URL and CORS settings
- **Firebase issues**: Ensure correct configuration files are in place
- **Build failures**: Run `flutter clean` and `flutter pub get`

For detailed troubleshooting, see the backend README and API testing guide.

## 🔧 Development & Deployment

### Development Environment

#### Code Quality & Standards
- **Linting**: Flutter lints enabled, ESLint for Node.js
- **Testing**: Unit tests, integration tests, and API testing
- **Code Style**: Consistent formatting with Prettier and Dart formatter
- **Git Workflow**: Feature branches with pull request reviews

#### Database Management
```bash
# Backend database operations
cd Swiftlyft_backend

# Setup database
npm run db:setup      # Create collections and indexes
npm run db:seed       # Populate with sample data
npm run db:backup     # Create database backup
npm run db:restore    # Restore from backup
```

#### Environment Management
- **Development**: Local MongoDB, debug logging, hot reload
- **Staging**: Cloud MongoDB, production-like settings
- **Production**: Optimized settings, monitoring, backups

### API Testing & Documentation

#### API Documentation
- **Swagger UI**: Interactive API docs at `http://localhost:3000/api-docs`
- **Postman Collections**: Pre-configured requests in root directory
- **Testing Guide**: See `API_Testing_Guide.md` for comprehensive testing procedures

#### Testing Commands
```bash
# Backend API tests
cd Swiftlyft_backend
npm test                    # Run all tests
npm run test:unit          # Unit tests only
npm run test:integration   # Integration tests only
npm run test:coverage      # With coverage report

# Frontend tests
cd swiftlyft
flutter test                # Unit tests
flutter test --coverage     # With coverage
```

### Deployment

#### Backend Deployment
```bash
# Production build
npm run build
npm start

# Docker deployment
docker build -t swiftlyft-backend .
docker run -p 3000:3000 swiftlyft-backend
```

#### Frontend Deployment
```bash
# Build for different platforms
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle
flutter build ios --release          # iOS (macOS only)
flutter build web --release          # Web deployment

# Firebase hosting (optional)
firebase init hosting
firebase deploy
```

#### Environment Variables for Production
```env
NODE_ENV=production
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/swiftlyft_prod
JWT_SECRET=your-production-jwt-secret
REDIS_URL=redis://your-redis-instance
```

##  API Documentation

### Backend API Overview

The SwiftLyft backend provides a comprehensive REST API with the following endpoints:

#### Core APIs
- **Authentication**: `/api/auth/*` - User registration, login, token management
- **Users**: `/api/users/*` - Profile management, loyalty, corporate features
- **Bookings**: `/api/bookings/*` - Trip booking, tracking, ratings
- **Vehicles**: `/api/vehicles/*` - Fleet management, availability, categories
- **Payments**: `/api/payments/*` - Payment processing, refunds, history
- **Notifications**: `/api/notifications/*` - Push notifications, settings
- **Support**: `/api/support/*` - Customer support tickets, chat
- **Analytics**: `/api/analytics/*` - Business intelligence, reporting

#### External Integrations
- **Google Maps**: Location services and routing
- **Stripe/Paystack**: Payment processing
- **Firebase/OneSignal**: Push notifications
- **WhatsApp**: Business messaging

### API Testing

#### Using Postman
1. Import `SwiftLyft_API_Tests_Updated.postman_collection.json`
2. Load environment: `SwiftLyft_Environment_Updated.postman_environment.json`
3. Update environment variables for your setup
4. Run test suites or individual requests

#### Automated Testing
```bash
# Run comprehensive API tests
cd Swiftlyft_backend
npm run test:api

# Test specific endpoints
npm run test:auth
npm run test:bookings
npm run test:payments
```

### API Response Format

All API responses follow a consistent format:

```json
{
  "success": true,
  "data": { /* Response data */ },
  "message": "Optional success message",
  "pagination": { /* For paginated responses */ }
}
```

Error responses:
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": { /* Additional error info */ }
}
```

##  Contributing

### Team Structure

SwiftLyft development follows a specialized team approach:

- **👨‍💻 Developer 1 (Tumelo)**: Authentication & User Management
- **👨‍💻 Developer 2 (Boiphelo)**: Booking & Trip Management
- **👨‍💻 Developer 3 (Austin)**: Payment & Vehicle Management
- **👨‍💻 Developer 4 (Khumo)**: Notifications & Support Systems

### Development Workflow

1. **Task Assignment**: Check `To-do.md` for assigned tasks
2. **Branch Creation**: `git checkout -b feature/your-feature-name`
3. **Code Development**: Follow coding standards and add tests
4. **Pull Request**: Create PR with description and screenshots
5. **Code Review**: Address review feedback
6. **Merge**: Squash merge to main branch

### Coding Standards

#### Flutter (Frontend)
- Use Provider for state management
- Follow Dart style guidelines
- Add proper error handling
- Write unit tests for business logic
- Use meaningful variable names

#### Node.js (Backend)
- Use async/await for asynchronous operations
- Implement proper error handling with try/catch
- Add JSDoc comments for functions
- Follow RESTful API conventions
- Write comprehensive tests

### Commit Guidelines

```
feat: add user authentication flow
fix: resolve payment processing bug
docs: update API documentation
test: add booking validation tests
refactor: improve error handling in user service
```

### Code Review Process

- All PRs require approval from at least one team member
- Automated tests must pass
- Code coverage should not decrease
- Documentation updated for API changes
- Security review for authentication/payment features

##  Project Status & Roadmap

### Current Status

**Phase**: API Integration & Testing
**Progress**: 75% Complete
**Team Size**: 4 Developers
**Timeline**: December 2024 - January 2025

### Completed Features ✅

- ✅ Flutter UI/UX Design (Complete)
- ✅ Backend API Structure (Complete)
- ✅ Database Schema & Models (Complete)
- ✅ Authentication System (In Progress)
- ✅ User Management (In Progress)
- ✅ Booking System (In Progress)
- ✅ Payment Integration (In Progress)

### In Development 

- 🔄 Real-time Notifications
- 🔄 Location Services Integration
- 🔄 Driver Management System
- 🔄 Corporate Features
- 🔄 Analytics Dashboard

### Upcoming Features 

- 📅 Advanced Analytics & Reporting
- 📅 Multi-language Support (Afrikaans, isiZulu)
- 📅 Offline Mode Capabilities
- 📅 Advanced Driver Features
- 📅 Loyalty Program Enhancements

### Quality Metrics

- **Code Coverage**: Target > 80%
- **API Response Time**: < 2 seconds
- **Error Rate**: < 1%
- **User Satisfaction**: Target > 4.5/5

### Success Criteria

- [ ] All API endpoints fully integrated
- [ ] Comprehensive test coverage achieved
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] User acceptance testing completed
- [ ] Production deployment successful


### Development Team

- **Tumelo Mabetwa**: Authentication & User Management
- **Boiphelo Twala**: Booking & Trip Management
- **Austin Mukhuba**: Payment & Vehicle Management
- **Khumo Ramerafe**: Notifications & Support Systems

### Documentation

- **Backend API Docs**: `Swiftlyft_backend/README.md`
- **API Testing Guide**: `API_Testing_Guide.md`
- **Frontend Guide**: `swiftlyft/README.md`
- **Task Management**: `To-do.md`

### External Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Node.js Documentation**: https://nodejs.org/docs
- **MongoDB Documentation**: https://docs.mongodb.com
- **Stripe API Docs**: https://stripe.com/docs/api

---

## 📄 License

This project is developed as part of the INSY7315 final project submission.

**Version**: 1.0.0
**Last Updated**: December 2024
**Repository**: [GitHub Repository URL]

---

*SwiftLyft - Elevating Premium Transportation in Johannesburg and Cape Town*
