import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../models/booking.dart';
import '../providers/payment_state.dart';
import '../providers/app_state.dart';
import '../services/payment_api_service.dart';
import '../utils/theme.dart';
import '../utils/card_utils.dart';
import '../utils/routes.dart';
import 'payment_card_widget.dart';

/// Result of payment processing
class PaymentResult {
  final bool success;
  final bool isLocalPayment;

  const PaymentResult({
    required this.success,
    this.isLocalPayment = false,
  });
}

/// Dialog for processing payment for a booking
class PaymentProcessingDialog extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onSuccess;

  const PaymentProcessingDialog({
    super.key,
    required this.booking,
    this.onSuccess,
  });
  
  @override
  State<PaymentProcessingDialog> createState() => _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<PaymentProcessingDialog> {
  PaymentMethod? _selectedPaymentMethod;
  bool _isProcessing = false;
  String? _error;
  bool _paymentSuccess = false;
  
  @override
  void initState() {
    super.initState();
    // Delay loading to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentMethods();
    });
  }
  
  Future<void> _loadPaymentMethods() async {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    // Skip loading if we already have payment methods
    if (appState.payments.paymentMethods.isNotEmpty) {
      debugPrint('✅ Payment methods already loaded (${appState.payments.paymentMethods.length}), using existing data');

      // Still auto-select default payment method
      if (mounted) {
        final defaultMethod = appState.payments.paymentMethods
            .where((m) => m.isDefault && m.isActive && !CardUtils.isCardExpired(m.expiryMonth, m.expiryYear))
            .firstOrNull;

        if (defaultMethod != null) {
          setState(() {
            _selectedPaymentMethod = defaultMethod;
          });
        }
      }
      return;
    }

    try {
      debugPrint('🔄 Loading payment methods in dialog...');
      await appState.payments.loadPaymentMethods();

      // Auto-select default payment method
      if (mounted) {
        final defaultMethod = appState.payments.paymentMethods
            .where((m) => m.isDefault && m.isActive && !CardUtils.isCardExpired(m.expiryMonth, m.expiryYear))
            .firstOrNull;
        
        if (defaultMethod != null) {
          setState(() {
            _selectedPaymentMethod = defaultMethod;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
      // Continue without auto-selection
    }
  }
  
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() {
        _error = 'Please select a payment method';
      });
      return;
    }

    // Validate booking ID
    if (widget.booking.id.isEmpty) {
      setState(() {
        _error = 'Invalid booking ID';
        _isProcessing = false;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Check if we're using local storage payment methods
      final appState = Provider.of<AppState>(context, listen: false);
      final isLocalStorage = _selectedPaymentMethod!.id.startsWith('local_');

      if (isLocalStorage) {
        // For local storage payments, simulate success since we can't process via backend
        debugPrint('💳 Processing local storage payment (simulated)');

        // Update booking payment status locally
        final appState = Provider.of<AppState>(context, listen: false);
        final updatedBooking = widget.booking.copyWith(paymentStatus: PaymentStatus.paid);
        await appState.bookings.updateBookingLocally(updatedBooking);

        // Simulate payment processing delay
        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _paymentSuccess = true;
          _isProcessing = false;
        });

        // Wait a bit to show success animation
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.of(context).pop(const PaymentResult(success: true, isLocalPayment: true));
          widget.onSuccess?.call();
        }
        return;
      }

      final paymentService = PaymentService();
      await paymentService.processPayment(
        bookingId: widget.booking.id,
        paymentMethodId: _selectedPaymentMethod!.id,
        amount: widget.booking.finalPrice,
        currency: 'ZAR',
        description: 'Payment for booking ${widget.booking.id}',
      );
      
      setState(() {
        _paymentSuccess = true;
        _isProcessing = false;
      });
      
      // Wait a bit to show success animation
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(const PaymentResult(success: true, isLocalPayment: false));
        widget.onSuccess?.call();
      }
    } catch (e) {
      setState(() {
        _error = 'Payment failed: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: _paymentSuccess ? _buildSuccessView() : _buildPaymentView(),
      ),
    );
  }
  
  Widget _buildPaymentView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: SwiftLyftTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'For booking #${widget.booking.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: SwiftLyftTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(const PaymentResult(success: false)),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Amount section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SwiftLyftTheme.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount to Pay',
                        style: TextStyle(
                          fontSize: 14,
                          color: SwiftLyftTheme.mediumGray,
                        ),
                      ),
                      Text(
                        'R ${widget.booking.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: SwiftLyftTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: SwiftLyftTheme.mediumGray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.booking.pickupAddress} → ${widget.booking.dropoffAddress}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SwiftLyftTheme.mediumGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment method selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddPaymentMethod,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Payment methods list
            Consumer<AppState>(
              builder: (context, appState, child) {
                if (appState.payments.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final activeMethods = appState.payments.paymentMethods
                    .where((m) => m.isActive && !CardUtils.isCardExpired(m.expiryMonth, m.expiryYear))
                    .toList();
                
                if (activeMethods.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: SwiftLyftTheme.lightGray),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.credit_card_off,
                          size: 48,
                          color: SwiftLyftTheme.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No payment methods available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a payment method to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: SwiftLyftTheme.mediumGray,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddPaymentMethod,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Payment Method'),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: activeMethods.map((method) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CompactPaymentCardWidget(
                        paymentMethod: method,
                        isSelected: _selectedPaymentMethod?.id == method.id,
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = method;
                            _error = null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(const PaymentResult(success: false)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_isProcessing || _selectedPaymentMethod == null)
                        ? null
                        : _processPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: SwiftLyftTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Pay R ${widget.booking.finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: SwiftLyftTheme.successGreen,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your payment of R ${widget.booking.finalPrice.toStringAsFixed(2)} has been processed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAddPaymentMethod() {
    // Close dialog and navigate to payment methods screen
    Navigator.of(context).pop(const PaymentResult(success: false));
    Navigator.pushNamed(context, AppRoutes.paymentMethods);
  }
}

/// Show payment processing dialog
Future<PaymentResult> showPaymentDialog(BuildContext context, Booking booking) async {
  final result = await showDialog<PaymentResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PaymentProcessingDialog(
      booking: booking,
    ),
  );

  return result ?? const PaymentResult(success: false);
}

