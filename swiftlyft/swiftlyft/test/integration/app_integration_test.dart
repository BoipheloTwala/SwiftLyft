import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftlyft/main.dart';
import 'package:swiftlyft/providers/app_state.dart';
import 'package:swiftlyft/models/user.dart';
import 'package:swiftlyft/screens/login_screen.dart';
import 'package:swiftlyft/screens/home_screen.dart';
import 'package:swiftlyft/screens/vehicle_listing_screen.dart';
import 'package:swiftlyft/screens/settings_screen.dart';
import 'package:swiftlyft/screens/trip_history_screen.dart';
import 'package:swiftlyft/widgets/error_handler.dart';

void main() {
  group('SwiftLyft Integration Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });
    testWidgets('Complete user journey: Login to Booking', (WidgetTester tester) async {
      // Create a mock logged-in state
      final mockUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        phoneNumber: '+1234567890',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Build the app with a pre-configured AppState
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) {
            final state = AppState();
            // Manually set the user as logged in for testing
            state.auth.setTestUser(mockUser);
            return state;
          },
          child: const SwiftLyftApp(),
        ),
      );

      // Wait for splash screen
      await tester.pumpAndSettle();

      // Should navigate directly to home screen since user is logged in
      expect(find.byType(HomeScreen), findsOneWidget);

      // Test navigation to vehicle listing by tapping the Vehicles tab
      await tester.tap(find.text('Vehicles'));
      await tester.pumpAndSettle();

      expect(find.byType(VehicleListingScreen), findsOneWidget);

      // Test search functionality
      await tester.enterText(find.widgetWithText(TextField, 'Search vehicles...'), 'Mercedes');
      await tester.pumpAndSettle();

      // Should show filtered results
      expect(find.text('Mercedes'), findsWidgets);
    });

    testWidgets('Settings and preferences flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AppState(),
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test dark mode toggle
      final darkModeSwitch = find.byKey(const Key('dark_mode_switch'));
      expect(darkModeSwitch, findsOneWidget);

      await tester.tap(darkModeSwitch);
      await tester.pumpAndSettle();

      // Test language selection
      await tester.tap(find.byKey(const Key('language_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Afrikaans'));
      await tester.pumpAndSettle();

      // Verify language changed
      expect(find.text('Afrikaans'), findsOneWidget);
    });

    testWidgets('Search and favorites functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AppState(),
          child: const MaterialApp(
            home: VehicleListingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test search
      await tester.enterText(find.byKey(const Key('search_field')), 'BMW');
      await tester.pumpAndSettle();

      // Test adding to favorites
      final favoriteButton = find.byKey(const Key('favorite_button_1')).first;
      await tester.tap(favoriteButton);
      await tester.pumpAndSettle();

      // Verify favorite was added (icon should change)
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('Trip history and booking management', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AppState(),
          child: const MaterialApp(
            home: TripHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show trip history
      expect(find.byType(TripHistoryScreen), findsOneWidget);

      // Test filtering by date
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Select last 30 days filter
      await tester.tap(find.text('Last 30 days'));
      await tester.pumpAndSettle();

      // Should show filtered results
      expect(find.byKey(const Key('trip_list')), findsOneWidget);
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      await tester.pumpWidget(
        ErrorBoundary(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // Simulate an error
                  throw Exception('Test error');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error boundary
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Test retry functionality
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigation flow between screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AppState(),
          child: MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/vehicle-listing': (context) => const VehicleListingScreen(),
              '/trip-history': (context) => const TripHistoryScreen(),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test navigation to different screens
      await tester.tap(find.byKey(const Key('settings_nav')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('trip_history_nav')));
      await tester.pumpAndSettle();
      expect(find.byType(TripHistoryScreen), findsOneWidget);
    });

    testWidgets('Form validation across screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AppState(),
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test empty form submission
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Test invalid email format
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Test weak password
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'weak');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters long'), findsOneWidget);
    });

    testWidgets('Offline support and data persistence', (WidgetTester tester) async {
      final appState = AppState();
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: VehicleListingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate loading cached data
      await appState.loadVehicles();
      await tester.pumpAndSettle();

      // Should show vehicles even in offline mode
      expect(find.byKey(const Key('vehicle_list')), findsOneWidget);

      // Test search history persistence
      await tester.enterText(find.byKey(const Key('search_field')), 'Test Search');
      await tester.pumpAndSettle();

      // Search should be added to history
      expect(appState.searchHistory.contains('Test Search'), isTrue);
    });
  });
}

// Mock widgets for testing
class MockHomeScreen extends StatelessWidget {
  const MockHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('vehicle_listing_nav'),
            onPressed: () => Navigator.pushNamed(context, '/vehicle-listing'),
            child: const Text('View Vehicles'),
          ),
          ElevatedButton(
            key: const Key('settings_nav'),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            child: const Text('Settings'),
          ),
          ElevatedButton(
            key: const Key('trip_history_nav'),
            onPressed: () => Navigator.pushNamed(context, '/trip-history'),
            child: const Text('Trip History'),
          ),
        ],
      ),
    );
  }
}

class MockLoginScreen extends StatelessWidget {
  const MockLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              key: const Key('email_field'),
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            TextFormField(
              key: const Key('password_field'),
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('login_button'),
              onPressed: () {
                // Mock login logic
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
} 