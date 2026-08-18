import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../utils/validators.dart';
import '../utils/card_utils.dart';
import '../services/payment_api_service.dart';
import '../models/payment.dart';
import '../providers/payment_state.dart';
import '../providers/app_state.dart';
import '../widgets/payment_card_widget.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentMethods();
    });
  }

  Future<void> _loadPaymentMethods() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Only load if we don't have payment methods yet or if forced refresh
    if (appState.payments.paymentMethods.isNotEmpty) {
      debugPrint('✅ Payment methods already loaded (${appState.payments.paymentMethods.length}), skipping reload');
      return;
    }

    debugPrint('🔄 Loading payment methods...');
    await appState.payments.loadPaymentMethods();
    debugPrint('✅ Payment methods loaded: ${appState.payments.paymentMethods.length} methods');
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.paymentMethods,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Payment Methods',
        subtitle: 'Manage your payment options',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPaymentMethods,
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.payments.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading payment methods...'),
                  ],
                ),
              );
            }

            if (appState.payments.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: SwiftLyftTheme.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appState.payments.error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadPaymentMethods,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildAddPaymentMethodButton(),
                    const SizedBox(height: 24),
                    _buildPaymentMethodsList(appState.payments.paymentMethods),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final activeCount = appState.payments.paymentMethods
            .where((m) => m.isActive && !CardUtils.isCardExpired(m.expiryMonth, m.expiryYear))
            .length;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Payment Methods',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$activeCount active card${activeCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                color: SwiftLyftTheme.mediumGray,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddPaymentMethodButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showAddPaymentMethod,
        icon: const Icon(Icons.add),
        label: const Text('Add New Card'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: SwiftLyftTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(List<PaymentMethod> methods) {
    if (methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          border: Border.all(color: SwiftLyftTheme.lightGray),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 80,
              color: SwiftLyftTheme.mediumGray.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No payment methods added',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a payment method to make bookings easier and faster',
              style: TextStyle(
                fontSize: 14,
                color: SwiftLyftTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: methods.map((method) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PaymentCardWidget(
            paymentMethod: method,
            onSetDefault: !method.isDefault
                ? () => _setDefaultPaymentMethod(method)
                : null,
            onEdit: () => _editPaymentMethod(method),
            onDelete: () => _confirmRemovePaymentMethod(method),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _setDefaultPaymentMethod(PaymentMethod method) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.payments.setDefaultPaymentMethod(method.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Default payment method updated'
              : 'Failed to update default payment method'),
          backgroundColor: success ? SwiftLyftTheme.successGreen : SwiftLyftTheme.errorRed,
        ),
      );
    }
  }

  void _editPaymentMethod(PaymentMethod method) {
    _showAddPaymentMethod(paymentMethod: method);
  }

  Future<void> _confirmRemovePaymentMethod(PaymentMethod method) async {
    final cardBrand = CardUtils.detectCardBrand(method.cardNumber);
    final last4 = method.cardNumber.length >= 4
        ? method.cardNumber.substring(method.cardNumber.length - 4)
        : method.cardNumber;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: SwiftLyftTheme.errorRed),
            SizedBox(width: 12),
            Text('Remove Card?'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${CardUtils.getCardBrandName(cardBrand)} ending in $last4?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: SwiftLyftTheme.errorRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final appState = Provider.of<AppState>(context, listen: false);
      final success = await appState.payments.deletePaymentMethod(method.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Payment method removed'
                : 'Failed to remove payment method'),
            backgroundColor: success ? SwiftLyftTheme.successGreen : SwiftLyftTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showAddPaymentMethod({PaymentMethod? paymentMethod}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _AddPaymentMethodSheet(
          paymentMethod: paymentMethod,
          onSaved: () {
            // PaymentState should have already updated its internal state
            // No need to reload - just close the dialog
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _AddPaymentMethodSheet extends StatefulWidget {
  final PaymentMethod? paymentMethod;
  final VoidCallback onSaved;

  const _AddPaymentMethodSheet({
    this.paymentMethod,
    required this.onSaved,
  });

  @override
  State<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  CardBrand _detectedCardBrand = CardBrand.unknown;

  @override
  void initState() {
    super.initState();
    
    // Add listener for card brand detection
    _cardNumberController.addListener(_detectCardBrand);
    
    if (widget.paymentMethod != null) {
      // For editing, show masked card number initially (user can clear and enter new one)
      if (widget.paymentMethod!.cardNumber.isNotEmpty) {
        final last4 = widget.paymentMethod!.cardNumber.length >= 4
            ? widget.paymentMethod!.cardNumber.substring(widget.paymentMethod!.cardNumber.length - 4)
            : widget.paymentMethod!.cardNumber;
        _cardNumberController.text = '•••• •••• •••• $last4';
      }
      _nameController.text = widget.paymentMethod!.holderName ?? '';
      if (widget.paymentMethod!.expiryMonth != null && widget.paymentMethod!.expiryYear != null) {
        // Format expiry with leading zeros
        final month = widget.paymentMethod!.expiryMonth!.padLeft(2, '0');
        final year = widget.paymentMethod!.expiryYear!.length == 4 
            ? widget.paymentMethod!.expiryYear!.substring(2) 
            : widget.paymentMethod!.expiryYear!;
        _expiryController.text = '$month/$year';
      }
      // Don't pre-fill CVV for security (user must enter it)
    }
  }
  
  void _detectCardBrand() {
    final brand = CardUtils.detectCardBrand(_cardNumberController.text);
    if (brand != _detectedCardBrand) {
      setState(() {
        _detectedCardBrand = brand;
      });
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.paymentMethod == null ? 'Add Payment Method' : 'Edit Payment Method',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                prefixIcon: const Icon(Icons.credit_card),
                suffixIcon: _detectedCardBrand != CardBrand.unknown
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Chip(
                          label: Text(
                            CardUtils.getCardBrandName(_detectedCardBrand),
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                        ),
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [CardNumberInputFormatter()],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Card number is required';
                }
                // Allow masked format for editing (but user should enter new number)
                if (value.contains('••••')) {
                  return 'Please enter the full card number';
                }
                if (!CardUtils.validateCardNumber(value)) {
                  return 'Please enter a valid card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      prefixIcon: Icon(Icons.calendar_today),
                      hintText: '12/25',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [ExpiryDateInputFormatter()],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (!CardUtils.validateExpiryDate(value)) {
                        return 'Invalid or expired';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      prefixIcon: Icon(Icons.security),
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CVVInputFormatter(cardBrand: _detectedCardBrand)],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final expected = CardUtils.getMaxCVVLength(_detectedCardBrand);
                      if (value.length != expected) {
                        return '$expected digits';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                prefixIcon: Icon(Icons.person),
                hintText: 'John Doe',
              ),
              textCapitalization: TextCapitalization.words,
              validator: Validators.validateName,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePaymentMethod,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.paymentMethod == null ? 'Add Payment Method' : 'Update Payment Method'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: SwiftLyftTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();
    final name = _nameController.text.trim();
    
    final expiryParts = expiry.split('/');

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      if (widget.paymentMethod == null) {
        // Add new payment method
        await appState.payments.addPaymentMethod(
          type: 'card',
          cardNumber: cardNumber,
          expiryMonth: expiryParts[0],
          expiryYear: expiryParts[1],
          cvc: cvv,
          holderName: name,
        );
      } else {
        // Update existing payment method
        // Check if card number was changed (not masked format)
        final isCardNumberChanged = !cardNumber.contains('••••');
        final cardNumberToUse = isCardNumberChanged 
            ? cardNumber 
            : widget.paymentMethod!.cardNumber;
        
        // Build update map with all changed fields
        final updates = <String, dynamic>{
          'holderName': name,
        };
        
        // Only update card details if they were actually changed
        if (isCardNumberChanged) {
          updates['cardNumber'] = cardNumberToUse;
          // Detect brand from new card number
          final brand = CardUtils.detectCardBrand(cardNumberToUse);
          updates['brand'] = CardUtils.getCardBrandName(brand).toLowerCase();
        }
        
        if (expiryParts.length == 2) {
          updates['expiryMonth'] = expiryParts[0].padLeft(2, '0');
          // Convert 2-digit year to 4-digit if needed
          final year = expiryParts[1];
          final expiryYear = year.length == 2 
              ? '20$year'  // Assume 20xx for 2-digit years
              : year;
          updates['expiryYear'] = expiryYear;
        }
        
        await appState.payments.updatePaymentMethod(
          widget.paymentMethod!.id,
          updates,
        );
      }
      
      widget.onSaved();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.paymentMethod == null 
              ? 'Payment method added successfully' 
              : 'Payment method updated successfully'),
            backgroundColor: SwiftLyftTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: SwiftLyftTheme.errorRed,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _savePaymentMethod,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 