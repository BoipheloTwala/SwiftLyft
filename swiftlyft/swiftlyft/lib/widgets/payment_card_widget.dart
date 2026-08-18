import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../utils/card_utils.dart';
import '../utils/theme.dart';

/// A widget to display a payment card with beautiful UI
class PaymentCardWidget extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;
  final bool isSelected;
  final bool showActions;
  
  const PaymentCardWidget({
    super.key,
    required this.paymentMethod,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
    this.isSelected = false,
    this.showActions = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final brand = CardUtils.detectCardBrand(paymentMethod.cardNumber);
    final isExpired = CardUtils.isCardExpired(
      paymentMethod.expiryMonth, 
      paymentMethod.expiryYear,
    );
    
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? const BorderSide(color: SwiftLyftTheme.primaryBlue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getCardGradient(brand),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Card brand icon
                  _buildCardBrandIcon(brand),
                  
                  // Actions menu
                  if (showActions)
                    _buildActionsMenu(context),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Card number
              Text(
                paymentMethod.maskedCardNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cardholder name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARDHOLDER',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paymentMethod.holderName?.toUpperCase() ?? 'NO NAME',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Expiry date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPIRES',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${paymentMethod.expiryMonth}/${paymentMethod.expiryYear}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isExpired ? Colors.red.shade300 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Badges
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (paymentMethod.isDefault)
                    _buildBadge('DEFAULT', Colors.green),
                  if (isExpired)
                    _buildBadge('EXPIRED', Colors.red),
                  if (!paymentMethod.isActive)
                    _buildBadge('INACTIVE', Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardBrandIcon(CardBrand brand) {
    IconData icon;
    switch (brand) {
      case CardBrand.visa:
        icon = Icons.credit_card;
        break;
      case CardBrand.mastercard:
        icon = Icons.credit_card;
        break;
      case CardBrand.amex:
        icon = Icons.credit_card;
        break;
      default:
        icon = Icons.credit_card;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            CardUtils.getCardBrandName(brand).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'set_default':
            onSetDefault?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      icon: const Icon(Icons.more_vert, color: Colors.white),
      itemBuilder: (context) => [
        if (!paymentMethod.isDefault && onSetDefault != null)
          const PopupMenuItem(
            value: 'set_default',
            child: Row(
              children: [
                Icon(Icons.star, size: 18),
                SizedBox(width: 8),
                Text('Set as Default'),
              ],
            ),
          ),
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Remove', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  LinearGradient _getCardGradient(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardBrand.mastercard:
        return const LinearGradient(
          colors: [Color(0xFFEB001B), Color(0xFFF79E1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardBrand.amex:
        return const LinearGradient(
          colors: [Color(0xFF006FCF), Color(0xFF0099CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardBrand.discover:
        return const LinearGradient(
          colors: [Color(0xFFFF6000), Color(0xFFFF9900)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [SwiftLyftTheme.deepCharcoal, SwiftLyftTheme.mediumGray],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

/// A compact card widget for selection lists
class CompactPaymentCardWidget extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final bool isSelected;
  final VoidCallback? onTap;
  
  const CompactPaymentCardWidget({
    super.key,
    required this.paymentMethod,
    this.isSelected = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final brand = CardUtils.detectCardBrand(paymentMethod.cardNumber);
    final isExpired = CardUtils.isCardExpired(
      paymentMethod.expiryMonth,
      paymentMethod.expiryYear,
    );
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: SwiftLyftTheme.primaryBlue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isExpired ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Radio/Checkbox
              if (onTap != null)
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? SwiftLyftTheme.primaryBlue : Colors.grey,
                  size: 24,
                ),
              
              if (onTap != null) const SizedBox(width: 12),
              
              // Card icon
              Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  gradient: _getCardGradient(brand),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.credit_card, color: Colors.white, size: 16),
              ),
              
              const SizedBox(width: 12),
              
              // Card details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${CardUtils.getCardBrandName(brand)} •••• ${paymentMethod.cardNumber.substring(paymentMethod.cardNumber.length - 4)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Expires ${paymentMethod.expiryMonth}/${paymentMethod.expiryYear}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? Colors.red : SwiftLyftTheme.mediumGray,
                          ),
                        ),
                        if (paymentMethod.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SwiftLyftTheme.successGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  LinearGradient _getCardGradient(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        );
      case CardBrand.mastercard:
        return const LinearGradient(
          colors: [Color(0xFFEB001B), Color(0xFFF79E1B)],
        );
      case CardBrand.amex:
        return const LinearGradient(
          colors: [Color(0xFF006FCF), Color(0xFF0099CC)],
        );
      default:
        return LinearGradient(
          colors: [SwiftLyftTheme.deepCharcoal, SwiftLyftTheme.mediumGray],
        );
    }
  }
}

