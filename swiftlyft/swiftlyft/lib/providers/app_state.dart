import 'package:flutter/foundation.dart';

// Import models
import '../models/coordinates.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../models/vehicle.dart';
import '../models/notification.dart';
import '../models/quote.dart';
import '../models/payment.dart';
import '../models/support.dart';
import '../models/loyalty.dart';
import '../models/referral.dart';
import '../models/driver.dart';
import '../models/corporate.dart';
import '../models/user_stats.dart';
import '../models/reward.dart';
import '../models/bulk_booking.dart';

// Import all the individual state managers
import 'auth_state.dart';
import 'vehicle_state.dart';
import 'booking_state.dart';
import 'payment_state.dart';
import 'notification_state.dart';
import 'quote_state.dart';
import 'support_state.dart';
import 'settings_state.dart';

// Import services
import '../services/auth_service.dart';
import '../services/analytics_api_service.dart';
import '../services/vehicle_api_service.dart';
import '../services/booking_api_service.dart';
import '../services/user_api_service.dart';
import '../services/quote_api_service.dart';
import '../services/notification_api_service.dart';
import '../services/support_api_service.dart';
import '../services/payment_api_service.dart';

/// Main application state that coordinates all individual state managers
class AppState extends ChangeNotifier {
  // Services
  final AuthService _authService = AuthService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final VehicleService _vehicleService = VehicleService();
  final BookingService _bookingService = BookingService();
  final UserService _userService = UserService();
  final QuoteService _quoteService = QuoteService();
  final NotificationService _notificationService = NotificationService();
  final SupportService _supportService = SupportService();
  final PaymentService _paymentService = PaymentService();

  // State managers
  late final AuthState auth;
  late final VehicleState vehicles;
  late final BookingState bookings;
  late final PaymentState payments;
  late final NotificationState notifications;
  late final QuoteState quotes;
  late final SupportState support;
  late final SettingsState settings;


  // Loyalty state
  LoyaltyInfo? _loyaltyInfo;
  bool _isLoadingLoyalty = false;
  String? _loyaltyError;
  ReferralInfo? _referralInfo;
  bool _isLoadingReferral = false;
  String? _referralError;

  // Corporate state
  CorporateInfo? _corporateInfo;
  bool _isLoadingCorporate = false;
  String? _corporateError;

  // User stats state
  UserStatistics? _userStats;
  bool _isLoadingStats = false;
  String? _statsError;

  // Rewards state
  RewardsInfo? _rewardsInfo;
  bool _isLoadingRewards = false;
  String? _rewardsError;

  // Bulk bookings state
  BulkBookingsResponse? _bulkBookingsResponse;
  bool _isLoadingBulkBookings = false;
  String? _bulkBookingsError;
  String? _bulkBookingsStatusFilter;
  int _bulkBookingsPage = 1;

  // Constructor
  AppState() {
    // Initialize state managers with their required services
    auth = AuthState(_authService, _analyticsService);
    // Propagate auth changes to AppState listeners so UI rebuilds
    auth.addListener(notifyListeners);
    vehicles = VehicleState(_vehicleService, _analyticsService);
    bookings = BookingState(_bookingService, _userService, _analyticsService);
    // Propagate booking changes so Trip History and related UIs rebuild
    bookings.addListener(notifyListeners);
    payments = PaymentState(_paymentService, _analyticsService, () => auth.currentUser?.id);
    // Propagate payment changes so Payment Methods and related UIs rebuild
    payments.addListener(notifyListeners);
    notifications = NotificationState(_notificationService, _analyticsService);
    quotes = QuoteState(_quoteService, _analyticsService, () => auth.currentUser?.id ?? '');
    support = SupportState(_supportService, _analyticsService);
    settings = SettingsState(_analyticsService);

    _initialize();
  }

  @override
  void dispose() {
    // Clean up listeners
    auth.removeListener(notifyListeners);
    bookings.removeListener(notifyListeners);
    payments.removeListener(notifyListeners);
    super.dispose();
  }

  /// Initialize the app state after authentication
  Future<void> _initialize() async {
    try {
      // Settings are now initialized synchronously, so we can proceed immediately
      // If user is logged in, initialize user-dependent services
      if (auth.isLoggedIn) {
        await _initializeUserData();
      }
    } catch (e) {
      debugPrint('AppState initialization error: $e');
    }
  }

