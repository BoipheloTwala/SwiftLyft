import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../services/payment_api_service.dart';
import '../services/analytics_api_service.dart';
import '../services/local_payment_storage.dart';

/// Payment method state management
class PaymentState extends ChangeNotifier {
  final PaymentService _paymentService;
  final AnalyticsService _analyticsService;
  final String? Function() _getCurrentUserId;

  PaymentState(this._paymentService, this._analyticsService, this._getCurrentUserId);

  // State
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;
  bool _useLocalStorage = false; // Flag to track if using local storage
  String? _currentUserId; // Track which user's payment methods are loaded

  // Getters
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId; // For debugging user association

  Future<void> loadPaymentMethods() async {
    final currentUserId = _getCurrentUserId();

    // If user changed, force reload even if we have payment methods
    if (_currentUserId != null && _currentUserId != currentUserId) {
      debugPrint('👤 User changed from $_currentUserId to $currentUserId, forcing reload');
      _paymentMethods = [];
      _currentUserId = currentUserId;
    }

    // If we already have payment methods loaded for the current user and not loading, don't reload unless forced
    if (_paymentMethods.isNotEmpty && !_isLoading && _currentUserId == currentUserId) {
      debugPrint('✅ Payment methods already loaded (${_paymentMethods.length}) for user $_currentUserId, skipping reload');
      return;
    }

    // Update current user ID
    _currentUserId = currentUserId;

    _setLoading(true);
    _clearError();

    try {
      // Try to load from API first
      debugPrint('🔍 Attempting to load payment methods from API...');
      final methods = await _paymentService.getPaymentMethods();
      _paymentMethods = methods;
      _useLocalStorage = false;
      _currentUserId = currentUserId; // Ensure user association is set
      debugPrint('✅ Successfully loaded ${methods.length} payment methods from API for user $currentUserId');
      notifyListeners();

      // Track successful load
      await _analyticsService.trackEvent(
        eventType: 'payment_methods_loaded',
        eventData: {'count': methods.length, 'source': 'api'},
      );

    } catch (e) {
      debugPrint('❌ API call failed: $e');
      // Gracefully handle 404 (endpoint not implemented yet) - use local storage temporarily
      if (e.toString().contains('Resource not found') ||
          e.toString().contains('404')) {
        debugPrint('ℹ️ Payment methods API not available - using local storage temporarily');

        // Load from local storage for current user (temporary fallback, don't set _useLocalStorage)
        try {
          final currentUserId = _getCurrentUserId();
          if (currentUserId != null) {
            final localMethods = await LocalPaymentStorage.loadPaymentMethods(currentUserId);
            _paymentMethods = localMethods;
            _currentUserId = currentUserId; // Ensure user association is set
            debugPrint('✅ Loaded ${localMethods.length} payment methods from local storage for user $currentUserId');
          } else {
            debugPrint('⚠️ No current user ID available for local storage');
            _paymentMethods = [];
            _currentUserId = null;
          }

          notifyListeners();

          // Track local storage usage
          final methodCount = currentUserId != null ? _paymentMethods.length : 0;
          await _analyticsService.trackEvent(
            eventType: 'payment_methods_loaded',
            eventData: {'count': methodCount, 'source': 'local'},
          );
        } catch (localError) {
          debugPrint('❌ Failed to load from local storage: $localError');
          _paymentMethods = [];
        }
      } else {
        final errorMessage = 'Failed to load payment methods: $e';
        _setError(errorMessage);
        debugPrint('❌ $errorMessage');
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<PaymentMethod?> addPaymentMethod({
    required String type,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String holderName,
    Map<String, dynamic>? billingAddress,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      PaymentMethod method;
      
      // Try API first if not in local storage mode
      if (!_useLocalStorage) {
        try {
          method = await _paymentService.addPaymentMethod(
            type: type,
            cardNumber: cardNumber,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cvc: cvc,
            holderName: holderName,
            billingAddress: billingAddress?.toString(),
          );
        } catch (e) {
          if (e.toString().contains('Resource not found') ||
              e.toString().contains('404')) {
            debugPrint('ℹ️ API not available - adding to local storage (temporary fallback)');
            // Don't set _useLocalStorage = true permanently, just use local storage for this operation
            final currentUserId = _getCurrentUserId();
            if (currentUserId != null) {
              method = await LocalPaymentStorage.addPaymentMethod(
                type: type,
                cardNumber: cardNumber,
                expiryMonth: expiryMonth,
                expiryYear: expiryYear,
                holderName: holderName,
                userId: currentUserId,
              );
            } else {
              throw Exception('No current user ID available for local payment method storage');
            }
          } else {
            rethrow;
          }
        }
      } else {
        // Use local storage
        final currentUserId = _getCurrentUserId();
        if (currentUserId != null) {
          method = await LocalPaymentStorage.addPaymentMethod(
            type: type,
            cardNumber: cardNumber,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            holderName: holderName,
            userId: currentUserId,
          );
        } else {
          throw Exception('No current user ID available for local payment method storage');
        }
      }

      _paymentMethods.add(method);
      debugPrint('✅ Added payment method to local list: ${method.id}, total methods: ${_paymentMethods.length}');

      // Track payment method addition
      await _analyticsService.trackEvent(
        eventType: 'payment_method_added',
        eventData: {
          'type': type, 
          'method_id': method.id,
          'source': _useLocalStorage ? 'local' : 'api',
        },
      );

      _setLoading(false);
      notifyListeners();
      debugPrint('✅ Payment method added successfully, returning: ${method.id}');
      return method;
    } catch (e) {
      debugPrint('❌ Payment method addition failed: $e');
      final errorMessage = 'Failed to add payment method: $e';
      _setError(errorMessage);

      // Track addition failure
      await _analyticsService.trackEvent(
        eventType: 'payment_method_add_failed',
        eventData: {'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<PaymentMethod?> updatePaymentMethod(
    String methodId,
    Map<String, dynamic> updates,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      PaymentMethod updatedMethod;
      
      if (_useLocalStorage) {
        final currentUserId = _getCurrentUserId();
        if (currentUserId != null) {
          updatedMethod = await LocalPaymentStorage.updatePaymentMethod(methodId, updates, currentUserId);
        } else {
          throw Exception('No current user ID available for local payment method update');
        }
      } else {
        try {
          updatedMethod = await _paymentService.updatePaymentMethod(methodId, updates);
        } catch (e) {
          if (e.toString().contains('Resource not found') ||
              e.toString().contains('404')) {
            debugPrint('ℹ️ API not available - updating in local storage (temporary fallback)');
            // Don't set _useLocalStorage = true permanently
            final currentUserId = _getCurrentUserId();
            if (currentUserId != null) {
              updatedMethod = await LocalPaymentStorage.updatePaymentMethod(methodId, updates, currentUserId);
            } else {
              throw Exception('No current user ID available for local payment method update');
            }
          } else {
            rethrow;
          }
        }
      }

      final index = _paymentMethods.indexWhere((m) => m.id == methodId);
      if (index != -1) {
        _paymentMethods[index] = updatedMethod;
      }

      // Track payment method update
      await _analyticsService.trackEvent(
        eventType: 'payment_method_updated',
        eventData: {
          'method_id': methodId,
          'source': _useLocalStorage ? 'local' : 'api',
        },
      );

      _setLoading(false);
      notifyListeners();
      return updatedMethod;
    } catch (e) {
      final errorMessage = 'Failed to update payment method: $e';
      _setError(errorMessage);

      // Track update failure
      await _analyticsService.trackEvent(
        eventType: 'payment_method_update_failed',
        eventData: {'method_id': methodId, 'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deletePaymentMethod(String methodId) async {
    _setLoading(true);
    _clearError();

    try {
      if (_useLocalStorage) {
        final currentUserId = _getCurrentUserId();
        if (currentUserId != null) {
          await LocalPaymentStorage.deletePaymentMethod(methodId, currentUserId);
        } else {
          throw Exception('No current user ID available for local payment method deletion');
        }
      } else {
        try {
          await _paymentService.deletePaymentMethod(methodId);
        } catch (e) {
          if (e.toString().contains('Resource not found') ||
              e.toString().contains('404')) {
            debugPrint('ℹ️ API not available - deleting from local storage (temporary fallback)');
            // Don't set _useLocalStorage = true permanently
            final currentUserId = _getCurrentUserId();
            if (currentUserId != null) {
              await LocalPaymentStorage.deletePaymentMethod(methodId, currentUserId);
            } else {
              throw Exception('No current user ID available for local payment method deletion');
            }
          } else {
            rethrow;
          }
        }
      }
      
      _paymentMethods.removeWhere((m) => m.id == methodId);

      // Track payment method deletion
      await _analyticsService.trackEvent(
        eventType: 'payment_method_deleted',
        eventData: {
          'method_id': methodId,
          'source': _useLocalStorage ? 'local' : 'api',
        },
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      final errorMessage = 'Failed to delete payment method: $e';
      _setError(errorMessage);

      // Track deletion failure
      await _analyticsService.trackEvent(
        eventType: 'payment_method_delete_failed',
        eventData: {'method_id': methodId, 'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultPaymentMethod(String methodId) async {
    _setLoading(true);
    _clearError();

    try {
      if (_useLocalStorage) {
        final currentUserId = _getCurrentUserId();
        if (currentUserId != null) {
          await LocalPaymentStorage.setDefaultPaymentMethod(methodId, currentUserId);
        } else {
          throw Exception('No current user ID available for setting default payment method');
        }
      } else {
        try {
          await _paymentService.setDefaultPaymentMethod(methodId);
        } catch (e) {
          if (e.toString().contains('Resource not found') ||
              e.toString().contains('404')) {
            debugPrint('ℹ️ API not available - setting default in local storage (temporary fallback)');
            // Don't set _useLocalStorage = true permanently
            final currentUserId = _getCurrentUserId();
            if (currentUserId != null) {
              await LocalPaymentStorage.setDefaultPaymentMethod(methodId, currentUserId);
            } else {
              throw Exception('No current user ID available for setting default payment method');
            }
          } else {
            rethrow;
          }
        }
      }

      // Update local state to reflect default method
      _paymentMethods = _paymentMethods.map((method) {
        return method.copyWith(isDefault: method.id == methodId);
      }).toList();

      // Track default payment method change
      await _analyticsService.trackEvent(
        eventType: 'default_payment_method_changed',
        eventData: {
          'method_id': methodId,
          'source': _useLocalStorage ? 'local' : 'api',
        },
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      final errorMessage = 'Failed to set default payment method: $e';
      _setError(errorMessage);

      // Track failure
      await _analyticsService.trackEvent(
        eventType: 'default_payment_method_change_failed',
        eventData: {'method_id': methodId, 'error': errorMessage},
      );

      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all payment method data (used on logout)
  void clearAllData() {
    _paymentMethods = [];
    _isLoading = false;
    _error = null;
    _useLocalStorage = false;
    _currentUserId = null; // Clear user association
    notifyListeners();
    debugPrint('🧹 Payment data cleared');
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
