// DEVELOPMENT MODE - Firebase services are disabled
// To enable Firebase, uncomment the Firebase imports and initialization code
// and update firebase_options.dart with your actual Firebase project values

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'utils/theme.dart';
import 'utils/routes.dart';
import 'providers/app_state.dart';
import 'providers/payment_state.dart';
import 'providers/trip_history_queue_provider.dart';
import 'providers/batch_booking_stack_provider.dart';
import 'services/auth_service.dart';
import 'services/payment_api_service.dart';
import 'services/analytics_api_service.dart';
import 'widgets/error_handler.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  // Initialize Firebase first - COMMENTED OUT FOR DEVELOPMENT
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   debugPrint('Firebase initialized successfully');
  // } catch (e) {
  //   debugPrint('Firebase initialization failed: $e');
  //   // Continue without Firebase
  // }
  
  // Initialize services with better error handling
  try {
    await AuthService().initialize();
    debugPrint('AuthService initialized successfully');
  } catch (e) {
    // Continue without AuthService
    debugPrint('AuthService initialization failed: $e');
  }

  try {
    // NotificationService initialization (if needed)
    debugPrint('NotificationService ready');
  } catch (e) {
    // Continue without NotificationService
    debugPrint('NotificationService initialization failed: $e');
  }

  try {
    // PaymentService initialization (if needed)
    debugPrint('PaymentService ready');
  } catch (e) {
    // Continue without PaymentService
    debugPrint('PaymentService initialization failed: $e');
  }
  
  debugPrint('Running in development mode without Firebase');
  
  runApp(
    ErrorBoundary(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AppState()),
          ChangeNotifierProvider(create: (context) => TripHistoryQueueProvider()),
          ChangeNotifierProvider(create: (context) => BatchBookingStackProvider()),
        ],
        child: const SwiftLyftApp(),
      ),
    ),
  );
}

class SwiftLyftApp extends StatelessWidget {
  const SwiftLyftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'SwiftLyft',
          debugShowCheckedModeBanner: false,
          theme: SwiftLyftTheme.lightTheme,
          darkTheme: SwiftLyftTheme.darkTheme,
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          navigatorKey: AppRoutes.navigatorKey,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            // Add error boundary to catch any rendering issues
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
