import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_api_service.dart';

/// Settings state management
class SettingsState extends ChangeNotifier {
  final AnalyticsService _analyticsService;

  SettingsState(this._analyticsService) {
    // Initialize synchronously for immediate availability
    _isInitialized = true;
    // Load settings asynchronously in background
    _loadSettings();
  }

  // State
  bool _isDarkMode = false;
  String _currentLanguage = 'en';
  bool _isInitialized = true; // Start as initialized

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _currentLanguage = prefs.getString('current_language') ?? 'en';

      // Notify listeners after loading settings from storage
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      // Keep defaults if loading fails - no need to notify since already initialized
    }
  }

  Future<bool> toggleDarkMode() async {
    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _isDarkMode);

      // Track theme change
      await _analyticsService.trackEvent(
        eventType: 'theme_changed',
        eventData: {'dark_mode': _isDarkMode},
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to toggle dark mode: $e');

      // Revert on failure
      _isDarkMode = !_isDarkMode;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setLanguage(String language) async {
    try {
      _currentLanguage = language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_language', language);

      // Track language change
      await _analyticsService.trackEvent(
        eventType: 'language_changed',
        eventData: {'language': language},
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to set language: $e');

      // Revert on failure
      _currentLanguage = 'en'; // fallback
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetSettings() async {
    try {
      _isDarkMode = false;
      _currentLanguage = 'en';

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_dark_mode');
      await prefs.remove('current_language');

      // Track settings reset
      await _analyticsService.trackEvent(
        eventType: 'settings_reset',
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to reset settings: $e');
      return false;
    }
  }
}
