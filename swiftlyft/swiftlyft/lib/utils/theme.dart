import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SwiftLyftTheme {
  // Modern Color Palette - Fresh & Contemporary
  static const Color primaryBlue = Color(0xFF2563EB);      // Modern blue
  static const Color secondaryTeal = Color(0xFF0D9488);    // Teal accent
  static const Color accentPurple = Color(0xFF7C3AED);     // Purple accent
  static const Color warmOrange = Color(0xFFF59E0B);       // Warm orange
  static const Color successGreen = Color(0xFF10B981);     // Success green
  static const Color errorRed = Color(0xFFEF4444);         // Error red
  
  // Neutral Colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color mediumGray = Color(0xFF64748B);
  static const Color darkGray = Color(0xFF334155);
  static const Color deepCharcoal = Color(0xFF1E293B);
  static const Color pureBlack = Color(0xFF0F172A);
  
  // Gradient Colors
  static const Color gradientStart = Color(0xFF2563EB);
  static const Color gradientEnd = Color(0xFF7C3AED);
  static const Color warmGradientStart = Color(0xFFF59E0B);
  static const Color warmGradientEnd = Color(0xFFEF4444);

  // Web-specific responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  // Responsive utilities
  static bool get isWeb => kIsWeb;
  
  // Responsive sizing utilities
  static double getResponsiveFontSize(BuildContext context, {double mobile = 14, double tablet = 16, double desktop = 18}) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return mobile;
    if (width < tabletBreakpoint) return tablet;
    return desktop;
  }

  static double getResponsivePadding(BuildContext context, {double mobile = 16, double tablet = 24, double desktop = 32}) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return mobile;
    if (width < tabletBreakpoint) return tablet;
    return desktop;
  }

  static double getResponsiveSpacing(BuildContext context, {double mobile = 16, double tablet = 24, double desktop = 32}) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return mobile;
    if (width < tabletBreakpoint) return tablet;
    return desktop;
  }

  // Web-specific container constraints
  static BoxConstraints getWebContainerConstraints(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return const BoxConstraints(maxWidth: double.infinity);
    } else if (width < tabletBreakpoint) {
      return const BoxConstraints(maxWidth: 600);
    } else if (width < desktopBreakpoint) {
      return const BoxConstraints(maxWidth: 900);
    } else {
      return const BoxConstraints(maxWidth: 1200);
    }
  }

  // Web-specific card elevation
  static double getWebCardElevation(BuildContext context) {
    if (isWeb) {
      final width = MediaQuery.of(context).size.width;
      if (width >= desktopBreakpoint) return 8;
      if (width >= tabletBreakpoint) return 6;
      return 4;
    }
    return 4;
  }

  // Web-specific card elevation without context (for theme)
  static double getWebCardElevationForTheme() {
    if (isWeb) {
      return 4; // Default elevation for theme
    }
    return 4;
  }

  // Responsive breakpoint checks
  static bool isMobile(BuildContext context) {
    return !isWeb || MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    return isWeb && MediaQuery.of(context).size.width >= mobileBreakpoint && 
           MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return isWeb && MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Responsive layout wrapper for web
  static Widget getResponsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (!isWeb) {
      return mobile;
    }
    
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= tabletBreakpoint) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryTeal,
        tertiary: accentPurple,
        surface: lightGray,
        error: Color(0xFFEF4444),
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onSurface: deepCharcoal,
        onError: pureWhite,
      ),
      textTheme: _getTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: pureWhite,
        foregroundColor: deepCharcoal,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _getTextTheme().titleLarge?.copyWith(
          color: deepCharcoal,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: deepCharcoal),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: getWebCardElevationForTheme(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: pureWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: _getTextTheme().labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: _getTextTheme().labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: _getTextTheme().labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: _getTextTheme().bodyMedium?.copyWith(
          color: mediumGray,
        ),
        hintStyle: _getTextTheme().bodyMedium?.copyWith(
          color: mediumGray,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: mediumGray,
        indicatorColor: primaryBlue,
        labelStyle: _getTextTheme().labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: _getTextTheme().labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pureWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: lightGray,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightGray,
        selectedColor: primaryBlue,
        disabledColor: lightGray,
        labelStyle: _getTextTheme().labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryTeal,
        tertiary: accentPurple,
        surface: deepCharcoal,
        error: Color(0xFFEF4444),
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onSurface: pureWhite,
        onError: pureWhite,
      ),
      textTheme: _getTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: deepCharcoal,
        foregroundColor: pureWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _getTextTheme().titleLarge?.copyWith(
          color: pureWhite,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: pureWhite),
      ),
      cardTheme: CardThemeData(
        color: darkGray,
        elevation: getWebCardElevationForTheme(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: pureWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: _getTextTheme().labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: _getTextTheme().labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: _getTextTheme().labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: _getTextTheme().bodyMedium?.copyWith(
          color: mediumGray,
        ),
        hintStyle: _getTextTheme().bodyMedium?.copyWith(
          color: mediumGray,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: mediumGray,
        indicatorColor: primaryBlue,
        labelStyle: _getTextTheme().labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: _getTextTheme().labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: deepCharcoal,
        selectedItemColor: primaryBlue,
        unselectedItemColor: mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: darkGray,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkGray,
        selectedColor: primaryBlue,
        disabledColor: darkGray,
        labelStyle: _getTextTheme().labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Get text theme with proper font fallbacks
  static TextTheme _getTextTheme() {
    try {
      // Try to use Google Fonts Inter with fallbacks
      return GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          height: 1.12,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.16,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.22,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.29,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.33,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.27,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.43,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.33,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.33,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.45,
        ),
      );
    } catch (e) {
      // Fallback to system fonts if Google Fonts fails
      return const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          height: 1.12,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.16,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.22,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.25,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.29,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.33,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.27,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          height: 1.5,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.43,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.43,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.33,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.43,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.33,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.45,
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ),
      );
    }
  }
}

// Responsive layout wrapper for web
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return SwiftLyftTheme.getResponsiveLayout(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

// Web-specific container wrapper
class WebContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const WebContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (!SwiftLyftTheme.isWeb) {
      return child;
    }

    // Don't apply center constraints when using web navigation
    final isDesktop = SwiftLyftTheme.isDesktop(context);
    if (isDesktop) {
      return Container(
        padding: padding,
        margin: margin,
        child: child,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: SwiftLyftTheme.getWebContainerConstraints(context),
        child: Container(
          padding: padding,
          margin: margin,
          child: child,
        ),
      ),
    );
  }
}