  /// Initialize user-specific data after login
  Future<void> _initializeUserData() async {
    try {
      await Future.wait([
        vehicles.loadVehicles(),
        bookings.loadBookings(),
        payments.loadPaymentMethods(),
        notifications.loadNotifications(),
        loadLoyalty(),
        loadReferral(),
        loadCorporate(),
        loadStats(),
        loadRewards(),
      ]);
    } catch (e) {
      debugPrint('Failed to initialize user data: $e');
    }
  }

  /// Handle user sign in - initialize user data
  Future<void> onSignIn() async {
    await _initializeUserData();
  }

  /// Handle user sign out - clear user data
  Future<void> onSignOut() async {
    // Clear user-specific data
    vehicles.clearError();
    bookings.clearError();
    payments.clearError();
    notifications.clearError();
    quotes.clearError();
    support.clearError();
    
    // Clear vehicle data to prevent stale data on next login
    vehicles.clearAllData();

    // Clear payment method data to prevent cross-user contamination
    payments.clearAllData();
    
    // Clear stats
    _userStats = null;
    _statsError = null;
    
    // Clear loyalty and referral data
    _loyaltyInfo = null;
    _loyaltyError = null;
    _referralInfo = null;
    _referralError = null;
    _corporateInfo = null;
    _corporateError = null;
    
    // Clear rewards data
    _rewardsInfo = null;
    _rewardsError = null;

    // Clear bulk bookings data
    _bulkBookingsResponse = null;
    _bulkBookingsError = null;
    _bulkBookingsStatusFilter = null;
    _bulkBookingsPage = 1;
    
    notifyListeners();
  }

  // ============================================================================
  // DELEGATED GETTERS - Access individual state managers through AppState
  // ============================================================================

  // Auth getters
  User? get currentUser => auth.currentUser;
  bool get isLoading => auth.isLoading;
  String? get error => auth.error;
  bool get isLoggedIn => auth.isLoggedIn;

  // Vehicle getters
  List<Vehicle> get allVehicles => vehicles.vehicles;
  List<Vehicle> get filteredVehicles => vehicles.filteredVehicles;
  bool get isLoadingVehicles => vehicles.isLoading;
  String? get vehicleError => vehicles.error;
  String get searchQuery => vehicles.searchQuery;
  List<String> get searchHistory => vehicles.searchHistory;
  String get selectedFilter => vehicles.selectedFilter;
  String get selectedCity => vehicles.selectedCity;
  Map<String, dynamic> get advancedFilters => vehicles.advancedFilters;

  // Booking getters
  List<Booking> get allBookings => bookings.bookings;
  List<Booking> get activeBookings => bookings.activeBookings;
  List<Booking> get completedBookings => bookings.completedBookings;
  bool get isLoadingBookings => bookings.isLoading;
  String? get bookingError => bookings.error;
  bool get hasMoreBookings => bookings.hasMore;
  bool get isLoadingMoreBookings => bookings.isLoadingMore;

  // Payment getters
  List<PaymentMethod> get paymentMethods => payments.paymentMethods;
  bool get isLoadingPaymentMethods => payments.isLoading;
  String? get paymentMethodsError => payments.error;

  // Notification getters
  List<NotificationModel> get allNotifications => notifications.notifications;
  bool get isLoadingNotifications => notifications.isLoading;
  String? get notificationsError => notifications.error;
  int get unreadNotificationCount => notifications.unreadNotificationCount;

  // Quote getters
  List<Quote> get allQuotes => quotes.quotes;
  bool get isLoadingQuotes => quotes.isLoading;
  String? get quoteError => quotes.error;

  // Support getters
  bool get isLoadingSupport => support.isLoading;
  String? get supportError => support.error;

  // Settings getters
  bool get isDarkMode => settings.isDarkMode;
  String get currentLanguage => settings.currentLanguage;

  // Loyalty getters
  LoyaltyInfo? get loyaltyInfo => _loyaltyInfo;
  bool get isLoadingLoyalty => _isLoadingLoyalty;
  String? get loyaltyError => _loyaltyError;

