import 'package:flutter/services.dart';

/// Utilities for credit card operations
class CardUtils {
  /// Detect credit card brand from card number
  static CardBrand detectCardBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    
    if (cleanNumber.isEmpty) return CardBrand.unknown;
    
    // Visa: starts with 4
    if (RegExp(r'^4').hasMatch(cleanNumber)) {
      return CardBrand.visa;
    }
    
    // Mastercard: starts with 51-55 or 2221-2720
    if (RegExp(r'^5[1-5]').hasMatch(cleanNumber) ||
        RegExp(r'^2(2[2-9][0-9]|[3-6][0-9]{2}|7[0-1][0-9]|720)').hasMatch(cleanNumber)) {
      return CardBrand.mastercard;
    }
    
    // American Express: starts with 34 or 37
    if (RegExp(r'^3[47]').hasMatch(cleanNumber)) {
      return CardBrand.amex;
    }
    
    // Discover: starts with 6011, 622126-622925, 644-649, or 65
    if (RegExp(r'^(6011|65|64[4-9]|622)').hasMatch(cleanNumber)) {
      return CardBrand.discover;
    }
    
    // Diners Club: starts with 36 or 38
    if (RegExp(r'^3[68]').hasMatch(cleanNumber)) {
      return CardBrand.diners;
    }
    
    // JCB: starts with 2131, 1800, or 35
    if (RegExp(r'^(2131|1800|35)').hasMatch(cleanNumber)) {
      return CardBrand.jcb;
    }
    
    return CardBrand.unknown;
  }
  
  /// Get card brand display name
  static String getCardBrandName(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.diners:
        return 'Diners Club';
      case CardBrand.jcb:
        return 'JCB';
      case CardBrand.unknown:
        return 'Card';
    }
  }
  
  /// Format card number with spaces
  static String formatCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    final brand = detectCardBrand(cleanNumber);
    
    // American Express: 4-6-5 format
    if (brand == CardBrand.amex) {
      if (cleanNumber.length <= 4) return cleanNumber;
      if (cleanNumber.length <= 10) {
        return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4)}';
      }
      return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4, 10)} ${cleanNumber.substring(10)}';
    }
    
    // Other cards: 4-4-4-4 format
    final buffer = StringBuffer();
    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanNumber[i]);
    }
    return buffer.toString();
  }
  
  /// Get maximum card number length for brand
  static int getMaxCardLength(CardBrand brand) {
    switch (brand) {
      case CardBrand.amex:
        return 15;
      case CardBrand.diners:
        return 14;
      default:
        return 16;
    }
  }
  
  /// Get maximum CVV length for brand
  static int getMaxCVVLength(CardBrand brand) {
    return brand == CardBrand.amex ? 4 : 3;
  }
  
  /// Validate card number using Luhn algorithm
  static bool validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    
    if (cleanNumber.isEmpty) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanNumber)) return false;
    
    final brand = detectCardBrand(cleanNumber);
    final maxLength = getMaxCardLength(brand);
    
    // Check length
    if (cleanNumber.length < 13 || cleanNumber.length > maxLength) {
      return false;
    }
    
    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }
  
  /// Mask card number showing only last 4 digits
  static String maskCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleanNumber.length < 4) return cardNumber;
    return '•••• •••• •••• ${cleanNumber.substring(cleanNumber.length - 4)}';
  }
  
  /// Format expiry date (MM/YY)
  static String formatExpiryDate(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleaned.isEmpty) return '';
    if (cleaned.length == 1) return cleaned;
    if (cleaned.length == 2) return cleaned;
    
    // Add slash after MM
    return '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
  }
  
  /// Validate expiry date
  static bool validateExpiryDate(String expiry) {
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(expiry)) {
      return false;
    }
    
    final parts = expiry.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]) + 2000; // Convert YY to YYYY
    
    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0); // Last day of expiry month
    
    return expiryDate.isAfter(now);
  }
  
  /// Check if card is expired
  static bool isCardExpired(String? expiryMonth, String? expiryYear) {
    if (expiryMonth == null || expiryYear == null) return true;
    
    try {
      final month = int.parse(expiryMonth);
      final year = int.parse(expiryYear.length == 2 ? '20$expiryYear' : expiryYear);
      
      final now = DateTime.now();
      final expiryDate = DateTime(year, month + 1, 0); // Last day of expiry month
      
      return expiryDate.isBefore(now);
    } catch (e) {
      return true;
    }
  }
}

/// Card brand enum
enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  diners,
  jcb,
  unknown,
}

/// Card number input formatter
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    
    // Detect card brand to determine max length
    final brand = CardUtils.detectCardBrand(digitsOnly);
    final maxLength = CardUtils.getMaxCardLength(brand);
    
    // Limit to max length
    final limitedDigits = digitsOnly.length > maxLength
        ? digitsOnly.substring(0, maxLength)
        : digitsOnly;
    
    // Format with spaces
    final formatted = CardUtils.formatCardNumber(limitedDigits);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Expiry date input formatter (MM/YY)
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 4 digits (MMYY)
    final limitedDigits = digitsOnly.length > 4
        ? digitsOnly.substring(0, 4)
        : digitsOnly;
    
    // Format as MM/YY
    String formatted = limitedDigits;
    if (limitedDigits.length >= 3) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// CVV input formatter
class CVVInputFormatter extends TextInputFormatter {
  final CardBrand cardBrand;
  
  CVVInputFormatter({this.cardBrand = CardBrand.unknown});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    
    // Limit based on card brand
    final maxLength = CardUtils.getMaxCVVLength(cardBrand);
    final limitedDigits = digitsOnly.length > maxLength
        ? digitsOnly.substring(0, maxLength)
        : digitsOnly;
    
    return TextEditingValue(
      text: limitedDigits,
      selection: TextSelection.collapsed(offset: limitedDigits.length),
    );
  }
}

