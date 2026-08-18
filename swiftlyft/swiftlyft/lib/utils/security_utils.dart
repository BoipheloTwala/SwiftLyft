import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../utils/constants.dart';

/// Security utilities for input sanitization, encryption, and security measures
class SecurityUtils {
  // Input sanitization
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    // Remove ASCII control characters except common whitespace, then trim
    final cleaned = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    return cleaned.trim();
  }

  // Sanitize HTML content
  static String sanitizeHtml(String html) {
    // Remove script tags and other dangerous elements
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<object[^>]*>.*?</object>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<embed[^>]*>.*?</embed>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<form[^>]*>.*?</form>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<input[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<textarea[^>]*>.*?</textarea>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<select[^>]*>.*?</select>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<button[^>]*>.*?</button>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<link[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<link[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<base[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<bgsound[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<command[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<details[^>]*>.*?</details>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<dialog[^>]*>.*?</dialog>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<fieldset[^>]*>.*?</fieldset>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<keygen[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<legend[^>]*>.*?</legend>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<menu[^>]*>.*?</menu>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<menuitem[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<optgroup[^>]*>.*?</optgroup>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<option[^>]*>.*?</option>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<output[^>]*>.*?</output>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<progress[^>]*>.*?</progress>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<source[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<track[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<video[^>]*>.*?</video>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<audio[^>]*>.*?</audio>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<canvas[^>]*>.*?</canvas>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<svg[^>]*>.*?</svg>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<math[^>]*>.*?</math>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<applet[^>]*>.*?</applet>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<area[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<basefont[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<bdo[^>]*>.*?</bdo>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<big[^>]*>.*?</big>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<blink[^>]*>.*?</blink>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<center[^>]*>.*?</center>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<cite[^>]*>.*?</cite>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<code[^>]*>.*?</code>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<del[^>]*>.*?</del>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<dfn[^>]*>.*?</dfn>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<dir[^>]*>.*?</dir>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<em[^>]*>.*?</em>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<font[^>]*>.*?</font>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<ins[^>]*>.*?</ins>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<kbd[^>]*>.*?</kbd>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<label[^>]*>.*?</label>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<map[^>]*>.*?</map>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<nobr[^>]*>.*?</nobr>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<noembed[^>]*>.*?</noembed>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<noframes[^>]*>.*?</noframes>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<noscript[^>]*>.*?</noscript>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<param[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<plaintext[^>]*>.*?</plaintext>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<q[^>]*>.*?</q>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<s[^>]*>.*?</s>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<samp[^>]*>.*?</samp>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<small[^>]*>.*?</small>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<strike[^>]*>.*?</strike>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<strong[^>]*>.*?</strong>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<sub[^>]*>.*?</sub>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<sup[^>]*>.*?</sup>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<tt[^>]*>.*?</tt>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<u[^>]*>.*?</u>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<var[^>]*>.*?</var>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<wbr[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<xmp[^>]*>.*?</xmp>', caseSensitive: false, dotAll: true), '');
  }

  // Validate file type
  static bool isValidFileType(String fileName, List<String> allowedTypes) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedTypes.contains(extension);
  }

  // Validate file size
  static bool isValidFileSize(int bytes, int maxSizeMB) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return bytes <= maxSizeBytes;
  }

  // Generate secure random string
  static String generateSecureRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Generate secure random bytes
  static Uint8List generateSecureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  // Hash password with salt
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate salt
  static String generateSalt() {
    return generateSecureRandomString(32);
  }

  // Verify password
  static bool verifyPassword(String password, String hashedPassword, String salt) {
    final hashedInput = hashPassword(password, salt);
    return hashedInput == hashedPassword;
  }

  // Encrypt sensitive data (basic implementation)
  static String encryptData(String data, String key) {
    // In a real app, use proper encryption like AES
    final bytes = utf8.encode(data + key);
    final digest = sha256.convert(bytes);
    return base64.encode(utf8.encode(digest.toString()));
  }

  // Decrypt sensitive data (basic implementation)
  static String decryptData(String encryptedData, String key) {
    // In a real app, use proper decryption
    try {
      final decoded = base64.decode(encryptedData);
      return utf8.decode(decoded);
    } catch (e) {
      return '';
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return ValidationPatterns.emailPattern.hasMatch(email);
  }

  // Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    return ValidationPatterns.phonePattern.hasMatch(phone);
  }

  // Validate password strength
  static bool isStrongPassword(String password) {
    return ValidationPatterns.passwordPattern.hasMatch(password);
  }

  // Validate name format
  static bool isValidName(String name) {
    return ValidationPatterns.namePattern.hasMatch(name);
  }

  // Validate credit card number
  static bool isValidCreditCard(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!ValidationPatterns.creditCardPattern.hasMatch(cleanNumber)) {
      return false;
    }
    return _isValidLuhn(cleanNumber);
  }

  // Validate CVV
  static bool isValidCVV(String cvv) {
    return ValidationPatterns.cvvPattern.hasMatch(cvv);
  }

  // Validate expiry date
  static bool isValidExpiryDate(String expiryDate) {
    if (!ValidationPatterns.expiryDatePattern.hasMatch(expiryDate)) {
      return false;
    }
    
    final parts = expiryDate.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;
    
    return year > currentYear || (year == currentYear && month >= currentMonth);
  }

  // Luhn algorithm for credit card validation
  static bool _isValidLuhn(String number) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }

  // Rate limiting helper
  static bool isRateLimited(Map<String, dynamic> rateLimitData, int maxRequests, int timeWindowMinutes) {
    final now = DateTime.now();
    final requests = rateLimitData['requests'] as List<DateTime>? ?? [];
    
    // Remove old requests outside the time window
    requests.removeWhere((time) => now.difference(time).inMinutes > timeWindowMinutes);
    
    // Check if limit exceeded
    if (requests.length >= maxRequests) {
      return true;
    }
    
    // Add current request
    requests.add(now);
    rateLimitData['requests'] = requests;
    
    return false;
  }

  // Generate CSRF token
  static String generateCSRFToken() {
    return generateSecureRandomString(32);
  }

  // Validate CSRF token
  static bool validateCSRFToken(String token, String expectedToken) {
    return token == expectedToken;
  }

  // Sanitize URL
  static String sanitizeUrl(String url) {
    if (url.isEmpty) return url;
    
    // Only allow http and https protocols
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return '';
    }
    
    // Remove potentially dangerous characters
    return url
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }

  // Validate and sanitize JSON
  static Map<String, dynamic>? validateAndSanitizeJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return _sanitizeJsonObject(json);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _sanitizeJsonObject(Map<String, dynamic> obj) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in obj.entries) {
      final key = sanitizeInput(entry.key);
      final value = entry.value;
      
      if (value is String) {
        sanitized[key] = sanitizeInput(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeJsonObject(value);
      } else if (value is List) {
        sanitized[key] = _sanitizeJsonArray(value);
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  static List<dynamic> _sanitizeJsonArray(List<dynamic> array) {
    return array.map((item) {
      if (item is String) {
        return sanitizeInput(item);
      } else if (item is Map<String, dynamic>) {
        return _sanitizeJsonObject(item);
      } else if (item is List) {
        return _sanitizeJsonArray(item);
      } else {
        return item;
      }
    }).toList();
  }
} 