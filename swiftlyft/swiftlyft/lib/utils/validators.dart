import '../utils/constants.dart';
import '../utils/security_utils.dart';

/// Enhanced validators with security integration and comprehensive error handling
class Validators {
  // Email validation with security checks
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Sanitize input first
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    if (sanitizedValue != value) {
      return 'Email contains invalid characters';
    }
    
    // Check length
    if (sanitizedValue.length > 254) {
      return 'Email is too long';
    }
    
    // Use security utility for validation
    if (!SecurityUtils.isValidEmail(sanitizedValue)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation with security checks
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    // Check minimum length
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters long';
    }
    
    // Check maximum length
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password is too long';
    }
    
    // Use security utility for strength validation
    if (!SecurityUtils.isStrongPassword(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character';
    }
    
    return null;
  }

  // Phone number validation (South African format) with security checks
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    
    // Use security utility for validation
    if (!SecurityUtils.isValidPhoneNumber(sanitizedValue)) {
      return 'Please enter a valid South African phone number';
    }
    
    return null;
  }

  // Name validation with security checks
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value.trim());
    
    // Check minimum length
    if (sanitizedValue.length < AppConstants.minNameLength) {
      return 'Name must be at least ${AppConstants.minNameLength} characters long';
    }
    
    // Check maximum length
    if (sanitizedValue.length > AppConstants.maxNameLength) {
      return 'Name is too long';
    }
    
    // Use security utility for validation
    if (!SecurityUtils.isValidName(sanitizedValue)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // Address validation with security checks
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value.trim());
    
    // Check minimum length
    if (sanitizedValue.length < 10) {
      return 'Please enter a complete address';
    }
    
    // Check maximum length
    if (sanitizedValue.length > 200) {
      return 'Address is too long';
    }
    
    return null;
  }

  // Credit card number validation with security checks
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    
    // Use security utility for validation
    if (!SecurityUtils.isValidCreditCard(sanitizedValue)) {
      return 'Please enter a valid card number';
    }
    
    return null;
  }

  // CVV validation with security checks
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    
    // Use security utility for validation
    if (!SecurityUtils.isValidCVV(sanitizedValue)) {
      return 'CVV must be 3 or 4 digits';
    }
    
    return null;
  }

  // Expiry date validation with security checks
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    
    // Use security utility for validation
    if (!SecurityUtils.isValidExpiryDate(sanitizedValue)) {
      return 'Please enter a valid expiry date in MM/YY format';
    }
    
    return null;
  }

  // Amount validation with security checks
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    
    // Check if it's a valid number
    final amount = double.tryParse(sanitizedValue);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    
    // Check maximum amount
    if (amount > 100000) {
      return 'Amount cannot exceed R100,000';
    }
    
    return null;
  }

  // File validation with security checks
  static String? validateFile({
    required String fileName,
    required int fileSizeBytes,
    required List<String> allowedTypes,
    int? maxSizeMB,
  }) {
    // Validate file type
    if (!SecurityUtils.isValidFileType(fileName, allowedTypes)) {
      return 'File type not supported. Allowed: ${allowedTypes.join(', ')}';
    }
    
    // Validate file size
    final maxSize = maxSizeMB ?? AppConstants.maxFileSizeMB;
    if (!SecurityUtils.isValidFileSize(fileSizeBytes, maxSize)) {
      return 'File size must be less than ${maxSize}MB';
    }
    
    return null;
  }

  // Image validation with security checks
  static String? validateImage({
    required String fileName,
    required int fileSizeBytes,
  }) {
    return validateFile(
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      allowedTypes: AppConstants.allowedImageTypes,
      maxSizeMB: AppConstants.maxImageSizeMB,
    );
  }

  // URL validation with security checks
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    // Sanitize URL
    final sanitizedUrl = SecurityUtils.sanitizeUrl(value);
    if (sanitizedUrl.isEmpty) {
      return 'Please enter a valid URL';
    }
    
    // Basic URL format validation
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlPattern.hasMatch(sanitizedUrl)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Description validation with security checks
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value.trim());
    
    // Check maximum length
    if (sanitizedValue.length > AppConstants.maxDescriptionLength) {
      return 'Description is too long (max ${AppConstants.maxDescriptionLength} characters)';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();
      
      // Check if date is in the future
      if (date.isBefore(now)) {
        return 'Date must be in the future';
      }
      
      // Check if date is not too far in the future (e.g., 1 year)
      final maxDate = now.add(const Duration(days: 365));
      if (date.isAfter(maxDate)) {
        return 'Date cannot be more than 1 year in the future';
      }
      
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Time validation
  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time is required';
    }
    
    try {
      // Basic time format validation (HH:MM)
      final timePattern = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
      if (!timePattern.hasMatch(value)) {
        return 'Please enter a valid time in HH:MM format';
      }
      
      return null;
    } catch (e) {
      return 'Please enter a valid time';
    }
  }

  // Number validation
  static String? validateNumber(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    
    // Check if it's a valid number
    final number = double.tryParse(sanitizedValue);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    // Check minimum value
    if (min != null && number < min) {
      return 'Number must be at least $min';
    }
    
    // Check maximum value
    if (max != null && number > max) {
      return 'Number must be at most $max';
    }
    
    return null;
  }

  // Integer validation
  static String? validateInteger(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    
    // Check if it's a valid integer
    final number = int.tryParse(sanitizedValue);
    if (number == null) {
      return 'Please enter a valid whole number';
    }
    
    // Check minimum value
    if (min != null && number < min) {
      return 'Number must be at least $min';
    }
    
    // Check maximum value
    if (max != null && number > max) {
      return 'Number must be at most $max';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    // Sanitize input
    final sanitizedValue = SecurityUtils.sanitizeInput(value.trim());
    
    // Check if sanitization removed all content
    if (sanitizedValue.isEmpty) {
      return '$fieldName contains invalid characters';
    }
    
    return null;
  }

  // Length validation
  static String? validateLength(String? value, {int? min, int? max, String? fieldName}) {
    if (value == null) return null;
    
    final length = value.length;
    
    if (min != null && length < min) {
      final name = fieldName ?? 'Field';
      return '$name must be at least $min characters long';
    }
    
    if (max != null && length > max) {
      final name = fieldName ?? 'Field';
      return '$name must be at most $max characters long';
    }
    
    return null;
  }

  // Pattern validation
  static String? validatePattern(String? value, RegExp pattern, String errorMessage) {
    if (value == null || value.isEmpty) return null;
    
    if (!pattern.hasMatch(value)) {
      return errorMessage;
    }
    
    return null;
  }

  // Custom validation function
  static String? validateCustom(String? value, bool Function(String) validator, String errorMessage) {
    if (value == null || value.isEmpty) return null;
    
    if (!validator(value)) {
      return errorMessage;
    }
    
    return null;
  }

  // Multiple validations
  static String? validateMultiple(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  // Real-time validation feedback
  static ValidationResult validateRealTime(String? value, String? Function(String?) validator) {
    if (value == null || value.isEmpty) {
      return const ValidationResult(isValid: false, message: null, isComplete: false);
    }
    
    final error = validator(value);
    return ValidationResult(
      isValid: error == null,
      message: error,
      isComplete: value.isNotEmpty,
    );
  }
}

/// Validation result for real-time feedback
class ValidationResult {
  final bool isValid;
  final String? message;
  final bool isComplete;

  const ValidationResult({
    required this.isValid,
    this.message,
    required this.isComplete,
  });
}

/// Form validation helper
class FormValidator {
  final Map<String, String? Function(String?)> _validators = {};
  final Map<String, String?> _errors = {};
  final Map<String, String> _values = {};

  /// Add field validator
  void addValidator(String fieldName, String? Function(String?) validator) {
    _validators[fieldName] = validator;
  }

  /// Set field value
  void setValue(String fieldName, String value) {
    _values[fieldName] = value;
    _validateField(fieldName);
  }

  /// Get field value
  String getValue(String fieldName) {
    return _values[fieldName] ?? '';
  }

  /// Get field error
  String? getError(String fieldName) {
    return _errors[fieldName];
  }

  /// Validate specific field
  void _validateField(String fieldName) {
    final validator = _validators[fieldName];
    if (validator != null) {
      final value = _values[fieldName] ?? '';
      final error = validator(value);
      if (error != null) {
        _errors[fieldName] = error;
      } else {
        _errors.remove(fieldName);
      }
    }
  }

  /// Validate all fields
  bool validateAll() {
    bool isValid = true;
    
    for (final fieldName in _validators.keys) {
      _validateField(fieldName);
      if (_errors.containsKey(fieldName)) {
        isValid = false;
      }
    }
    
    return isValid;
  }

  /// Get all errors
  Map<String, String?> getErrors() {
    return Map.unmodifiable(_errors);
  }

  /// Check if form is valid
  bool get isValid => _errors.isEmpty;

  /// Clear all errors
  void clearErrors() {
    _errors.clear();
  }

  /// Reset form
  void reset() {
    _values.clear();
    _errors.clear();
  }
} 