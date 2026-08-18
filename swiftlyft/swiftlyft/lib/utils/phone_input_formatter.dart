import 'package:flutter/services.dart';

/// South Africa phone input formatter (lenient):
/// - Allows either local leading '0' or international '+27'
/// - Does NOT auto-prefix '+27' or convert '0' while typing
/// - Strips non-digits except leading '+'
class SouthAfricaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;

    // Allow clearing the field
    if (raw.isEmpty) {
      return newValue;
    }

    // Normalize: keep '+' if present, otherwise only digits
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (i == 0 && ch == '+') {
        buffer.write(ch);
      } else if (RegExp(r'\d').hasMatch(ch)) {
        buffer.write(ch);
      }
    }
    final normalized = buffer.toString();

    // Place cursor at end to avoid jumpiness
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}

/// Helper to normalize an existing phone string to +27 format
String normalizeToZaPhone(String? input) {
  if (input == null || input.isEmpty) return '';
  final chars = input.trim();
  final buffer = StringBuffer();
  for (int i = 0; i < chars.length; i++) {
    final ch = chars[i];
    if (i == 0 && ch == '+') {
      buffer.write(ch);
    } else if (RegExp(r'\d').hasMatch(ch)) {
      buffer.write(ch);
    }
  }
  var normalized = buffer.toString();
  if (normalized.isEmpty) return '';
  if (normalized.startsWith('0')) {
    normalized = '+27${normalized.substring(1)}';
  } else if (!normalized.startsWith('+')) {
    if (normalized.startsWith('27')) {
      normalized = '+$normalized';
    } else {
      normalized = '+27$normalized';
    }
  }
  return normalized;
}


