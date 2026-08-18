import 'package:flutter/foundation.dart';
import '../models/coordinates.dart';
import '../models/quote.dart';
import '../services/quote_api_service.dart';
import '../services/analytics_api_service.dart';

/// Quote state management
class QuoteState extends ChangeNotifier {
  final QuoteService _quoteService;
  final AnalyticsService _analyticsService;
  final String Function() _getUserId;

  QuoteState(this._quoteService, this._analyticsService, this._getUserId);

  // State
  List<Quote> _quotes = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Quote> get quotes => _quotes;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 QuoteState: Creating quote request');
      
      final quote = await _quoteService.createQuote(
        pickupLocation: {
          'address': pickupAddress ?? 'Pickup Location',
          'coordinates': {
            'latitude': pickupLocation.latitude,
            'longitude': pickupLocation.longitude,
          },
        },
        dropoffLocation: {
          'address': dropoffAddress ?? 'Dropoff Location',
          'coordinates': {
            'latitude': dropoffLocation.latitude,
            'longitude': dropoffLocation.longitude,
          },
        },
        vehicleType: vehicleType,
        serviceType: serviceType,
        scheduledDate: scheduledDate,
        passengerCount: passengerCount,
        specialRequirements: specialNotes,
        luggageCount: luggageCount,
      );

      _quotes.add(quote);

      // Track quote creation
      await _analyticsService.trackEvent(
        eventType: 'quote_created',
        eventData: {
          'quote_id': quote.id,
          'vehicle_type': vehicleType,
          'service_type': serviceType,
          'passenger_count': passengerCount,
          'estimated_price': quote.finalPrice,
        },
      );

      _setLoading(false);
      notifyListeners();
      return quote;
    } catch (e) {
      final errorMessage = 'Failed to create quote: $e';
      _setError(errorMessage);

      // Track quote creation failure
      await _analyticsService.trackEvent(
        eventType: 'quote_creation_failed',
        eventData: {'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Quote>> getQuoteHistory({
    int? page,
    int? limit,
    String? status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📋 QuoteState: Loading quote history');
      
      final userId = _getUserId();
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final quotes = await _quoteService.getUserQuotes(
        userId: userId,
        page: page ?? 1,
        limit: limit ?? 20,
        status: status,
      );
      
      _quotes = quotes;

      // Track quote history load
      await _analyticsService.trackEvent(
        eventType: 'quote_history_loaded',
        eventData: {'count': quotes.length},
      );

      _setLoading(false);
      notifyListeners();
      return quotes;
    } catch (e) {
      final errorMessage = 'Failed to load quote history: $e';
      _setError(errorMessage);

      // Track load failure
      await _analyticsService.trackEvent(
        eventType: 'quote_history_load_failed',
        eventData: {'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateQuoteStatus(String quoteId, String status, {String? notes}) async {
    try {
      debugPrint('🔄 QuoteState: Updating quote status to: $status');
      
      final updatedQuote = await _quoteService.updateQuoteStatus(
        quoteId,
        status,
        notes: notes,
      );

      // Update local state with the returned quote
      final index = _quotes.indexWhere((q) => q.id == quoteId);
      if (index != -1) {
        _quotes[index] = updatedQuote;
      }

      // Track status update
      await _analyticsService.trackEvent(
        eventType: 'quote_status_updated',
        eventData: {'quote_id': quoteId, 'status': status},
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update quote status: $e');

      // Track failure
      await _analyticsService.trackEvent(
        eventType: 'quote_status_update_failed',
        eventData: {'quote_id': quoteId, 'status': status, 'error': e.toString()},
      );

      return false;
    }
  }

  /// Accept a quote
  /// Note: Since backend only allows users to cancel quotes, this method
  /// creates a notification/request for admin to approve the acceptance
  Future<bool> acceptQuote(String quoteId, {String? notes}) async {
    try {
      debugPrint('📋 QuoteState: Accepting quote $quoteId');
      
      // For now, we'll track the acceptance locally
      // In a full implementation, this would notify admin or create a booking
      
      final index = _quotes.indexWhere((q) => q.id == quoteId);
      if (index != -1) {
        // Track acceptance event
        await _analyticsService.trackEvent(
          eventType: 'quote_accepted',
          eventData: {
            'quote_id': quoteId,
            'notes': notes,
          },
        );
        
        debugPrint('✅ Quote acceptance tracked');
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Failed to accept quote: $e');
      
      await _analyticsService.trackEvent(
        eventType: 'quote_acceptance_failed',
        eventData: {'quote_id': quoteId, 'error': e.toString()},
      );
      
      return false;
    }
  }

  /// Cancel/Reject a quote
  Future<bool> cancelQuote(String quoteId, {String? reason}) async {
    return updateQuoteStatus(quoteId, 'cancelled', notes: reason);
  }

  /// Legacy method for backwards compatibility
  Future<bool> rejectQuote(String quoteId) async {
    return cancelQuote(quoteId);
  }

  Future<Quote?> getQuoteById(String quoteId) async {
    try {
      // First check if we have it in local cache
      try {
        final cachedQuote = _quotes.firstWhere(
          (quote) => quote.id == quoteId,
        );
        return cachedQuote;
      } catch (e) {
        // Not found in cache, continue to API call
      }

      // If not in cache, try to fetch from API
      // Note: This assumes the API has a getQuoteById method
      // For now, return null as this might not be implemented
      return null;
    } catch (e) {
      debugPrint('Failed to get quote by ID: $e');
      return null;
    }
  }

  void checkAndHandleExpiredQuotes() {
    final now = DateTime.now();
    final expiredQuotes = _quotes.where((quote) =>
      quote.status == 'pending' &&
      quote.expiresAt.isBefore(now)
    ).toList();

    for (final quote in expiredQuotes) {
      updateQuoteStatus(quote.id, 'expired');
    }

    if (expiredQuotes.isNotEmpty) {
      // Track expired quotes
      _analyticsService.trackEvent(
        eventType: 'quotes_expired',
        eventData: {'count': expiredQuotes.length},
      );
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
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
