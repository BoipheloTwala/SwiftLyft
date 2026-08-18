import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/quote.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Quote Service - handles /api/quotes/* endpoints
class QuoteService {
  static final QuoteService _instance = QuoteService._internal();
  factory QuoteService() => _instance;

  final ApiClient _apiClient = ApiClient();

  QuoteService._internal();

  /// Transform location coordinates to backend format (latitude/longitude)
  Map<String, dynamic> _transformLocation(dynamic location) {
    // Accept both Map and String; if String, wrap into minimal structure
    if (location is! Map<String, dynamic>) {
      return {
        'address': location?.toString() ?? 'Location',
        'coordinates': <String, dynamic>{},
      };
    }

    final coords = location['coordinates'] as Map<String, dynamic>?;
    if (coords == null) return location;
    
    // Ensure coordinates use latitude/longitude keys (backend format)
    final transformedCoords = <String, dynamic>{};
    if (coords.containsKey('lat') && coords.containsKey('lng')) {
      transformedCoords['latitude'] = coords['lat'];
      transformedCoords['longitude'] = coords['lng'];
    } else if (coords.containsKey('latitude') && coords.containsKey('longitude')) {
      // Already in correct format
      transformedCoords['latitude'] = coords['latitude'];
      transformedCoords['longitude'] = coords['longitude'];
    }
    
    return {
      'address': location['address'],
      'coordinates': transformedCoords,
    };
  }

  /// Create a quote request
  /// Endpoint: POST /api/quotes
  Future<Quote> createQuote({
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required String vehicleType,
    required String serviceType,
    required DateTime scheduledDate,
    required int passengerCount,
    String? specialRequirements,
    int? luggageCount,
  }) async {
    try {
      debugPrint('📝 Creating quote request');
      
      const url = '${AppConstants.baseUrl}/api/quotes';
      final response = await _apiClient.post(url, body: {
        'pickupLocation': _transformLocation(pickupLocation),
        'dropoffLocation': _transformLocation(dropoffLocation),
        'vehicleType': vehicleType,
        'serviceType': serviceType,
        'scheduledDate': scheduledDate.toIso8601String(),
        'passengerCount': passengerCount,
        'luggageCount': luggageCount ?? 0,
        'specialRequirements': specialRequirements,
      });

      final data = jsonDecode(response.body);
      debugPrint('✅ Quote created successfully');

      // Support multiple backend response shapes
      final dynamic payload = data['data'];
      Map<String, dynamic>? quoteJson;

      if (payload is Map<String, dynamic>) {
        if (payload['quote'] is Map<String, dynamic>) {
          quoteJson = payload['quote'] as Map<String, dynamic>;
        } else if (payload.containsKey('id')) {
          quoteJson = payload; // data holds the quote directly
        }
      }

      if (quoteJson == null) {
        throw Exception('Unexpected quote response format');
      }

      return Quote.fromJson(quoteJson);
    } catch (e) {
      debugPrint('❌ Failed to create quote: $e');
      rethrow;
    }
  }

  /// Update quote status
  /// Endpoint: PUT /api/quotes/:id
  /// Users can only set status to 'cancelled', admins can set any status
  Future<Quote> updateQuoteStatus(
    String quoteId,
    String status, {
    String? notes,
  }) async {
    try {
      debugPrint('🔄 Updating quote $quoteId status to: $status');
      
      final url = '${AppConstants.baseUrl}/api/quotes/$quoteId';
      final response = await _apiClient.put(url, body: {
        'status': status,
        if (notes != null) 'notes': notes,
      });

      final data = jsonDecode(response.body);
      debugPrint('✅ Quote status updated successfully');
      return Quote.fromJson(data['data']['quote']);
    } catch (e) {
      debugPrint('❌ Failed to update quote status: $e');
      rethrow;
    }
  }

  /// Get quote by ID
  /// Endpoint: GET /api/quotes/:id
  Future<Quote> getQuote(String quoteId) async {
    try {
      debugPrint('📖 Fetching quote: $quoteId');
      
      final url = '${AppConstants.baseUrl}/api/quotes/$quoteId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return Quote.fromJson(data['data']['quote']);
    } catch (e) {
      debugPrint('❌ Failed to get quote: $e');
      rethrow;
    }
  }

  /// Get user quotes
  /// Endpoint: GET /api/quotes/user/:userId
  Future<List<Quote>> getUserQuotes({
    required String userId,
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      debugPrint('📋 Fetching user quotes for: $userId');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final url = '${AppConstants.baseUrl}/api/quotes/user/$userId';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final quotes = data['data']['quotes'] as List;
      debugPrint('✅ Found ${quotes.length} quotes');
      return quotes.map((quote) => Quote.fromJson(quote)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get user quotes: $e');
      rethrow;
    }
  }

  /// Get price estimate without creating a quote
  /// Endpoint: POST /api/quotes/estimate
  /// This is a public endpoint that doesn't require authentication
  Future<Map<String, dynamic>> getPriceEstimate({
    required Map<String, double> pickupCoordinates,
    required Map<String, double> dropoffCoordinates,
    required String vehicleType,
    required String serviceType,
    int passengerCount = 1,
  }) async {
    try {
      debugPrint('💰 Getting price estimate');
      
      const url = '${AppConstants.baseUrl}/api/quotes/estimate';
      final response = await _apiClient.post(url, body: {
        'pickupCoordinates': pickupCoordinates,
        'dropoffCoordinates': dropoffCoordinates,
        'vehicleType': vehicleType,
        'serviceType': serviceType,
        'passengerCount': passengerCount,
      });

      final data = jsonDecode(response.body);
      debugPrint('✅ Price estimate received');
      return data['data'];
    } catch (e) {
      debugPrint('❌ Failed to get price estimate: $e');
      rethrow;
    }
  }

  /// Cancel quote (uses updateQuoteStatus internally)
  /// Users can cancel their own quotes by setting status to 'cancelled'
  Future<Quote> cancelQuote(String quoteId, {String? reason}) async {
    return updateQuoteStatus(quoteId, 'cancelled', notes: reason);
  }

  // ============================================================================
  // HELPER METHODS FOR COMMON OPERATIONS
  // ============================================================================

  /// Get pending quotes for a user
  Future<List<Quote>> getPendingQuotes({required String userId}) async {
    return getUserQuotes(userId: userId, status: 'pending');
  }

  /// Get quote history (all quotes) for a user
  Future<List<Quote>> getQuoteHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    return getUserQuotes(userId: userId, page: page, limit: limit);
  }

  // ============================================================================
  // NOTE: The following methods are NOT implemented in the backend yet
  // ============================================================================
  
  // Future<QuoteAcceptance> acceptQuote(...) - NOT IMPLEMENTED
  // Future<void> rejectQuote(...) - Use updateQuoteStatus with 'cancelled' instead
  // Future<QuoteModification> requestModification(...) - NOT IMPLEMENTED
  // Future<QuoteStats> getQuoteStats() - NOT IMPLEMENTED
  // Future<QuoteShare> shareQuote(...) - NOT IMPLEMENTED
  // Future<List<QuoteTemplate>> getQuoteTemplates() - NOT IMPLEMENTED
  // Future<Quote> createQuoteFromTemplate(...) - NOT IMPLEMENTED
}