  Future<void> loadLoyalty() async {
    if (!auth.isLoggedIn) return;
    _isLoadingLoyalty = true;
    _loyaltyError = null;
    notifyListeners();
    try {
      _loyaltyInfo = await _userService.getLoyalty();
    } catch (e) {
      _loyaltyError = e.toString();
    } finally {
      _isLoadingLoyalty = false;
      notifyListeners();
    }
  }

  // Referral getters
  ReferralInfo? get referralInfo => _referralInfo;
  bool get isLoadingReferral => _isLoadingReferral;
  String? get referralError => _referralError;

  Future<void> loadReferral() async {
    if (!auth.isLoggedIn) return;
    _isLoadingReferral = true;
    _referralError = null;
    notifyListeners();
    try {
      _referralInfo = await _userService.getReferral();
    } catch (e) {
      _referralError = e.toString();
    } finally {
      _isLoadingReferral = false;
      notifyListeners();
    }
  }

  // Corporate getters and methods
  CorporateInfo? get corporateInfo => _corporateInfo;
  bool get isLoadingCorporate => _isLoadingCorporate;
  String? get corporateError => _corporateError;
  bool get isCorporateUser {
    // Primary check: if corporateInfo has been loaded successfully
    if (_corporateInfo != null) {
      return _corporateInfo!.corporateAccount.isActive;
    }
    
    // Fallback: check if current user object has corporateAccount field
    // This is used before corporateInfo is loaded
    if (auth.currentUser?.corporateAccount != null) {
      return auth.currentUser!.corporateAccount!.isActive;
    }
    
    // Default: user is not a corporate user
    return false;
  }

  Future<void> loadCorporate() async {
    if (!auth.isLoggedIn) return;
    _isLoadingCorporate = true;
    _corporateError = null;
    notifyListeners();
    try {
      _corporateInfo = await _userService.getCorporateInfo();
      // If getCorporateInfo returns null, user is a regular (non-corporate) user
      if (_corporateInfo == null) {
        debugPrint('ℹ️ Regular user account (not corporate)');
      } else {
        debugPrint('✅ Corporate account loaded');
      }
    } catch (e) {
      // If user doesn't have corporate account, set to null (this is expected)
      _corporateInfo = null;
      if (!e.toString().contains('404') && 
          !e.toString().contains('No corporate account found') &&
          !e.toString().contains('Resource not found')) {
        _corporateError = e.toString();
        debugPrint('❌ Unexpected error loading corporate info: $e');
      }
    } finally {
      _isLoadingCorporate = false;
      notifyListeners();
    }
  }

  /// Create a corporate booking (legacy method)
  /// @deprecated Use createBulkBooking(Map<String, dynamic>) instead
  Future<CorporateBooking> createCorporateBooking({
    required String title,
    String? description,
    required String bookingType,
    required List<Map<String, dynamic>> trips,
    String? specialInstructions,
  }) async {
    final booking = await _userService.createCorporateBooking(
      title: title,
      description: description,
      bookingType: bookingType,
      trips: trips,
      specialInstructions: specialInstructions,
    );
    // Reload corporate info to refresh bulk bookings
    await loadCorporate();
    return booking;
  }

