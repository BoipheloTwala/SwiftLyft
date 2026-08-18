import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/vehicle_listing_screen.dart';
import '../screens/vehicle_details_screen.dart';
import '../screens/booking_creation_screen.dart';
import '../screens/quote_request_screen.dart';
import '../screens/trip_history_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/special_offers_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/payment_methods_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quote_details_screen.dart';
import '../screens/quote_history_screen.dart';
import '../screens/quote_management_screen.dart';
import '../screens/driver_rating_screen.dart';
import '../screens/bulk_bookings_screen.dart';
import '../screens/batch_booking_stack_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String vehicleListing = '/vehicle-listing';
  static const String vehicleDetails = '/vehicle-details';
  static const String bookingCreation = '/booking-creation';
  static const String quoteRequest = '/quote-request';
  static const String tripHistory = '/trip-history';
  static const String aboutUs = '/about-us';
  static const String specialOffers = '/special-offers';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String paymentMethods = '/payment-methods';
  static const String profile = '/profile';
  static const String quoteDetails = '/quote-details';
  static const String quoteHistory = '/quote-history';
  static const String quoteManagement = '/quote-management';
  static const String driverRating = '/driver-rating';
  static const String bulkBookings = '/bulk-bookings';
  static const String batchBookingStack = '/batch-booking-stack';

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    vehicleListing: (context) => const VehicleListingScreen(),
    tripHistory: (context) => const TripHistoryScreen(),
    aboutUs: (context) => const AboutUsScreen(),
    specialOffers: (context) => const SpecialOffersScreen(),
    settings: (context) => const SettingsScreen(),
    notifications: (context) => const NotificationsScreen(),
    paymentMethods: (context) => const PaymentMethodsScreen(),
    profile: (context) => const ProfileScreen(),
    quoteHistory: (context) => const QuoteHistoryScreen(),
    quoteManagement: (context) => const QuoteManagementScreen(),
    bulkBookings: (context) => const BulkBookingsManagementScreen(),
    batchBookingStack: (context) => const BatchBookingStackScreen(),
    // driverRating requires parameters, handled in onGenerateRoute
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case vehicleDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => VehicleDetailsScreen(
            vehicleId: args?['vehicleId'] ?? '',
            vehicleName: args?['vehicleName'] ?? '',
          ),
        );
      case bookingCreation:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => BookingCreationScreen(
            vehicleId: args?['vehicleId'],
            vehicleName: args?['vehicleName'],
            vehicleType: args?['vehicleType'],
            pickupAddress: args?['pickupAddress'],
            dropoffAddress: args?['dropoffAddress'],
            passengerCount: args?['passengerCount'],
            specialNotes: args?['specialNotes'],
            closeProtectionOfficer: args?['closeProtectionOfficer'],
          ),
        );
      case quoteRequest:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => QuoteRequestScreen(
            vehicleId: args?['vehicleId'] ?? '',
            vehicleName: args?['vehicleName'] ?? '',
          ),
        );
      case quoteDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => QuoteDetailsScreen(
            quoteId: args?['quoteId'] ?? '',
          ),
        );
      case driverRating:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => DriverRatingScreen(
            bookingId: args?['bookingId'] ?? '',
            driverId: args?['driverId'] ?? '',
          ),
        );
      default:
        // Handle unknown routes gracefully
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page Not Found'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pushReplacementNamed(home),
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Page Not Found',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The page you requested could not be found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
} 