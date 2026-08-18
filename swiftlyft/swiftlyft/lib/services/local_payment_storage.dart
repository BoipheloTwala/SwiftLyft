import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment.dart';

/// Local storage service for payment methods
/// Used as fallback when backend API is not available
/// Each user has their own isolated storage to prevent cross-user contamination
class LocalPaymentStorage {
  
  /// Save payment methods to local storage for a specific user
  static Future<void> savePaymentMethods(List<PaymentMethod> methods, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'local_payment_methods_$userId';
      final jsonList = methods.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(storageKey, jsonString);
      debugPrint('✅ Saved ${methods.length} payment methods for user $userId');
    } catch (e) {
      debugPrint('❌ Error saving payment methods to local storage: $e');
    }
  }
  
  /// Load payment methods from local storage for a specific user
  static Future<List<PaymentMethod>> loadPaymentMethods(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'local_payment_methods_$userId';
      final jsonString = prefs.getString(storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('ℹ️ No payment methods in local storage for user $userId');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final methods = jsonList.map((json) => PaymentMethod.fromJson(json)).toList();
      debugPrint('✅ Loaded ${methods.length} payment methods from local storage for user $userId');
      return methods;
    } catch (e) {
      debugPrint('❌ Error loading payment methods from local storage: $e');
      return [];
    }
  }
  
  /// Add a new payment method for a specific user
  static Future<PaymentMethod> addPaymentMethod({
    required String type,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String holderName,
    required String userId,
  }) async {
    try {
      // Load existing methods for this user
      final methods = await loadPaymentMethods(userId);

      // Create new method
      final newMethod = PaymentMethod(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: type,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        holderName: holderName,
        brand: _detectCardBrand(cardNumber),
        isDefault: methods.isEmpty, // First card is default
        isActive: true,
        isExpired: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to list
      methods.add(newMethod);

      // Save
      await savePaymentMethods(methods, userId);

      debugPrint('✅ Added payment method for user $userId: ${newMethod.id}');
      return newMethod;
    } catch (e) {
      debugPrint('❌ Error adding payment method: $e');
      rethrow;
    }
  }
  
  /// Update a payment method for a specific user
  static Future<PaymentMethod> updatePaymentMethod(
    String methodId,
    Map<String, dynamic> updates,
    String userId,
  ) async {
    try {
      final methods = await loadPaymentMethods(userId);
      final index = methods.indexWhere((m) => m.id == methodId);

      if (index == -1) {
        throw Exception('Payment method not found');
      }

      final currentMethod = methods[index];

      // Build updated method with all provided fields
      String? newCardNumber = updates['cardNumber'] as String?;
      String? newBrand = updates['brand'] as String?;

      // If card number changed, detect brand if not provided
      if (newCardNumber != null && newBrand == null) {
        newBrand = _detectCardBrand(newCardNumber);
      }

      // Update the method with all provided fields
      final updatedMethod = currentMethod.copyWith(
        cardNumber: newCardNumber ?? currentMethod.cardNumber,
        expiryMonth: updates['expiryMonth'] as String? ?? currentMethod.expiryMonth,
        expiryYear: updates['expiryYear'] as String? ?? currentMethod.expiryYear,
        holderName: updates['holderName'] as String? ?? currentMethod.holderName,
        brand: newBrand ?? currentMethod.brand,
        updatedAt: DateTime.now(),
      );

      methods[index] = updatedMethod;
      await savePaymentMethods(methods, userId);

      debugPrint('✅ Updated payment method for user $userId: $methodId');
      return updatedMethod;
    } catch (e) {
      debugPrint('❌ Error updating payment method: $e');
      rethrow;
    }
  }
  
  /// Delete a payment method for a specific user
  static Future<void> deletePaymentMethod(String methodId, String userId) async {
    try {
      final methods = await loadPaymentMethods(userId);
      methods.removeWhere((m) => m.id == methodId);
      await savePaymentMethods(methods, userId);
      debugPrint('✅ Deleted payment method for user $userId: $methodId');
    } catch (e) {
      debugPrint('❌ Error deleting payment method: $e');
      rethrow;
    }
  }
  
  /// Set a payment method as default for a specific user
  static Future<void> setDefaultPaymentMethod(String methodId, String userId) async {
    try {
      final methods = await loadPaymentMethods(userId);

      // Update all methods
      final updatedMethods = methods.map((m) {
        return m.copyWith(
          isDefault: m.id == methodId,
          updatedAt: DateTime.now(),
        );
      }).toList();

      await savePaymentMethods(updatedMethods, userId);
      debugPrint('✅ Set default payment method for user $userId: $methodId');
    } catch (e) {
      debugPrint('❌ Error setting default payment method: $e');
      rethrow;
    }
  }
  
  /// Clear all payment methods for all users (for testing/emergency use)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Remove all keys that start with our payment method prefix
      final keys = prefs.getKeys().where((key) => key.startsWith('local_payment_methods_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('✅ Cleared all user payment methods from local storage (${keys.length} users)');
    } catch (e) {
      debugPrint('❌ Error clearing payment methods: $e');
    }
  }
  
  /// Detect card brand from card number
  static String _detectCardBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    
    if (RegExp(r'^4').hasMatch(cleanNumber)) {
      return 'visa';
    } else if (RegExp(r'^5[1-5]').hasMatch(cleanNumber) ||
        RegExp(r'^2(2[2-9][0-9]|[3-6][0-9]{2}|7[0-1][0-9]|720)').hasMatch(cleanNumber)) {
      return 'mastercard';
    } else if (RegExp(r'^3[47]').hasMatch(cleanNumber)) {
      return 'amex';
    } else if (RegExp(r'^(6011|65|64[4-9]|622)').hasMatch(cleanNumber)) {
      return 'discover';
    }
    
    return 'card';
  }
}

