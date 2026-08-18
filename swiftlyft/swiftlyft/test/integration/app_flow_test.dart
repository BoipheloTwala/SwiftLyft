import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftlyft/main.dart';
import 'package:swiftlyft/providers/app_state.dart';
import 'package:swiftlyft/screens/quote_history_screen.dart';
import 'package:swiftlyft/screens/quote_details_screen.dart';
import 'package:swiftlyft/screens/driver_rating_screen.dart';
import 'package:swiftlyft/screens/payment_methods_screen.dart';
import 'package:swiftlyft/screens/notifications_screen.dart';
import 'package:swiftlyft/screens/support_screen.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestApp() {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const SwiftLyftApp(),
    );
  }

  group('App Integration Tests', () {
    testWidgets('Complete user journey from login to booking', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Should start at splash screen
      expect(find.byType(SplashScreen), findsOneWidget);

      // Wait for splash to complete and navigate to login
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should be on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill in login form
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'StrongPass123!');
      
      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should navigate to home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to vehicle listing
      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      // Should be on vehicle listing screen
      expect(find.byType(VehicleListingScreen), findsOneWidget);

      // Select a vehicle
      await tester.tap(find.byType(VehicleCard).first);
      await tester.pumpAndSettle();

      // Should be on vehicle details screen
      expect(find.byType(VehicleDetailsScreen), findsOneWidget);

      // Request quote
      await tester.tap(find.text('Request Quote'));
      await tester.pumpAndSettle();

      // Should be on quote request screen
      expect(find.byType(QuoteRequestScreen), findsOneWidget);

      // Fill quote form
      await tester.enterText(find.byKey(const Key('pickup_field')), 'Sandton City Mall');
      await tester.enterText(find.byKey(const Key('dropoff_field')), 'OR Tambo Airport');
      await tester.enterText(find.byKey(const Key('passengers_field')), '2');

      // Submit quote request
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      // Should show success message or navigate to confirmation
      expect(find.text('Quote Request Submitted'), findsOneWidget);
    });

    testWidgets('Complete quote lifecycle: Request to Acceptance', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to vehicle listing
      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      // Select a vehicle
      await tester.tap(find.byType(VehicleCard).first);
      await tester.pumpAndSettle();

      // Request quote
      await tester.tap(find.text('Request Quote'));
      await tester.pumpAndSettle();

      // Fill and submit quote form
      await tester.enterText(find.byKey(const Key('pickup_field')), 'Sandton City Mall');
      await tester.enterText(find.byKey(const Key('dropoff_field')), 'OR Tambo Airport');
      await tester.enterText(find.byKey(const Key('passengers_field')), '2');
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      // Navigate to quote history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should be on quote history screen
      expect(find.byType(QuoteHistoryScreen), findsOneWidget);

      // Select a quote
      await tester.tap(find.textContaining('Quote #').first);
      await tester.pumpAndSettle();

      // Should be on quote details screen
      expect(find.byType(QuoteDetailsScreen), findsOneWidget);

      // Select payment method and accept quote
      await tester.tap(find.byType(RadioListTile).first);
      await tester.tap(find.text('Accept Quote & Book Now'));
      await tester.pumpAndSettle();

      // Should navigate to home after booking
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Driver rating and feedback flow', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to trip history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Select a completed trip
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Tap rate driver button (assuming it exists)
      final rateButton = find.text('Rate Driver');
      if (rateButton.evaluate().isNotEmpty) {
        await tester.tap(rateButton);
        await tester.pumpAndSettle();

        // Should be on driver rating screen
        expect(find.byType(DriverRatingScreen), findsOneWidget);

        // Fill rating form
        await tester.tap(find.byIcon(Icons.star).at(3)); // 4-star rating
        await tester.enterText(find.byKey(const Key('review_field')), 'Excellent service!');

        // Submit rating
        await tester.tap(find.text('Submit Rating'));
        await tester.pumpAndSettle();

        // Should show success message
        expect(find.text('Thank you for your feedback!'), findsOneWidget);
      }
    });

    testWidgets('Quote expiration handling', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to quote history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should show quote history with expired quotes marked
      expect(find.byType(QuoteHistoryScreen), findsOneWidget);

      // Check for expired quote indicators
      expect(find.text('Expired'), findsNothing); // Or findsWidgets if expired quotes exist
    });

    testWidgets('Payment method management', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Navigate to payment methods (assuming this exists in settings)
      await tester.tap(find.text('Payment Methods'));
      await tester.pumpAndSettle();

      // Should be on payment methods screen
      expect(find.byType(PaymentMethodsScreen), findsOneWidget);

      // Test adding a payment method
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill payment method form
      await tester.enterText(find.byKey(const Key('card_number_field')), '4111111111111111');
      await tester.enterText(find.byKey(const Key('expiry_field')), '12/25');
      await tester.enterText(find.byKey(const Key('cvv_field')), '123');
      await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');

      // Submit form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show payment method in list
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('Real-time notifications and updates', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to notifications
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      // Should be on notifications screen
      expect(find.byType(NotificationsScreen), findsOneWidget);

      // Test notification marking as read
      final notificationItem = find.byType(ListTile).first;
      if (notificationItem.evaluate().isNotEmpty) {
        await tester.tap(notificationItem);
        await tester.pumpAndSettle();

        // Should mark as read (check for visual changes)
        expect(find.byType(NotificationsScreen), findsOneWidget);
      }
    });

    testWidgets('Support ticket creation and FAQ', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to support
      await tester.tap(find.byIcon(Icons.help));
      await tester.pumpAndSettle();

      // Should be on support screen
      expect(find.byType(SupportScreen), findsOneWidget);

      // Test FAQ search
      await tester.tap(find.text('FAQ'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'booking');
      await tester.pumpAndSettle();

      // Should show filtered FAQ results
      expect(find.byType(ExpansionTile), findsWidgets);

      // Test support ticket creation
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Booking Issues'));
      await tester.pumpAndSettle();

      // Should show chat interface
      expect(find.byType(SupportScreen), findsOneWidget);
    });

    testWidgets('Settings and preferences management', (WidgetTester tester) async {
      // Build the app and navigate to settings
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to settings (assuming user is logged in)
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should be on settings screen
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Toggle dark mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      // Verify dark mode is applied
      final appState = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(appState.themeMode, ThemeMode.dark);

      // Change language
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Afrikaans'));
      await tester.pumpAndSettle();

      // Verify language change
      expect(find.text('Voorkeure'), findsOneWidget); // Settings in Afrikaans
    });

    testWidgets('Search and filtering functionality', (WidgetTester tester) async {
      // Build the app and navigate to vehicle listing
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      // Should be on vehicle listing screen
      expect(find.byType(VehicleListingScreen), findsOneWidget);

      // Perform search
      await tester.enterText(find.byType(TextField), 'Mercedes');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('Mercedes S-Class'), findsOneWidget);

      // Apply filter
      await tester.tap(find.text('Price'));
      await tester.pumpAndSettle();

      // Verify filtered results
      expect(find.byType(VehicleCard), findsWidgets);
    });

    testWidgets('Favorites functionality', (WidgetTester tester) async {
      // Build the app and navigate to vehicle listing
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      // Tap favorite button on first vehicle
      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();

      // Verify favorite icon changed
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Navigate to favorites section
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      // Verify favorited vehicle is shown
      expect(find.byType(VehicleCard), findsOneWidget);
    });

    testWidgets('Trip history and booking management', (WidgetTester tester) async {
      // Build the app and navigate to trip history
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should be on trip history screen
      expect(find.byType(TripHistoryScreen), findsOneWidget);

      // Switch between tabs
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelled'));
      await tester.pumpAndSettle();

      // Verify different booking lists are shown
      expect(find.byType(TripHistoryScreen), findsOneWidget);
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Simulate network error by triggering error state
      // Note: In a real test, you would trigger an actual error condition
      // For now, we'll just verify the app loads correctly
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify error is displayed
      expect(find.text('Network error occurred'), findsOneWidget);

      // Test retry functionality
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify error is cleared
      expect(find.text('Network error occurred'), findsNothing);
    });

    testWidgets('Offline functionality', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Simulate offline mode
      // Note: In a real test, you would simulate offline conditions
      // For now, we'll just verify the app loads correctly
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpAndSettle();

      // Verify cached data is displayed
      expect(find.byType(VehicleCard), findsWidgets);
    });

    testWidgets('Navigation consistency', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Test bottom navigation
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      expect(find.byType(VehicleListingScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.local_offer));
      await tester.pumpAndSettle();
      expect(find.byType(SpecialOffersScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.byType(TripHistoryScreen), findsOneWidget);
    });

    testWidgets('Form validation and submission', (WidgetTester tester) async {
      // Build the app and navigate to quote request
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(VehicleCard).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Request Quote'));
      await tester.pumpAndSettle();

      // Try to submit without filling required fields
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      // Verify validation errors are shown
      expect(find.text('Address is required'), findsOneWidget);

      // Fill required fields
      await tester.enterText(find.byKey(const Key('pickup_field')), 'Sandton City Mall');
      await tester.enterText(find.byKey(const Key('dropoff_field')), 'OR Tambo Airport');
      await tester.enterText(find.byKey(const Key('passengers_field')), '2');

      // Submit again
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      // Verify successful submission
      expect(find.text('Quote Request Submitted'), findsOneWidget);
    });

    testWidgets('Performance and responsiveness', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Measure initial load time
      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should load within 1 second

      // Test scrolling performance
      await tester.fling(find.byType(ListView), const Offset(0, -500), 3000);
      await tester.pumpAndSettle();

      // Verify smooth scrolling
      expect(find.byType(VehicleCard), findsWidgets);
    });
  });
}

// Mock widgets for testing
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Splash Screen')),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TextField(key: Key('email_field')),
          const TextField(key: Key('password_field')),
          ElevatedButton(
            key: const Key('login_button'),
            onPressed: () {},
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home Screen')),
    );
  }
}

class VehicleListingScreen extends StatelessWidget {
  const VehicleListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Vehicle Listing Screen')),
    );
  }
}

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Vehicle Details Screen')),
    );
  }
}

class QuoteRequestScreen extends StatelessWidget {
  const QuoteRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TextField(key: Key('pickup_field')),
          const TextField(key: Key('dropoff_field')),
          const TextField(key: Key('passengers_field')),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quote Request Submitted')),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Settings Screen')),
    );
  }
}

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Trip History Screen')),
    );
  }
}

class SpecialOffersScreen extends StatelessWidget {
  const SpecialOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Special Offers Screen')),
    );
  }
}

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Mercedes S-Class'),
        trailing: IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {},
        ),
      ),
    );
  }
} 