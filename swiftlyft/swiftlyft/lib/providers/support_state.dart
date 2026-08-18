import 'package:flutter/foundation.dart';
import '../models/support.dart';
import '../services/support_api_service.dart';
import '../services/analytics_api_service.dart';

/// Support state management for FAQs and support tickets
class SupportState extends ChangeNotifier {
  final SupportService _supportService;
  final AnalyticsService _analyticsService;

  SupportState(this._supportService, this._analyticsService);

  // State
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<FAQ>> getFAQs({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final faqs = await _supportService.getFAQs(
        category: category,
        limit: limit,
      );

      // Track FAQ retrieval
      await _analyticsService.trackEvent(
        eventType: 'faqs_retrieved',
        eventData: {
          'category': category,
          'count': faqs.length,
        },
      );

      _setLoading(false);
      notifyListeners();
      return faqs;
    } catch (e) {
      final errorMessage = 'Failed to load FAQs: $e';
      _setError(errorMessage);

      // Track FAQ load failure
      await _analyticsService.trackEvent(
        eventType: 'faqs_load_failed',
        eventData: {'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<FAQ>> searchFAQs(String query, {int limit = 20}) async {
    _setLoading(true);
    _clearError();

    try {
      final faqs = await _supportService.searchFAQs(query, limit: limit);

      // Track FAQ search
      await _analyticsService.trackEvent(
        eventType: 'faqs_searched',
        eventData: {
          'query': query,
          'results_count': faqs.length,
        },
      );

      _setLoading(false);
      notifyListeners();
      return faqs;
    } catch (e) {
      final errorMessage = 'Failed to search FAQs: $e';
      _setError(errorMessage);

      // Track search failure
      await _analyticsService.trackEvent(
        eventType: 'faqs_search_failed',
        eventData: {'query': query, 'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> rateFAQ(String faqId, bool isHelpful) async {
    try {
      await _supportService.rateFAQ(faqId: faqId, helpful: isHelpful);

      // Track FAQ rating
      await _analyticsService.trackEvent(
        eventType: 'faq_rated',
        eventData: {
          'faq_id': faqId,
          'helpful': isHelpful,
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to rate FAQ: $e');

      // Track rating failure
      await _analyticsService.trackEvent(
        eventType: 'faq_rating_failed',
        eventData: {'faq_id': faqId, 'error': e.toString()},
      );

      return false;
    }
  }

  Future<SupportTicket?> createSupportTicket({
    required String subject,
    required String category,
    required String description,
    String priority = 'normal',
    String? relatedBookingId,
    String? relatedQuoteId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final ticket = await _supportService.createTicket(
        subject: subject,
        category: category,
        description: description,
        priority: priority,
        relatedBookingId: relatedBookingId,
        relatedQuoteId: relatedQuoteId,
      );

      // Track support ticket creation
      await _analyticsService.trackEvent(
        eventType: 'support_ticket_created',
        eventData: {
          'ticket_id': ticket.id,
          'category': category,
          'priority': priority,
        },
      );

      _setLoading(false);
      notifyListeners();
      return ticket;
    } catch (e) {
      final errorMessage = 'Failed to create support ticket: $e';
      _setError(errorMessage);

      // Track ticket creation failure
      await _analyticsService.trackEvent(
        eventType: 'support_ticket_creation_failed',
        eventData: {'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      rethrow;
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
