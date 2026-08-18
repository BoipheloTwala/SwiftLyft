import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/auth.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _apiClient = ApiClient();
    _setupTokenRefreshCallback();
  }

  late final ApiClient _apiClient;
  SharedPreferences? _prefs;
  User? _currentUser;
  AuthTokens? _tokens;

  void _setupTokenRefreshCallback() {
    _apiClient.setTokenRefreshCallback(_refreshTokenInternal);
  }

  Future<String?> _refreshTokenInternal() async {
    try {
      if (_tokens?.refreshToken == null) {
        return null;
      }
      final response = await _apiClient.post(
        '${AppConstants.baseUrl}/api/auth/refresh-token',
        body: {'refreshToken': _tokens?.refreshToken},
      );

      final data = jsonDecode(response.body);
      // Backend returns { success, message, data: { tokens: { accessToken, refreshToken? } } }
      final newAccessToken = data['data']?['tokens']?['accessToken'] as String?;

      if (newAccessToken != null) {
        _tokens = AuthTokens(
          accessToken: newAccessToken,
          refreshToken: _tokens!.refreshToken,
        );
        _apiClient.setTokens(newAccessToken, _tokens!.refreshToken);
        await _saveAuthData();
      }

      return newAccessToken;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return null;
    }
  }

  bool get isLoggedIn => _currentUser != null && _tokens != null;
  User? get currentUser => _currentUser;
  AuthTokens? get tokens => _tokens;

  // Initialize authentication service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Load stored tokens and user data
      await _loadStoredAuthData();

      // Validate tokens if they exist
      if (_tokens != null) {
        try {
          await validateSession();
        } catch (e) {
          // Tokens invalid, clear them
          await logout();
        }
      }
    } catch (e) {
      debugPrint('AuthService initialization failed: $e');
      // Continue with limited functionality
    }
  }

  // Register a new user
  Future<User?> register({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? referralCode,
    bool isCorporate = false,
    String? companyName,
    String? companyEmail,
    String? contactPerson,
    double? monthlyBudget,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/auth/register';

      final response = await _apiClient.post(url, body: {
        'email': email,
        'password': password,
        'name': name,
        'phoneNumber': phoneNumber,
        if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
        if (isCorporate) 'isCorporate': true,
        if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
        if (companyEmail != null && companyEmail.isNotEmpty) 'companyEmail': companyEmail,
        if (contactPerson != null && contactPerson.isNotEmpty) 'contactPerson': contactPerson,
        if (monthlyBudget != null) 'monthlyBudget': monthlyBudget,
      });

      debugPrint('📦 Registration response received, parsing...');
      
      final data = jsonDecode(response.body);
      debugPrint('📦 JSON decoded successfully');
      
      try {
        debugPrint('📦 Attempting to parse AuthResponse...');
        debugPrint('📦 Data structure: ${data.runtimeType}');
        debugPrint('📦 Has "data" key: ${data.containsKey("data")}');
        debugPrint('📦 Has "success" key: ${data.containsKey("success")}');
        
        final authResponse = AuthResponse.fromJson(data);
        debugPrint('📦 AuthResponse parsed successfully');
      } catch (parseError) {
        debugPrint('❌ PARSE ERROR: $parseError');
        debugPrint('❌ Parse error type: ${parseError.runtimeType}');
        debugPrint('❌ Full response: ${response.body.substring(0, 500)}...');
        rethrow;
      }
      
      final authResponse = AuthResponse.fromJson(data);
      debugPrint('📦 AuthResponse parsed successfully');

      // Set tokens
      _tokens = authResponse.data.tokens;
      _apiClient.setTokens(_tokens!.accessToken, _tokens!.refreshToken);
      debugPrint('📦 Tokens set successfully');

      // Set current user
      _currentUser = authResponse.data.user;
      debugPrint('📦 Current user set: ${_currentUser?.email}');

      // Save to storage
      await _saveAuthData();
      debugPrint('📦 Auth data saved successfully');

      return _currentUser;
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      throw _handleAuthError(e);
    }
  }

  // Login with email and password
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/auth/login';
      // Ensure no stale Authorization header is sent during login
      final prevAccess = _apiClient.accessToken;
      final prevRefresh = _apiClient.refreshToken;
      _apiClient.clearTokens();

      final response = await _apiClient.post(url, body: {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      // Set tokens
      _tokens = authResponse.data.tokens;
      _apiClient.setTokens(_tokens!.accessToken, _tokens!.refreshToken);

      // Set current user
      _currentUser = authResponse.data.user;

      // Save to storage
      await _saveAuthData();

      return _currentUser;
    } catch (e) {
      // Restore previous tokens if login failed
      if (_apiClient.accessToken == null && _apiClient.refreshToken == null && _tokens != null) {
        _apiClient.setTokens(_tokens?.accessToken, _tokens?.refreshToken);
      }
      throw _handleAuthError(e);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint to invalidate server-side tokens
      const url = '${AppConstants.baseUrl}/api/auth/logout';
      await _apiClient.post(url);

      // Clear local data
      await _clearAuthData();
    } catch (e) {
      // Even if server logout fails, clear local data
      await _clearAuthData();
      debugPrint('Server logout failed: $e');
    }
  }

  // Refresh access token
  Future<void> refreshToken() async {
    try {
      if (_tokens?.refreshToken == null) {
        throw Exception('No refresh token available');
      }

      const url = '${AppConstants.baseUrl}/api/auth/refresh';
      final response = await _apiClient.post(url, body: {
        'refreshToken': _tokens!.refreshToken,
      });

      final data = jsonDecode(response.body);
      final refreshResponse = RefreshTokenResponse.fromJson(data);

      // Update tokens
      _tokens = AuthTokens(
        accessToken: refreshResponse.accessToken,
        refreshToken: _tokens!.refreshToken, // Keep existing refresh token
      );

      _apiClient.setTokens(_tokens!.accessToken, _tokens!.refreshToken);

      // Save updated tokens
      await _saveAuthData();
    } catch (e) {
      // Refresh failed, logout user
      await _clearAuthData();
      throw Exception('Token refresh failed: $e');
    }
  }

  // Validate current session
  Future<bool> validateSession() async {
    try {
      const url = '${AppConstants.baseUrl}/api/auth/me';
      await _apiClient.get(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      const url = '${AppConstants.baseUrl}/api/auth/forgot-password';
      await _apiClient.post(url, body: {'email': email});
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update user profile
  Future<User?> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/users/profile';
      final response = await _apiClient.put(url, body: {
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });

      final data = jsonDecode(response.body);
      _currentUser = User.fromJson(data['data']['user']);

      // Update stored user data
      await _saveAuthData();

      return _currentUser;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Load stored authentication data
  Future<void> _loadStoredAuthData() async {
    try {
      final tokensJson = _prefs?.getString('auth_tokens');
      final userJson = _prefs?.getString('user_data');

      if (tokensJson != null) {
        final tokensData = json.decode(tokensJson);
        _tokens = AuthTokens.fromJson(tokensData);
        _apiClient.setTokens(_tokens!.accessToken, _tokens!.refreshToken);
      }

      if (userJson != null) {
        final userData = json.decode(userJson);
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Failed to load stored auth data: $e');
      _tokens = null;
      _currentUser = null;
    }
  }

  // Save authentication data to storage
  Future<void> _saveAuthData() async {
    try {
      if (_tokens != null) {
        final tokensJson = json.encode(_tokens!.toJson());
        await _prefs?.setString('auth_tokens', tokensJson);
      }

      if (_currentUser != null) {
        final userJson = json.encode(_currentUser!.toJson());
        await _prefs?.setString('user_data', userJson);
      }
    } catch (e) {
      debugPrint('Failed to save auth data: $e');
    }
  }

  // Clear authentication data
  Future<void> _clearAuthData() async {
    try {
      await _prefs?.remove('auth_tokens');
      await _prefs?.remove('user_data');

      _tokens = null;
      _currentUser = null;
      _apiClient.clearTokens();

      // Note: Payment methods are now user-specific and persist across logins
      // They are stored with user-specific keys like 'local_payment_methods_{userId}'
    } catch (e) {
      debugPrint('Failed to clear auth data: $e');
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    if (!isLoggedIn) return false;
    return await validateSession();
  }

  // Handle authentication errors
  Exception _handleAuthError(dynamic error) {
    String message = 'Authentication failed';

    if (error is ApiException) {
      message = error.message;
    } else if (error.toString().contains('network')) {
      message = 'Network error. Please check your connection';
    } else if (error.toString().contains('timeout')) {
      message = 'Request timeout. Please try again';
    } else if (error.toString().contains('401')) {
      message = 'Invalid email or password';
    } else if (error.toString().contains('409')) {
      message = 'Email already exists';
    } else if (error.toString().contains('422')) {
      message = 'Invalid input data';
    }

    return Exception(message);
  }
} 