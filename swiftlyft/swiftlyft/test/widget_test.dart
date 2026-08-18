import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftlyft/main.dart';
import 'package:swiftlyft/providers/app_state.dart';
import 'package:swiftlyft/screens/quote_history_screen.dart';
import 'package:swiftlyft/screens/quote_details_screen.dart';
import 'package:swiftlyft/screens/driver_rating_screen.dart';
import 'package:swiftlyft/utils/routes.dart';

void main() {
  group('SwiftLyft Widget Tests', () {
    testWidgets('App initializes correctly', (WidgetTester tester) async {
      // Build our app with provider
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AppState(),
          child: const SwiftLyftApp(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should show splash screen initially
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Quote history screen loads correctly', (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: QuoteHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display quote history screen
      expect(find.byType(QuoteHistoryScreen), findsOneWidget);
      expect(find.text('Quote History'), findsOneWidget);
    });

    testWidgets('Quote details screen loads with quote ID', (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: QuoteDetailsScreen(quoteId: 'test-quote-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display quote details screen
      expect(find.byType(QuoteDetailsScreen), findsOneWidget);
      expect(find.text('Quote Details'), findsOneWidget);
    });

    testWidgets('Driver rating screen loads correctly', (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: DriverRatingScreen(
              bookingId: 'test-booking-id',
              driverId: 'test-driver-id',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display driver rating screen
      expect(find.byType(DriverRatingScreen), findsOneWidget);
      expect(find.text('Rate Your Driver'), findsOneWidget);
    });

    testWidgets('Quote history filtering works', (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: QuoteHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test filter button exists
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should show filter dialog
      expect(find.text('Filter Quotes'), findsOneWidget);
    });

    testWidgets('Driver rating form validation', (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: DriverRatingScreen(
              bookingId: 'test-booking-id',
              driverId: 'test-driver-id',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to the submit button
      await tester.ensureVisible(find.text('Submit Rating'));
      await tester.pumpAndSettle();

      // Try to submit without rating
      await tester.tap(find.text('Submit Rating'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please provide a rating'), findsOneWidget);
    });

    testWidgets('Route navigation works correctly', (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            routes: AppRoutes.routes,
            initialRoute: '/',
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to quote history
      Navigator.pushNamed(tester.element(find.byType(Scaffold).first), AppRoutes.quoteHistory);
      await tester.pumpAndSettle();

      // Should be on quote history screen
      expect(find.byType(QuoteHistoryScreen), findsOneWidget);
    });
  });
}
