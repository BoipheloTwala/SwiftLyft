import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/quote_action_dialog.dart';
import '../utils/quote_status_helper.dart';
import '../utils/quote_pricing_helper.dart';
import '../providers/app_state.dart';
import '../models/quote.dart';
import '../models/payment.dart';

class QuoteDetailsScreen extends StatefulWidget {
  final String quoteId;

  const QuoteDetailsScreen({
    super.key,
    required this.quoteId,
  });

  @override
  State<QuoteDetailsScreen> createState() => _QuoteDetailsScreenState();
}

class _QuoteDetailsScreenState extends State<QuoteDetailsScreen> {
  Quote? _quote;
  bool _isLoading = true;
  String? _error;
  String? _selectedPaymentMethodId;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final quote = await appState.getQuoteById(widget.quoteId);

      if (quote != null) {
        setState(() {
          _quote = quote;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Quote not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load quote: $e';
        _isLoading = false;
      });
    }
  }

  void _showQuoteActionDialog() {
    if (_quote == null) return;
    
    showDialog(
      context: context,
      builder: (context) => QuoteActionDialog(
        quote: _quote!,
        onAction: _handleQuoteAction,
      ),
    );
  }

  Future<void> _handleQuoteAction(String action, String? notes) async {
    if (_quote == null) return;

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      bool success = false;

      if (action == 'accept') {
        success = await appState.acceptQuote(_quote!.id, notes: notes);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quote acceptance request sent! We will contact you shortly.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          
          // Refresh data
          await Future.wait([
            appState.loadLoyalty(),
            appState.loadStats(),
          ]);
        }
      } else if (action == 'cancel') {
        success = await appState.cancelQuote(_quote!.id, reason: notes);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quote cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (success) {
        _loadQuote(); // Reload the quote to get updated status
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action quote. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptQuote() async {
    if (_quote == null || _selectedPaymentMethodId == null) return;

    setState(() {
      _isAccepting = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.acceptQuote(_quote!.id);

      // Refresh loyalty and stats after successful booking since points/tier/totalSpent may change
      await Future.wait([
        appState.loadLoyalty(),
        appState.loadStats(),
      ]);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Quote accepted successfully! A driver will be assigned shortly.'),
            backgroundColor: SwiftLyftTheme.successGreen,
            duration: Duration(seconds: 4),
          ),
        );

        // Navigate back to quotes list
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final paymentMethods = appState.paymentMethods;

        return UnifiedNavigation.buildScaffold(
          context: context,
          currentRoute: AppRoutes.quoteDetails,
          appBar: UnifiedAppBar.buildResponsive(
            context: context,
            title: 'Quote Details',
            subtitle: _quote?.id ?? 'Loading...',
            showBackButton: true,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : _buildQuoteDetails(paymentMethods),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: SwiftLyftTheme.mediumGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load quote',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadQuote,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteDetails(List<PaymentMethod> paymentMethods) {
    if (_quote == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote Header
          _buildQuoteHeader(),

          const SizedBox(height: 24),

          // Trip Details
          _buildTripDetails(),

          const SizedBox(height: 24),

          // Pricing
          _buildPricingDetails(),

          const SizedBox(height: 24),

          // Payment Method Selection
          _buildPaymentMethodSelection(paymentMethods),

          const SizedBox(height: 24),

          // Accept Quote Button
          _buildAcceptButton(),

          const SizedBox(height: 24),

          // Terms and Conditions
          _buildTermsAndConditions(),
        ],
      ),
    );
  }

  Widget _buildQuoteHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: SwiftLyftTheme.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quote #${_quote!.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Valid until: ${_formatDate(_quote!.expiresAt)}',
                      style: const TextStyle(
                        color: SwiftLyftTheme.mediumGray,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(_quote!.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = QuoteStatusHelper.getStatusColor(status);
    final icon = QuoteStatusHelper.getStatusIcon(status);
    final text = QuoteStatusHelper.getStatusDisplayName(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Pickup Location
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: SwiftLyftTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _quote!.pickupLocation['address'] ??
                          'Address not available',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          const SizedBox(height: 16),

          // Dropoff Location
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: SwiftLyftTheme.accentPurple,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dropoff',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _quote!.dropoffLocation['address'] ??
                          'Address not available',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          const SizedBox(height: 16),

          // Date & Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: SwiftLyftTheme.secondaryTeal,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_formatDate(_quote!.scheduledDate)} at ${_formatTime(_quote!.scheduledDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          const SizedBox(height: 16),

          // Passengers
          Row(
            children: [
              const Icon(
                Icons.people,
                color: SwiftLyftTheme.successGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Passengers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_quote!.passengerCount} passenger${_quote!.passengerCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_quote!.specialNotes != null &&
              _quote!.specialNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Special Notes
            Row(
              children: [
                const Icon(
                  Icons.note,
                  color: SwiftLyftTheme.warmOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _quote!.specialNotes!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingDetails() {
    // Get adjusted pricing for luxury service display
    final adjusted = _quote!.adjustedPricing;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Base Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base Fare'),
              Text('R${(adjusted['baseFare'] ?? 0.0).toStringAsFixed(2)}'),
            ],
          ),

          const SizedBox(height: 8),

          // Distance Fee (if applicable)
          if ((adjusted['distanceFare'] ?? 0.0) > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Distance Charge'),
                Text('R${(adjusted['distanceFare'] ?? 0.0).toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Time Fee (if applicable)
          if ((adjusted['timeFare'] ?? 0.0) > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Time Charge'),
                Text('R${(adjusted['timeFare'] ?? 0.0).toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Service Fee (if applicable)
          if ((adjusted['serviceFee'] ?? 0.0) > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service Fee'),
                Text('R${(adjusted['serviceFee'] ?? 0.0).toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Protection Officer Fee
          if (_quote!.closeProtectionOfficer) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Close Protection Officer'),
                Text('R${(adjusted['protectionOfficerFee'] ?? 500.0).toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Taxes
          if ((adjusted['taxes'] ?? 0.0) > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Taxes (15% VAT)'),
                Text('R${(adjusted['taxes'] ?? 0.0).toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
          ],

          const Divider(),

          const SizedBox(height: 8),

          // Loyalty discount (if applicable)
          Builder(
            builder: (context) {
              final l = Provider.of<AppState>(context, listen: false).loyaltyInfo;
              if (l == null || l.tierDiscount <= 0) return const SizedBox.shrink();
              final adjustedTotal = (adjusted['total'] ?? 0.0).toDouble();
              final discountAmount = adjustedTotal * l.tierDiscount;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Loyalty Discount (${(l.tierDiscount * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: SwiftLyftTheme.successGreen)),
                      Text('-R${discountAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: SwiftLyftTheme.successGreen)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Builder(
                builder: (context) {
                  final l = Provider.of<AppState>(context, listen: false).loyaltyInfo;
                  final adjustedTotal = (adjusted['total'] ?? 0.0).toDouble();
                  final total = l == null ? adjustedTotal : (adjustedTotal * (1 - l.tierDiscount));
                  return Text(
                    'R${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.primaryBlue,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection(List<PaymentMethod> paymentMethods) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (paymentMethods.isEmpty) ...[
            const Text('No payment methods available. Please add one first.'),
          ] else ...[
            RadioGroup<String>(
              groupValue: _selectedPaymentMethodId,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPaymentMethodId = value;
                  });
                }
              },
              child: Column(
                children: paymentMethods
                    .map((method) => RadioListTile<String>(
                          title: Text(_getPaymentMethodDisplayName(method)),
                          subtitle:
                              method.isDefault ? const Text('Default') : null,
                          value: method.id,
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptButton() {
    if (_quote == null) return const SizedBox.shrink();
    
    final status = _quote!.status.toLowerCase();
    final isExpired = _quote!.isExpired;
    
    // Show action buttons only for quoted status
    if (status == 'quoted' && !isExpired) {
      return _buildQuoteActionButtons();
    }
    
    // Show legacy accept button for pending status with payment method
    if (status == 'pending' && !isExpired && _selectedPaymentMethodId != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_isAccepting) ? null : _acceptQuote,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: SwiftLyftTheme.successGreen,
            disabledBackgroundColor: SwiftLyftTheme.mediumGray,
          ),
          child: _isAccepting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Accept Quote & Book Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    }
    
    // Show status message for non-actionable quotes
    return _buildStatusMessage();
  }
  
  Widget _buildQuoteActionButtons() {
    return Column(
      children: [
        // Time remaining indicator
        if (_quote!.validUntil != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  QuoteStatusHelper.getTimeRemaining(_quote!.validUntil),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showQuoteActionDialog,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.how_to_vote),
            label: const Text(
              'Accept or Cancel Quote',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusMessage() {
    if (_quote == null) return const SizedBox.shrink();
    
    String message;
    IconData icon;
    Color color;
    
    if (_quote!.isExpired) {
      message = 'This quote has expired';
      icon = Icons.event_busy;
      color = Colors.grey;
    } else if (_quote!.status.toLowerCase() == 'pending') {
      message = 'Waiting for quote from SwiftLyft';
      icon = Icons.hourglass_empty;
      color = Colors.orange;
    } else if (_quote!.status.toLowerCase() == 'accepted') {
      message = 'Quote accepted! Booking in progress.';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (_quote!.status.toLowerCase() == 'cancelled') {
      message = 'This quote has been cancelled';
      icon = Icons.cancel;
      color = Colors.red;
    } else {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'By accepting this quote, you agree to our terms and conditions. '
        'The booking will be confirmed immediately and payment will be processed. '
        'Cancellation fees may apply.',
        style: TextStyle(
          fontSize: 12,
          color: SwiftLyftTheme.mediumGray,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  String _getPaymentMethodDisplayName(PaymentMethod method) {
    if (method.type == 'card' && method.cardNumber.isNotEmpty) {
      final last4 = method.cardNumber.length >= 4
          ? method.cardNumber.substring(method.cardNumber.length - 4)
          : method.cardNumber;
      final brand = method.brand ?? 'Card';
      return '$brand **** $last4';
    }
    return method.holderName ?? method.type;
  }
}
