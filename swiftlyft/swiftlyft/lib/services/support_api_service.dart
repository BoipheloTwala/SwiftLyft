import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/support.dart';
import '../services/http_client.dart';
import '../utils/constants.dart';

/// Support Service - handles /api/support/* endpoints
class SupportService {
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;

  final ApiClient _apiClient = ApiClient();

  SupportService._internal();

  /// Create support ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String description,
    String priority = 'normal',
    String? relatedBookingId,
    String? relatedQuoteId,
    List<String>? attachments,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/support/tickets';
      final response = await _apiClient.post(url, body: {
        'subject': subject,
        'category': category,
        'description': description,
        'priority': priority,
        'relatedBookingId': relatedBookingId,
        'relatedQuoteId': relatedQuoteId,
        'attachments': attachments,
      });

      final data = jsonDecode(response.body);
      return SupportTicket.fromJson(data['data']['ticket']);
    } catch (e) {
      debugPrint('Failed to create support ticket: $e');
      rethrow;
    }
  }

  /// Get user support tickets
  Future<List<SupportTicket>> getUserTickets({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (category != null) 'category': category,
      };

      const url = '${AppConstants.baseUrl}/api/support/tickets';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final tickets = data['data']['tickets'] as List;
      return tickets.map((ticket) => SupportTicket.fromJson(ticket)).toList();
    } catch (e) {
      debugPrint('Failed to get user tickets: $e');
      rethrow;
    }
  }

  /// Get support ticket by ID
  Future<SupportTicket> getTicket(String ticketId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/support/tickets/$ticketId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return SupportTicket.fromJson(data['data']['ticket']);
    } catch (e) {
      debugPrint('Failed to get support ticket: $e');
      rethrow;
    }
  }

  /// Update support ticket
  Future<SupportTicket> updateTicket(
    String ticketId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final url = '${AppConstants.baseUrl}/api/support/tickets/$ticketId';
      final response = await _apiClient.put(url, body: updates);

      final data = jsonDecode(response.body);
      return SupportTicket.fromJson(data['data']['ticket']);
    } catch (e) {
      debugPrint('Failed to update support ticket: $e');
      rethrow;
    }
  }

  /// Close support ticket
  Future<SupportTicket> closeTicket(String ticketId, {String? feedback}) async {
    try {
      final url = '${AppConstants.baseUrl}/api/support/tickets/$ticketId/close';
      final response = await _apiClient.put(url, body: {
        if (feedback != null) 'feedback': feedback,
      });

      final data = jsonDecode(response.body);
      return SupportTicket.fromJson(data['data']['ticket']);
    } catch (e) {
      debugPrint('Failed to close support ticket: $e');
      rethrow;
    }
  }

  /// Add message to support ticket
  Future<SupportMessage> addMessage({
    required String ticketId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/support/tickets/$ticketId/messages';
      final response = await _apiClient.post(url, body: {
        'message': message,
        'attachments': attachments,
      });

      final data = jsonDecode(response.body);
      return SupportMessage.fromJson(data['data']['message']);
    } catch (e) {
      debugPrint('Failed to add message to ticket: $e');
      rethrow;
    }
  }

  /// Get ticket messages
  Future<List<SupportMessage>> getTicketMessages(
    String ticketId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = '${AppConstants.baseUrl}/api/support/tickets/$ticketId/messages';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final messages = data['data']['messages'] as List;
      return messages.map((message) => SupportMessage.fromJson(message)).toList();
    } catch (e) {
      debugPrint('Failed to get ticket messages: $e');
      rethrow;
    }
  }

  /// Get FAQ categories
  Future<List<FAQCategory>> getFAQCategories() async {
    try {
      const url = '${AppConstants.baseUrl}/api/support/faq/categories';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      final categories = data['data']['categories'] as List;
      return categories.map((category) => FAQCategory.fromJson(category)).toList();
    } catch (e) {
      debugPrint('Failed to get FAQ categories: $e');
      rethrow;
    }
  }

  /// Get FAQs
  Future<List<FAQ>> getFAQs({
    String? category,
    String? search,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      };

      const url = '${AppConstants.baseUrl}/api/support/faq';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final faqs = data['data']['faqs'] as List;
      return faqs.map((faq) => FAQ.fromJson(faq)).toList();
    } catch (e) {
      debugPrint('Failed to get FAQs: $e');
      rethrow;
    }
  }

  /// Search FAQs
  Future<List<FAQ>> searchFAQs(String query, {int limit = 20}) async {
    try {
      final queryParams = <String, String>{
        'query': query,
        'limit': limit.toString(),
      };

      const url = '${AppConstants.baseUrl}/api/support/faq/search';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final faqs = data['data']['faqs'] as List;
      return faqs.map((faq) => FAQ.fromJson(faq)).toList();
    } catch (e) {
      debugPrint('Failed to search FAQs: $e');
      rethrow;
    }
  }

  /// Get FAQ by ID
  Future<FAQ> getFAQ(String faqId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/support/faq/$faqId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return FAQ.fromJson(data['data']['faq']);
    } catch (e) {
      debugPrint('Failed to get FAQ: $e');
      rethrow;
    }
  }

  /// Rate FAQ helpfulness
  Future<void> rateFAQ({
    required String faqId,
    required bool helpful,
    String? feedback,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/support/faq/$faqId/rate';
      await _apiClient.post(url, body: {
        'helpful': helpful,
        'feedback': feedback,
      });
    } catch (e) {
      debugPrint('Failed to rate FAQ: $e');
      rethrow;
    }
  }

  /// Get support statistics
  Future<SupportStats> getSupportStats() async {
    try {
      const url = '${AppConstants.baseUrl}/api/support/stats';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return SupportStats.fromJson(data['data']['stats']);
    } catch (e) {
      debugPrint('Failed to get support stats: $e');
      rethrow;
    }
  }

  /// Request callback
  Future<CallbackRequest> requestCallback({
    required String phoneNumber,
    required String preferredTime,
    String? issue,
    String? ticketId,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/support/callback';
      final response = await _apiClient.post(url, body: {
        'phoneNumber': phoneNumber,
        'preferredTime': preferredTime,
        'issue': issue,
        'ticketId': ticketId,
      });

      final data = jsonDecode(response.body);
      return CallbackRequest.fromJson(data['data']['callback']);
    } catch (e) {
      debugPrint('Failed to request callback: $e');
      rethrow;
    }
  }

  /// Get live chat availability
  Future<LiveChatAvailability> getLiveChatAvailability() async {
    try {
      const url = '${AppConstants.baseUrl}/api/support/live-chat/availability';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return LiveChatAvailability.fromJson(data['data']['availability']);
    } catch (e) {
      debugPrint('Failed to get live chat availability: $e');
      rethrow;
    }
  }

  /// Start live chat session
  Future<LiveChatSession> startLiveChat({
    String? initialMessage,
    String? relatedTicketId,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/support/live-chat/start';
      final response = await _apiClient.post(url, body: {
        'initialMessage': initialMessage,
        'relatedTicketId': relatedTicketId,
      });

      final data = jsonDecode(response.body);
      return LiveChatSession.fromJson(data['data']['session']);
    } catch (e) {
      debugPrint('Failed to start live chat: $e');
      rethrow;
    }
  }

  /// Send live chat message
  Future<LiveChatMessage> sendLiveChatMessage({
    required String sessionId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/support/live-chat/$sessionId/message';
      final response = await _apiClient.post(url, body: {
        'message': message,
        'attachments': attachments,
      });

      final data = jsonDecode(response.body);
      return LiveChatMessage.fromJson(data['data']['message']);
    } catch (e) {
      debugPrint('Failed to send live chat message: $e');
      rethrow;
    }
  }

  /// End live chat session
  Future<void> endLiveChatSession(String sessionId, {String? feedback}) async {
    try {
      final url = '${AppConstants.baseUrl}/api/support/live-chat/$sessionId/end';
      await _apiClient.put(url, body: {
        if (feedback != null) 'feedback': feedback,
      });
    } catch (e) {
      debugPrint('Failed to end live chat session: $e');
      rethrow;
    }
  }

  /// Get system status
  Future<SystemStatus> getSystemStatus() async {
    try {
      const url = '${AppConstants.baseUrl}/api/support/system-status';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return SystemStatus.fromJson(data['data']['status']);
    } catch (e) {
      debugPrint('Failed to get system status: $e');
      rethrow;
    }
  }

  /// Submit feedback
  Future<void> submitFeedback({
    required int rating,
    String? comment,
    String? category,
    String? relatedTicketId,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/support/feedback';
      await _apiClient.post(url, body: {
        'rating': rating,
        'comment': comment,
        'category': category,
        'relatedTicketId': relatedTicketId,
      });
    } catch (e) {
      debugPrint('Failed to submit feedback: $e');
      rethrow;
    }
  }
}
