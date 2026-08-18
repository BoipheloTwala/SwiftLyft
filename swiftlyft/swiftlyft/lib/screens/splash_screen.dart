import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../providers/app_state.dart';
// import '../services/auth_service.dart'; // COMMENTED OUT FOR DEVELOPMENT

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _carController;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _carAnimation;
  late Animation<double> _fadeAnimation;
  // final AuthService _authService = AuthService(); // COMMENTED OUT FOR DEVELOPMENT

  @override
  void initState() {
    super.initState();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize animations
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _carController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _carAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0.0),
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _carController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _carController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    // Start animations
    _carController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _logoController.forward();
      }
    });

    // Navigate after animation (shorter delay for tests)
    const delay = kDebugMode ? Duration(milliseconds: 100) : Duration(seconds: 4);
    Future.delayed(delay, () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    try {
      // Check if user is logged in using AppState
      final appState = Provider.of<AppState>(context, listen: false);
      final isLoggedIn = appState.isLoggedIn;

      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      // Fallback to login screen
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwiftLyftTheme.pureBlack,
      body: Stack(
        children: [
          // Modern gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SwiftLyftTheme.gradientStart,
                  SwiftLyftTheme.gradientEnd,
                  SwiftLyftTheme.pureBlack,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          
          // Animated background elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: SwiftLyftTheme.accentPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: SwiftLyftTheme.secondaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // City skyline silhouette
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: ModernSkylinePainter(),
              size: Size(MediaQuery.of(context).size.width, 200),
            ),
          ),
          
          // Animated car
          Positioned(
            bottom: 120,
            child: SlideTransition(
              position: _carAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 120,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [SwiftLyftTheme.warmOrange, SwiftLyftTheme.warmGradientEnd],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SwiftLyftTheme.warmOrange.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: SwiftLyftTheme.pureWhite,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          
          // Logo and tagline
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ScaleTransition(
                  scale: _logoAnimation,
                  child: FadeTransition(
                    opacity: _logoAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [SwiftLyftTheme.warmOrange, SwiftLyftTheme.warmGradientEnd],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SwiftLyftTheme.warmOrange.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_taxi,
                        size: 60,
                        color: SwiftLyftTheme.pureWhite,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // App name
                FadeTransition(
                  opacity: _logoAnimation,
                  child: const Text(
                    'SwiftLyft',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.pureWhite,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Tagline
                FadeTransition(
                  opacity: _logoAnimation,
                  child: Text(
                    'Your Journey, Elevated',
                    style: TextStyle(
                      fontSize: 16,
                      color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: TextButton(
              onPressed: () {
                _navigateToNextScreen();
              },
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: SwiftLyftTheme.pureWhite,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModernSkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SwiftLyftTheme.pureBlack.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create a modern skyline silhouette
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.05, size.height * 0.7);
    path.lineTo(size.width * 0.1, size.height * 0.85);
    path.lineTo(size.width * 0.15, size.height * 0.6);
    path.lineTo(size.width * 0.2, size.height * 0.75);
    path.lineTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.65);
    path.lineTo(size.width * 0.35, size.height * 0.4);
    path.lineTo(size.width * 0.4, size.height * 0.55);
    path.lineTo(size.width * 0.45, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.45);
    path.lineTo(size.width * 0.55, size.height * 0.25);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.65, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.35);
    path.lineTo(size.width * 0.75, size.height * 0.15);
    path.lineTo(size.width * 0.8, size.height * 0.3);
    path.lineTo(size.width * 0.85, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.25);
    path.lineTo(size.width * 0.95, size.height * 0.05);
    path.lineTo(size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 