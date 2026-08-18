import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/analytics_api_service.dart';

/// Authentication state management
class AuthState extends ChangeNotifier {
  final AuthService _authService;
  final AnalyticsService _analyticsService;

  AuthState(this._authService, this._analyticsService) {
    _initialize();
  }

  // State
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<void> _initialize() async {
    try {
      // Check if user is already logged in (from persistent storage)
      if (_authService.isLoggedIn) {
        _currentUser = _authService.currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
  }

  // Test-only method to set user state
  void setTestUser(User user) {
    _currentUser = user;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(email: email, password: password);
      if (user != null) {
        _currentUser = user;

        // Track sign in event (fire and forget to avoid blocking sign-in)
        _analyticsService.trackEvent(
          eventType: 'user_sign_in',
          eventData: {'method': 'email'},
        ).catchError((e) => debugPrint('Sign-in analytics failed: $e'));

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid credentials');
      }
    } catch (e) {
      final errStr = e.toString();
      final is401 = errStr.contains('401') || errStr.contains('Invalid email or password');
      final errorMessage = is401 ? 'Invalid email or password' : 'Sign in failed: $e';
      _setError(errorMessage);

      // Track failed sign in (fire and forget)
      _analyticsService.trackEvent(
        eventType: 'user_sign_in_failed',
        eventData: {'error': errorMessage},
      ).catchError((e) => debugPrint('Sign-in failure analytics failed: $e'));

      _currentUser = null; // ensure no stale user persists
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String? phoneNumber, {
    String? referralCode,
    bool isCorporate = false,
    String? companyName,
    String? companyEmail,
    String? contactPerson,
    double? monthlyBudget,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.register(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        referralCode: referralCode,
        isCorporate: isCorporate,
        companyName: companyName,
        companyEmail: companyEmail,
        contactPerson: contactPerson,
        monthlyBudget: monthlyBudget,
      );

      if (user != null) {
        _currentUser = user;

        // Track sign up event (non-blocking, don't fail registration if this fails)
        try {
          await _analyticsService.trackEvent(
            eventType: 'user_sign_up',
            eventData: {'method': 'email'},
          );
        } catch (analyticsError) {
          debugPrint('Analytics tracking failed (non-critical): $analyticsError');
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      debugPrint('Sign up error: $e');
      final errorMessage = 'Sign up failed: $e';
      _setError(errorMessage);

      // Track failed sign up (non-blocking)
      try {
        await _analyticsService.trackEvent(
          eventType: 'user_sign_up_failed',
          eventData: {'error': errorMessage},
        );
      } catch (analyticsError) {
        debugPrint('Analytics tracking failed (non-critical): $analyticsError');
      }

      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signOut() async {
    try {
      await _authService.logout();
      _currentUser = null;

      // Track sign out event
      await _analyticsService.trackEvent(
        eventType: 'user_sign_out',
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign out error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.requestPasswordReset(email);

      // Track password reset request
      await _analyticsService.trackEvent(
        eventType: 'password_reset_requested',
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      final errorMessage = 'Password reset failed: $e';
      _setError(errorMessage);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }
}