  // User stats getters and methods
  UserStatistics? get userStats => _userStats;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  Future<void> loadStats() async {
    if (!auth.isLoggedIn) return;
    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();
    try {
      _userStats = await _userService.getStats();
    } catch (e) {
      _statsError = e.toString();
      debugPrint('Failed to load user stats: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // Rewards getters and methods
  RewardsInfo? get rewardsInfo => _rewardsInfo;
  bool get isLoadingRewards => _isLoadingRewards;
  String? get rewardsError => _rewardsError;

  Future<void> loadRewards() async {
    if (!auth.isLoggedIn || auth.currentUser == null) return;
    _isLoadingRewards = true;
    _rewardsError = null;
    notifyListeners();
    try {
      _rewardsInfo = await _userService.getRewards(auth.currentUser!.id);
    } catch (e) {
      _rewardsError = e.toString();
      debugPrint('Failed to load user rewards: $e');
    } finally {
      _isLoadingRewards = false;
      notifyListeners();
    }
  }

  // Bulk bookings getters and methods
  BulkBookingsResponse? get bulkBookingsResponse => _bulkBookingsResponse;
  bool get isLoadingBulkBookings => _isLoadingBulkBookings;
  String? get bulkBookingsError => _bulkBookingsError;
  List<BulkBooking> get bulkBookings => _bulkBookingsResponse?.bulkBookings ?? [];
  BulkBookingSummary? get bulkBookingsSummary => _bulkBookingsResponse?.summary;
  BulkBookingPagination? get bulkBookingsPagination => _bulkBookingsResponse?.pagination;
  String? get bulkBookingsStatusFilter => _bulkBookingsStatusFilter;
  int get bulkBookingsPage => _bulkBookingsPage;

  Future<void> loadBulkBookings({
    String? status,
    int? page,
    int limit = 10,
  }) async {
    if (!auth.isLoggedIn || auth.currentUser == null) return;

    // Update filter and page
    if (status != null) _bulkBookingsStatusFilter = status;
    if (page != null) _bulkBookingsPage = page;

    _isLoadingBulkBookings = true;
    _bulkBookingsError = null;
    notifyListeners();
    
    try {
      _bulkBookingsResponse = await _userService.getBulkBookings(
        auth.currentUser!.id,
        status: _bulkBookingsStatusFilter,
        page: _bulkBookingsPage,
        limit: limit,
      );
    } catch (e) {
      // If user doesn't have corporate account, that's not an error
      final errorString = e.toString();
      if (errorString.contains('404') || 
          errorString.contains('No corporate account found') ||
          errorString.contains('Corporate account required')) {
        debugPrint('User does not have access to bulk bookings (not a corporate user)');
        _bulkBookingsResponse = null;
      } else {
        _bulkBookingsError = errorString;
        debugPrint('Failed to load bulk bookings: $e');
      }
    } finally {
      _isLoadingBulkBookings = false;
      notifyListeners();
    }
  }

  Future<void> refreshBulkBookings({bool preserveFilter = true}) async {
    _bulkBookingsPage = 1;
    await loadBulkBookings(
      status: preserveFilter ? _bulkBookingsStatusFilter : null,
      page: 1,
    );
  }

  void clearBulkBookingsFilter() {
    _bulkBookingsStatusFilter = null;
    _bulkBookingsPage = 1;
    notifyListeners();
  }

  Future<BulkBooking> createBulkBooking(Map<String, dynamic> bookingData) async {
    if (!auth.isLoggedIn || auth.currentUser == null) {
      throw Exception('User not logged in');
    }
    
    try {
      final booking = await _userService.createBulkBooking(
        auth.currentUser!.id,
        bookingData,
      );
      return booking;
    } catch (e) {
      debugPrint('Failed to create bulk booking: $e');
      rethrow;
    }
  }

  Future<BulkBooking> updateBulkBooking(
    String bookingId,
    Map<String, dynamic> bookingData,
  ) async {
    if (!auth.isLoggedIn || auth.currentUser == null) {
      throw Exception('User not logged in');
    }
    
    try {
      final booking = await _userService.updateBulkBooking(
        auth.currentUser!.id,
        bookingId,
        bookingData,
      );
      
      // Update local state with the updated booking (if it exists in state)
      if (_bulkBookingsResponse != null && 
          _bulkBookingsResponse!.bulkBookings.any((b) => b.id == bookingId)) {
        updateBulkBookingInState(bookingId, booking);
      }
      
      return booking;
    } catch (e) {
      // If update fails, refresh to restore correct state
      await refreshBulkBookings(preserveFilter: true);
      debugPrint('Failed to update bulk booking: $e');
      rethrow;
    }
  }

  Future<void> cancelBulkBooking(String bookingId) async {
    if (!auth.isLoggedIn || auth.currentUser == null) {
      throw Exception('User not logged in');
    }
    
    try {
      // Optimistically remove from local state for instant UI update
      removeBulkBooking(bookingId);
      
      await _userService.cancelBulkBooking(
        auth.currentUser!.id,
        bookingId,
      );
    } catch (e) {
      // If deletion fails, refresh to restore correct state
      await refreshBulkBookings(preserveFilter: true);
      debugPrint('Failed to cancel bulk booking: $e');
      rethrow;
    }
  }

  /// Remove bulk booking from local state (for optimistic UI updates)
  /// Also updates summary stats to reflect the deletion
  void removeBulkBooking(String bookingId) {
    if (_bulkBookingsResponse != null) {
      // Check if booking exists
      if (!_bulkBookingsResponse!.bulkBookings.any((b) => b.id == bookingId)) {
        // Booking not found, just remove from list without updating stats
        final updatedBookings = _bulkBookingsResponse!.bulkBookings
            .where((booking) => booking.id != bookingId)
            .toList();
        _bulkBookingsResponse = BulkBookingsResponse(
          bulkBookings: updatedBookings,
          pagination: _bulkBookingsResponse!.pagination,
          summary: _bulkBookingsResponse!.summary,
        );
        notifyListeners();
        return;
      }
      
      // Get the booking to remove for stats calculation
      final bookingToRemove = _bulkBookingsResponse!.bulkBookings
          .firstWhere((booking) => booking.id == bookingId);
      
      final updatedBookings = _bulkBookingsResponse!.bulkBookings
          .where((booking) => booking.id != bookingId)
          .toList();
      
      // Update summary stats
      final oldSummary = _bulkBookingsResponse!.summary;
      final oldStatusCounts = oldSummary.statusCounts;
      
      // Decrease status count based on removed booking's status
      int newDraft = oldStatusCounts.draft;
      int newPending = oldStatusCounts.pending;
      int newConfirmed = oldStatusCounts.confirmed;
      int newCompleted = oldStatusCounts.completed;
      int newCancelled = oldStatusCounts.cancelled;
      
      switch (bookingToRemove.status) {
        case BulkBookingStatus.draft:
          newDraft = (newDraft - 1).clamp(0, double.infinity).toInt();
          break;
        case BulkBookingStatus.pending:
          newPending = (newPending - 1).clamp(0, double.infinity).toInt();
          break;
        case BulkBookingStatus.confirmed:
          newConfirmed = (newConfirmed - 1).clamp(0, double.infinity).toInt();
          break;
        case BulkBookingStatus.completed:
          newCompleted = (newCompleted - 1).clamp(0, double.infinity).toInt();
          break;
        case BulkBookingStatus.cancelled:
          newCancelled = (newCancelled - 1).clamp(0, double.infinity).toInt();
          break;
      }
      
      final updatedStatusCounts = BulkBookingStatusCounts(
        draft: newDraft,
        pending: newPending,
        confirmed: newConfirmed,
        completed: newCompleted,
        cancelled: newCancelled,
      );
      
      // Decrease total amount and discount
      final newTotalAmount = (oldSummary.totalAmount - bookingToRemove.totalAmount).clamp(0.0, double.infinity);
      final newTotalDiscount = (oldSummary.totalDiscount - bookingToRemove.discountAmount).clamp(0.0, double.infinity);
      
      // Decrease total bookings count
      final newTotalBookings = (oldSummary.totalBookings - 1).clamp(0, double.infinity).toInt();
      
      final updatedSummary = BulkBookingSummary(
        totalAmount: newTotalAmount,
        totalDiscount: newTotalDiscount,
        totalBookings: newTotalBookings,
        statusCounts: updatedStatusCounts,
      );
      
      // Update pagination total
      final oldPagination = _bulkBookingsResponse!.pagination;
      final newTotalBookingsInPagination = (oldPagination.totalBookings - 1).clamp(0, double.infinity).toInt();
      final updatedPagination = BulkBookingPagination(
        currentPage: oldPagination.currentPage,
        totalPages: oldPagination.totalPages,
        totalBookings: newTotalBookingsInPagination,
        hasNextPage: oldPagination.hasNextPage,
        hasPrevPage: oldPagination.hasPrevPage,
      );
      
      _bulkBookingsResponse = BulkBookingsResponse(
        bulkBookings: updatedBookings,
        pagination: updatedPagination,
        summary: updatedSummary,
      );
      notifyListeners();
    }
  }

  /// Update bulk booking payment status locally (for optimistic UI updates after payment)
  Future<void> updateBulkBookingLocally(BulkBooking updatedBooking) async {
    if (_bulkBookingsResponse != null) {
      final bookingIndex = _bulkBookingsResponse!.bulkBookings.indexWhere((b) => b.id == updatedBooking.id);
      if (bookingIndex == -1) return;

      final updatedBookings = List<BulkBooking>.from(_bulkBookingsResponse!.bulkBookings);
      updatedBookings[bookingIndex] = updatedBooking;

      _bulkBookingsResponse = BulkBookingsResponse(
        bulkBookings: updatedBookings,
        pagination: _bulkBookingsResponse!.pagination,
        summary: _bulkBookingsResponse!.summary,
      );

      notifyListeners();
    }
  }

  /// Update bulk booking in local state (for optimistic UI updates after edit)
  /// Also updates summary stats to reflect the changes
  void updateBulkBookingInState(String bookingId, BulkBooking updatedBooking) {
    if (_bulkBookingsResponse != null) {
      final bookingIndex = _bulkBookingsResponse!.bulkBookings.indexWhere((b) => b.id == bookingId);
      if (bookingIndex == -1) return;
      
      final oldBooking = _bulkBookingsResponse!.bulkBookings[bookingIndex];
      final updatedBookings = List<BulkBooking>.from(_bulkBookingsResponse!.bulkBookings);
      updatedBookings[bookingIndex] = updatedBooking;
      
      // Update summary stats if amount or status changed
      final oldSummary = _bulkBookingsResponse!.summary;
      final oldStatusCounts = oldSummary.statusCounts;
      
      // Update status counts if status changed
      BulkBookingStatusCounts updatedStatusCounts = oldStatusCounts;
      if (oldBooking.status != updatedBooking.status) {
        // Decrease old status count
        int newDraft = oldStatusCounts.draft;
        int newPending = oldStatusCounts.pending;
        int newConfirmed = oldStatusCounts.confirmed;
        int newCompleted = oldStatusCounts.completed;
        int newCancelled = oldStatusCounts.cancelled;
        
        switch (oldBooking.status) {
          case BulkBookingStatus.draft:
            newDraft = (newDraft - 1).clamp(0, double.infinity).toInt();
            break;
          case BulkBookingStatus.pending:
            newPending = (newPending - 1).clamp(0, double.infinity).toInt();
            break;
          case BulkBookingStatus.confirmed:
            newConfirmed = (newConfirmed - 1).clamp(0, double.infinity).toInt();
            break;
          case BulkBookingStatus.completed:
            newCompleted = (newCompleted - 1).clamp(0, double.infinity).toInt();
            break;
          case BulkBookingStatus.cancelled:
            newCancelled = (newCancelled - 1).clamp(0, double.infinity).toInt();
            break;
        }
        
        // Increase new status count
        switch (updatedBooking.status) {
          case BulkBookingStatus.draft:
            newDraft = newDraft + 1;
            break;
          case BulkBookingStatus.pending:
            newPending = newPending + 1;
            break;
          case BulkBookingStatus.confirmed:
            newConfirmed = newConfirmed + 1;
            break;
          case BulkBookingStatus.completed:
            newCompleted = newCompleted + 1;
            break;
          case BulkBookingStatus.cancelled:
            newCancelled = newCancelled + 1;
            break;
        }
        
        updatedStatusCounts = BulkBookingStatusCounts(
          draft: newDraft,
          pending: newPending,
          confirmed: newConfirmed,
          completed: newCompleted,
          cancelled: newCancelled,
        );
      }
      
      // Update amounts (subtract old, add new)
      final amountDifference = updatedBooking.totalAmount - oldBooking.totalAmount;
      final discountDifference = updatedBooking.discountAmount - oldBooking.discountAmount;
      
      final newTotalAmount = (oldSummary.totalAmount + amountDifference).clamp(0.0, double.infinity);
      final newTotalDiscount = (oldSummary.totalDiscount + discountDifference).clamp(0.0, double.infinity);
      
      final updatedSummary = BulkBookingSummary(
        totalAmount: newTotalAmount,
        totalDiscount: newTotalDiscount,
        totalBookings: oldSummary.totalBookings, // Total bookings doesn't change on edit
        statusCounts: updatedStatusCounts,
      );
      
      _bulkBookingsResponse = BulkBookingsResponse(
        bulkBookings: updatedBookings,
        pagination: _bulkBookingsResponse!.pagination,
        summary: updatedSummary,
      );
      notifyListeners();
    }
  }

  /// Delete user account
  /// Returns a map with deletion details
  Future<Map<String, dynamic>> deleteAccount({
    required String password,
    bool permanent = false,
  }) async {
    if (!auth.isLoggedIn) {
      throw Exception('User not logged in');
    }
    
    try {
      final result = await _userService.deleteAccount(
        password: password,
        permanent: permanent,
      );
      
      // If successful, sign out the user
      if (result['success'] == true) {
        await onSignOut();
      }
      
      return result;
    } catch (e) {
      debugPrint('Failed to delete account: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DELEGATED METHODS - Forward calls to individual state managers
  // ============================================================================

  // Auth methods
  Future<bool> signIn(String email, String password) => auth.signIn(email, password);
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
  }) => auth.signUp(
    email,
    password,
    name,
    phoneNumber,
    referralCode: referralCode,
    isCorporate: isCorporate,
    companyName: companyName,
    companyEmail: companyEmail,
    contactPerson: contactPerson,
    monthlyBudget: monthlyBudget,
  );
  Future<bool> signOut() => auth.signOut();
  Future<bool> resetPassword(String email) => auth.resetPassword(email);

  // Vehicle methods
  Future<void> loadVehicles({bool force = false}) => vehicles.loadVehicles(force: force);
  void updateSearchQuery(String query) => vehicles.updateSearchQuery(query);
  void updateFilter(String filter) => vehicles.updateFilter(filter);
  void updateCity(String city) => vehicles.updateCity(city);
  void updateCategory(String? category) => vehicles.updateCategory(category);
  void clearCategoryFilter() => vehicles.clearCategoryFilter();
  bool isVehicleFavorited(String vehicleId) => vehicles.isVehicleFavorited(vehicleId);
  void toggleVehicleFavorite(String vehicleId) => vehicles.toggleVehicleFavorite(vehicleId);
  void updateAdvancedFilters(Map<String, dynamic> filters) => vehicles.updateAdvancedFilters(filters);

  // Booking methods
  Future<void> loadBookings({
    int page = 1,
    bool reset = true,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) => bookings.loadBookings(
    page: page,
    reset: reset,
    status: status,
    startDate: startDate,
    endDate: endDate,
  );
  Future<void> loadMoreBookings() => bookings.loadMoreBookings();
  Future<Booking?> getBookingById(String bookingId) => bookings.getBookingById(bookingId);
  Future<Booking?> createBooking({
    required String vehicleId,
    required String vehicleName,
    required String vehicleType,
    required String serviceType,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required DateTime scheduledDate,
    required int passengerCount,
    required Map<String, dynamic> pricing,
    String? pickupAddress,
    String? dropoffAddress,
    List<Map<String, dynamic>>? waypoints,
    int? luggageCount,
    DateTime? pickupTime,
    bool? isFlexibleTime,
    int? flexibleWindow,
    double? basePrice,
    double? finalPrice,
    String? specialNotes,
    bool closeProtectionOfficer = false,
    String? customerNotes,
    String? paymentMethod,
    Map<String, dynamic>? emergencyContact,
    String? quoteId,
  }) => bookings.createBooking(
    vehicleId: vehicleId,
    vehicleName: vehicleName,
    vehicleType: vehicleType,
    serviceType: serviceType,
    pickupLocation: pickupLocation,
    dropoffLocation: dropoffLocation,
    scheduledDate: scheduledDate,
    passengerCount: passengerCount,
    pricing: pricing,
    pickupAddress: pickupAddress,
    dropoffAddress: dropoffAddress,
    waypoints: waypoints,
    luggageCount: luggageCount,
    pickupTime: pickupTime,
    isFlexibleTime: isFlexibleTime,
    flexibleWindow: flexibleWindow,
    basePrice: basePrice,
    finalPrice: finalPrice,
    specialNotes: specialNotes,
    closeProtectionOfficer: closeProtectionOfficer,
    customerNotes: customerNotes,
    paymentMethod: paymentMethod,
    emergencyContact: emergencyContact,
    quoteId: quoteId,
  );
  Future<bool> cancelBooking(String bookingId) => bookings.cancelBooking(bookingId);
  
  /// Remove booking from local state (for cancelled bookings)
  void removeBooking(String bookingId) => bookings.removeBooking(bookingId);
  
  /// Update booking status with optional notes
  Future<Booking> updateBookingStatus(String bookingId, String status, {String? notes, bool skipLoadingState = false}) => 
      bookings.updateBookingStatus(bookingId, status, notes: notes, skipLoadingState: skipLoadingState);
  
  Future<bool> assignDriver(String bookingId, String driverId) => bookings.assignDriver(bookingId, driverId);
  Future<bool> rateDriver(String driverId, {
    required String bookingId,
    required double rating,
    String? review,
    Map<String, double>? criteria,
  }) => bookings.rateDriver(driverId, bookingId: bookingId, rating: rating, review: review, criteria: criteria);
  Future<Driver?> getDriverById(String driverId) => bookings.getDriverById(driverId);

  // Payment methods
  Future<void> loadPaymentMethods() => payments.loadPaymentMethods();
  Future<PaymentMethod?> addPaymentMethod({
    required String type,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String holderName,
    Map<String, dynamic>? billingAddress,
  }) => payments.addPaymentMethod(
    type: type,
    cardNumber: cardNumber,
    expiryMonth: expiryMonth,
    expiryYear: expiryYear,
    cvc: cvc,
    holderName: holderName,
    billingAddress: billingAddress,
  );
  Future<PaymentMethod?> updatePaymentMethod(String methodId, Map<String, dynamic> updates) => payments.updatePaymentMethod(methodId, updates);
  Future<bool> deletePaymentMethod(String methodId) => payments.deletePaymentMethod(methodId);
  Future<bool> setDefaultPaymentMethod(String methodId) => payments.setDefaultPaymentMethod(methodId);

  // Notification methods
  Future<void> loadNotifications() => notifications.loadNotifications();
  Future<bool> markNotificationAsRead(String notificationId) => notifications.markNotificationAsRead(notificationId);
  Future<bool> markAllNotificationsAsRead() => notifications.markAllNotificationsAsRead();

  // Quote methods
  Future<Quote?> createQuote({
    required LatLng pickupLocation,
    required LatLng dropoffLocation,
    required String vehicleType,
    required String serviceType,
    required DateTime scheduledDate,
    required int passengerCount,
    String? pickupAddress,
    String? dropoffAddress,
    String? specialNotes,
    int? luggageCount,
  }) => quotes.createQuote(
    pickupLocation: pickupLocation,
    dropoffLocation: dropoffLocation,
    vehicleType: vehicleType,
    serviceType: serviceType,
    scheduledDate: scheduledDate,
    passengerCount: passengerCount,
    pickupAddress: pickupAddress,
    dropoffAddress: dropoffAddress,
    specialNotes: specialNotes,
    luggageCount: luggageCount,
  );
  Future<List<Quote>> getQuoteHistory({
    int? page,
    int? limit,
    String? status,
  }) => quotes.getQuoteHistory(
    page: page,
    limit: limit,
    status: status,
  );
  Future<Quote?> getQuoteById(String quoteId) => quotes.getQuoteById(quoteId);
  Future<bool> updateQuoteStatus(String quoteId, String status, {String? notes}) => 
      quotes.updateQuoteStatus(quoteId, status, notes: notes);
  Future<bool> acceptQuote(String quoteId, {String? notes}) => quotes.acceptQuote(quoteId, notes: notes);
  Future<bool> cancelQuote(String quoteId, {String? reason}) => quotes.cancelQuote(quoteId, reason: reason);
  Future<bool> rejectQuote(String quoteId) => quotes.rejectQuote(quoteId);
  void checkAndHandleExpiredQuotes() => quotes.checkAndHandleExpiredQuotes();

  // Support methods
  Future<List<FAQ>> getFAQs({
    String? category,
    int page = 1,
    int limit = 20,
  }) => support.getFAQs(category: category, page: page, limit: limit);
  Future<List<FAQ>> searchFAQs(String query, {int limit = 20}) => support.searchFAQs(query, limit: limit);
  Future<bool> rateFAQ(String faqId, bool isHelpful) => support.rateFAQ(faqId, isHelpful);
  Future<SupportTicket?> createSupportTicket({
    required String subject,
    required String category,
    required String description,
    String priority = 'normal',
    String? relatedBookingId,
    String? relatedQuoteId,
  }) => support.createSupportTicket(
    subject: subject,
    category: category,
    description: description,
    priority: priority,
    relatedBookingId: relatedBookingId,
    relatedQuoteId: relatedQuoteId,
  );

  // Settings methods
  Future<bool> toggleDarkMode() => settings.toggleDarkMode();
  Future<bool> setLanguage(String language) => settings.setLanguage(language);
  Future<bool> resetSettings() => settings.resetSettings();
}
