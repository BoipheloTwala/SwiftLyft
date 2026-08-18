import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../services/http_client.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

/// Payment Service - handles /api/payments/* endpoints
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  final ApiClient _apiClient = ApiClient();

  PaymentService._internal();

  /// Process a payment
  Future<PaymentTransaction> processPayment({
    required String bookingId,
    required String paymentMethodId,
    required double amount,
    String currency = 'ZAR',
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/payments/process';
      final response = await _apiClient.post(url, body: {
        'bookingId': bookingId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        'description': description,
        'metadata': metadata,
      });

      final data = jsonDecode(response.body);
      return PaymentTransaction.fromJson(data['data']['transaction']);
    } catch (e) {
      debugPrint('Failed to process payment: $e');
      rethrow;
    }
  }

  /// Get payment methods for current user
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      // Get current user ID from AuthService
      final authService = AuthService();
      final userId = authService.currentUser?.id;
      debugPrint('🔍 Current user ID: $userId');
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final url = '${AppConstants.baseUrl}/api/users/$userId/payment-methods';
      debugPrint('🔍 Calling payment methods API: $url');
      final response = await _apiClient.get(url);
      debugPrint('🔍 API response status: ${response.statusCode}');

      final data = jsonDecode(response.body);
      final methods = data['data']['paymentMethods'] as List;
      return methods.map((method) => PaymentMethod.fromJson(method)).toList();
    } catch (e) {
      debugPrint('Failed to get payment methods: $e');
      rethrow;
    }
  }

  /// Add payment method for current user
  Future<PaymentMethod> addPaymentMethod({
    required String type,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String holderName,
    String? billingAddress,
  }) async {
    try {
      // Get current user ID from AuthService
      final authService = AuthService();
      final userId = authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final url = '${AppConstants.baseUrl}/api/users/$userId/payment-methods';
      final response = await _apiClient.post(url, body: {
        'type': type,
        'cardNumber': cardNumber,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'cvc': cvc,
        'holderName': holderName,
        'billingAddress': billingAddress,
      });

      final data = jsonDecode(response.body);
      return PaymentMethod.fromJson(data['data']['paymentMethod']);
    } catch (e) {
      debugPrint('Failed to add payment method: $e');
      rethrow;
    }
  }

  /// Update payment method
  Future<PaymentMethod> updatePaymentMethod(
    String methodId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final url = '${AppConstants.baseUrl}/api/payments/methods/$methodId';
      final response = await _apiClient.put(url, body: updates);

      final data = jsonDecode(response.body);
      return PaymentMethod.fromJson(data['data']['method']);
    } catch (e) {
      debugPrint('Failed to update payment method: $e');
      rethrow;
    }
  }

  /// Delete payment method
  Future<void> deletePaymentMethod(String methodId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/payments/methods/$methodId';
      await _apiClient.delete(url);
    } catch (e) {
      debugPrint('Failed to delete payment method: $e');
      rethrow;
    }
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod(String methodId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/payments/methods/$methodId/default';
      await _apiClient.put(url);
    } catch (e) {
      debugPrint('Failed to set default payment method: $e');
      rethrow;
    }
  }

  /// Get payment transactions
  Future<List<PaymentTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/payments/transactions';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      final transactions = data['data']['transactions'] as List;
      return transactions.map((tx) => PaymentTransaction.fromJson(tx)).toList();
    } catch (e) {
      debugPrint('Failed to get transactions: $e');
      rethrow;
    }
  }

  /// Get transaction by ID
  Future<PaymentTransaction> getTransaction(String transactionId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/payments/transactions/$transactionId';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return PaymentTransaction.fromJson(data['data']['transaction']);
    } catch (e) {
      debugPrint('Failed to get transaction: $e');
      rethrow;
    }
  }

  /// Refund payment
  Future<PaymentTransaction> refundPayment({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    try {
      const url = '${AppConstants.baseUrl}/api/payments/refund';
      final response = await _apiClient.post(url, body: {
        'transactionId': transactionId,
        'amount': amount,
        'reason': reason,
      });

      final data = jsonDecode(response.body);
      return PaymentTransaction.fromJson(data['data']['refund']);
    } catch (e) {
      debugPrint('Failed to refund payment: $e');
      rethrow;
    }
  }

  /// Get payment statistics
  Future<PaymentStats> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      const url = '${AppConstants.baseUrl}/api/payments/stats';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      final data = jsonDecode(response.body);
      return PaymentStats.fromJson(data['data']['stats']);
    } catch (e) {
      debugPrint('Failed to get payment stats: $e');
      rethrow;
    }
  }

  /// Validate payment method
  Future<PaymentMethodValidation> validatePaymentMethod(String methodId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/payments/methods/$methodId/validate';
      final response = await _apiClient.post(url);

      final data = jsonDecode(response.body);
      return PaymentMethodValidation.fromJson(data['data']['validation']);
    } catch (e) {
      debugPrint('Failed to validate payment method: $e');
      rethrow;
    }
  }

  /// Get supported payment methods
  Future<List<String>> getSupportedPaymentTypes() async {
    try {
      const url = '${AppConstants.baseUrl}/api/payments/types';
      final response = await _apiClient.get(url);

      final data = jsonDecode(response.body);
      return List<String>.from(data['data']['types']);
    } catch (e) {
      debugPrint('Failed to get supported payment types: $e');
      rethrow;
    }
  }
}
