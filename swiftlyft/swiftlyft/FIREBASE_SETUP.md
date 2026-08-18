# Firebase Setup Guide for SwiftLyft

## Current Status

**DEVELOPMENT MODE ACTIVE** - The app is currently running without Firebase services to avoid API key errors during development.

### What's Disabled:
- Firebase Core initialization
- Firebase Authentication
- Firebase Cloud Messaging
- Firebase Analytics
- All Firebase service calls

### What's Working:
- Mock user authentication (creates local users)
- Mock data loading (vehicles, bookings, favorites)
- Local storage and persistence
- Full UI functionality
- All screens and navigation

## Development Mode (Current)

The app uses mock services and local storage to simulate Firebase functionality:

- **Authentication**: Creates mock users with any valid email/password
- **Data**: Loads mock vehicles and bookings from local storage
- **Storage**: Uses SharedPreferences for data persistence
- **Analytics**: Disabled (no tracking)

### To Test the App:
1. Use any email/password combination to sign in
2. The app will create a mock user account
3. All features work with mock data
4. No Firebase connection required

## Production Firebase Setup

When you're ready to use real Firebase services:

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `swiftlyft`
4. Follow the setup wizard

### 2. Add Apps to Firebase Project

#### Web App
1. In Firebase Console, click the web icon (</>)
2. Register app with nickname: `swiftlyft-web`
3. Copy the configuration object

#### Android App
1. In Firebase Console, click the Android icon
2. Register app with package name: `com.example.swiftlyft`
3. Download `google-services.json` and place it in `android/app/`

#### iOS App (if needed)
1. In Firebase Console, click the iOS icon
2. Register app with bundle ID: `com.example.swiftlyft`
3. Download `GoogleService-Info.plist`

### 3. Update Firebase Configuration

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase project values:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-actual-api-key',
  appId: 'your-actual-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-actual-project-id.firebaseapp.com',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

### 4. Enable Firebase Services

In Firebase Console, enable the following services:

#### Authentication
1. Go to Authentication > Sign-in method
2. Enable Email/Password
3. Enable Google Sign-in (optional)

#### Cloud Firestore (if needed)
1. Go to Firestore Database
2. Create database in test mode
3. Set up security rules

#### Cloud Messaging
1. Go to Cloud Messaging
2. Set up for your platforms

### 5. Update Android Configuration

1. Ensure `google-services.json` is in `android/app/`
2. Verify `android/build.gradle` includes Google Services plugin
3. Verify `android/app/build.gradle` applies the plugin

### 6. Re-enable Firebase in Code

1. **Uncomment imports in `lib/main.dart`:**
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   import 'services/auth_service.dart';
   import 'services/notification_service.dart';
   import 'services/payment_service.dart';
   ```

2. **Uncomment Firebase initialization in `main()`:**
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

3. **Uncomment service initialization:**
   ```dart
   await AuthService().initialize();
   await NotificationService().initialize();
   await PaymentService().initialize();
   ```

4. **Uncomment service imports in `lib/providers/app_state.dart`:**
   ```dart
   import '../services/auth_service.dart';
   import '../services/analytics_service.dart';
   ```

5. **Uncomment service declarations:**
   ```dart
   final AuthService _authService = AuthService();
   final AnalyticsService _analyticsService = AnalyticsService();
   ```

6. **Uncomment all Firebase service calls throughout the code**

### 7. Test Firebase Integration

1. Run the app
2. Check console logs for "Firebase initialized successfully"
3. Test authentication features
4. Test push notifications

## Current Firebase Services Used

- **Firebase Auth**: User authentication (currently disabled)
- **Firebase Messaging**: Push notifications (currently disabled)
- **Firebase Core**: Base Firebase functionality (currently disabled)

## Error Handling

The app is designed to gracefully handle Firebase initialization failures:
- If Firebase fails to initialize, the app continues with limited functionality
- Authentication falls back to local storage
- Notifications fall back to local notifications only

## Troubleshooting

### Common Issues

1. **"No Firebase App '[DEFAULT]' has been created"**
   - Ensure Firebase.initializeApp() is called before using Firebase services
   - Check that firebase_options.dart has correct configuration

2. **Authentication not working**
   - Verify Firebase Auth is enabled in Firebase Console
   - Check that the API key is correct

3. **Push notifications not working**
   - Verify Cloud Messaging is set up
   - Check device permissions
   - Verify FCM token is being generated

### Development vs Production

- **Development**: Uses mock services and local storage (current mode)
- **Production**: Requires real Firebase project with proper configuration

## Next Steps

1. **For Development**: Continue using the current mock setup
2. **For Production**: Follow the Firebase setup steps above
3. **Testing**: Test all features thoroughly in both modes
4. **Security**: Set up proper security rules for Firestore (if used)
5. **Analytics**: Configure analytics and crash reporting (optional)

## Quick Toggle

To quickly switch between development and production modes:

1. **Development Mode**: Set `isDevelopmentMode = true` in `lib/utils/constants.dart`
2. **Production Mode**: Set `isDevelopmentMode = false` and follow Firebase setup steps 