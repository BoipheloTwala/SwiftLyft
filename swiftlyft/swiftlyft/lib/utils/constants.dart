// App-wide constants to reduce code duplication and improve maintainability
class AppConstants {
  // Development Mode
  static const bool isDevelopmentMode = true; // Set to false for production
  
  // API Configuration
  static const String baseUrl = 'https://swiftlyft-frontend.onrender.com';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Configuration
  static const int cacheExpiryHours = 24;
  static const int imageCacheExpiryDays = 7;
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  
  // File Upload
  static const int maxImageSizeMB = 5;
  static const int maxFileSizeMB = 10;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedFileTypes = ['pdf', 'doc', 'docx'];
  
  // Rate Limiting
  static const int maxRequestsPerMinute = 60;
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  
  // UI Constants
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unexpected error occurred.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  
  // Success Messages
  static const String bookingSuccessMessage = 'Booking created successfully!';
  static const String profileUpdateMessage = 'Profile updated successfully!';
  static const String passwordChangeMessage = 'Password changed successfully!';
  
  // Default Values
  static const String defaultCurrency = 'ZAR';
  static const String defaultLanguage = 'en';
  static const String defaultCountry = 'ZA';
  static const String defaultTimeZone = 'Africa/Johannesburg';
}

// Route names for consistent navigation
class RouteNames {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String vehicleListing = '/vehicle-listing';
  static const String vehicleDetails = '/vehicle-details';
  static const String quoteRequest = '/quote-request';
  static const String tripHistory = '/trip-history';
  static const String support = '/support';
  static const String aboutUs = '/about-us';
  static const String specialOffers = '/special-offers';
  static const String contact = '/contact';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String paymentMethods = '/payment-methods';
  static const String profile = '/profile';
}

// Asset paths for consistent image loading
class AssetPaths {
  static const String images = 'assets/images/';
  static const String icons = 'assets/icons/';
  static const String logos = 'assets/logos/';
  
  // Vehicle images
  static const String vehiclePlaceholder = '${images}vehicle_placeholder.jpg';
  static const String mercedesSClass = '${images}mercedes_s_class.jpg';
  static const String bmw7Series = '${images}bmw_7_series.jpg';
  
  // Icons
  static const String appIcon = '${icons}app_icon.png';
  static const String logoIcon = '${icons}logo_icon.png';
}

// Database keys for consistent storage
class StorageKeys {
  // User preferences
  static const String isDarkMode = 'isDarkMode';
  static const String currentLanguage = 'currentLanguage';
  static const String selectedCity = 'selectedCity';
  static const String searchQuery = 'searchQuery';
  static const String selectedFilter = 'selectedFilter';
  static const String advancedFilters = 'advancedFilters';
  
  // User data
  static const String user = 'user';
  static const String userBackup = 'user_backup';
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  
  // Cache data
  static const String cachedVehicles = 'cached_vehicles';
  static const String cachedBookings = 'cached_bookings';
  static const String cachedFavorites = 'cached_favorites';
  static const String searchHistory = 'search_history';
  
  // Settings
  static const String notificationsEnabled = 'notificationsEnabled';
  static const String emailNotifications = 'emailNotifications';
  static const String pushNotifications = 'pushNotifications';
  static const String whatsappNotifications = 'whatsappNotifications';
  static const String locationEnabled = 'locationEnabled';
  static const String twoFactorEnabled = 'twoFactorEnabled';
  
  // Analytics
  static const String analyticsEvents = 'analytics_events';
  static const String userProperties = 'user_properties';
}

// Validation patterns for consistent input validation
class ValidationPatterns {
  static final RegExp emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp phonePattern = RegExp(
    r'^(?:\+27\d{9}|0[6-8]\d{8})$',
  );
  
  static final RegExp passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
  );
  
  static final RegExp namePattern = RegExp(
    r"^[a-zA-Z\s'\-]{2,50}$",
  );
  
  static final RegExp creditCardPattern = RegExp(
    r'^[0-9]{13,19}$',
  );
  
  static final RegExp cvvPattern = RegExp(
    r'^[0-9]{3,4}$',
  );
  
  static final RegExp expiryDatePattern = RegExp(
    r'^(0[1-9]|1[0-2])\/([0-9]{2})$',
  );
} 