import 'package:flutter_test/flutter_test.dart';
import 'package:swiftlyft/utils/validators.dart';
import 'package:swiftlyft/models/quote.dart';


void main() {
  group('Validators', () {
    group('Email Validation', () {
      test('should validate correct email addresses', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
        expect(Validators.validateEmail('user.name@domain.co.za'), isNull);
        expect(Validators.validateEmail('test+tag@example.com'), isNull);
      });

      test('should reject invalid email addresses', () {
        expect(Validators.validateEmail('invalid-email'), isNotNull);
        expect(Validators.validateEmail('test@'), isNotNull);
        expect(Validators.validateEmail('@example.com'), isNotNull);
        expect(Validators.validateEmail(''), isNotNull);
        expect(Validators.validateEmail(null), isNotNull);
      });

      test('should reject emails with dangerous characters', () {
        expect(Validators.validateEmail('test<script>@example.com'), isNotNull);
        expect(Validators.validateEmail('test"@example.com'), isNotNull);
      });

      test('should reject emails that are too long', () {
        final longEmail = 'a' * 255 + '@example.com';
        expect(Validators.validateEmail(longEmail), isNotNull);
      });
    });

    group('Password Validation', () {
      test('should validate strong passwords', () {
        expect(Validators.validatePassword('StrongPass123!'), isNull);
        expect(Validators.validatePassword('MyP@ssw0rd'), isNull);
        expect(Validators.validatePassword('Secure123#'), isNull);
      });

      test('should reject weak passwords', () {
        expect(Validators.validatePassword('weak'), isNotNull);
        expect(Validators.validatePassword('password'), isNotNull);
        expect(Validators.validatePassword('12345678'), isNotNull);
        expect(Validators.validatePassword('PASSWORD'), isNotNull);
        expect(Validators.validatePassword(''), isNotNull);
        expect(Validators.validatePassword(null), isNotNull);
      });

      test('should reject passwords that are too short', () {
        expect(Validators.validatePassword('Abc1!'), isNotNull);
      });

      test('should reject passwords that are too long', () {
        final longPassword = 'A' * 129 + 'b1!';
        expect(Validators.validatePassword(longPassword), isNotNull);
      });
    });

    group('Phone Number Validation', () {
      test('should validate South African phone numbers', () {
        expect(Validators.validatePhoneNumber('+27123456789'), isNull);
        expect(Validators.validatePhoneNumber('0712345678'), isNull);
        expect(Validators.validatePhoneNumber('0823456789'), isNull);
      });

      test('should reject invalid phone numbers', () {
        expect(Validators.validatePhoneNumber('123456789'), isNotNull);
        expect(Validators.validatePhoneNumber('+123456789'), isNotNull);
        expect(Validators.validatePhoneNumber(''), isNotNull);
        expect(Validators.validatePhoneNumber(null), isNotNull);
      });
    });

    group('Name Validation', () {
      test('should validate correct names', () {
        expect(Validators.validateName('John Doe'), isNull);
        expect(Validators.validateName('Mary-Jane'), isNull);
        expect(Validators.validateName('O\'Connor'), isNull);
      });

      test('should reject invalid names', () {
        expect(Validators.validateName(''), isNotNull);
        expect(Validators.validateName('A'), isNotNull);
        expect(Validators.validateName('John123'), isNotNull);
        expect(Validators.validateName('John@Doe'), isNotNull);
        expect(Validators.validateName(null), isNotNull);
      });

      test('should reject names that are too long', () {
        final longName = 'A' * 51;
        expect(Validators.validateName(longName), isNotNull);
      });
    });

    group('Credit Card Validation', () {
      test('should validate correct credit card numbers', () {
        expect(Validators.validateCreditCard('4111111111111111'), isNull);
        expect(Validators.validateCreditCard('5555555555554444'), isNull);
      });

      test('should reject invalid credit card numbers', () {
        expect(Validators.validateCreditCard('1234567890123456'), isNotNull);
        expect(Validators.validateCreditCard('4111111111111112'), isNotNull);
        expect(Validators.validateCreditCard(''), isNotNull);
        expect(Validators.validateCreditCard(null), isNotNull);
      });
    });

    group('CVV Validation', () {
      test('should validate correct CVV', () {
        expect(Validators.validateCVV('123'), isNull);
        expect(Validators.validateCVV('1234'), isNull);
      });

      test('should reject invalid CVV', () {
        expect(Validators.validateCVV('12'), isNotNull);
        expect(Validators.validateCVV('12345'), isNotNull);
        expect(Validators.validateCVV('abc'), isNotNull);
        expect(Validators.validateCVV(''), isNotNull);
        expect(Validators.validateCVV(null), isNotNull);
      });
    });

    group('Expiry Date Validation', () {
      test('should validate correct expiry dates', () {
        final nextYear = DateTime.now().year + 1;
        expect(Validators.validateExpiryDate('12/${nextYear.toString().substring(2)}'), isNull);
      });

      test('should reject expired cards', () {
        final lastYear = DateTime.now().year - 1;
        expect(Validators.validateExpiryDate('12/${lastYear.toString().substring(2)}'), isNotNull);
      });

      test('should reject invalid formats', () {
        expect(Validators.validateExpiryDate('13/25'), isNotNull);
        expect(Validators.validateExpiryDate('00/25'), isNotNull);
        expect(Validators.validateExpiryDate('12-25'), isNotNull);
        expect(Validators.validateExpiryDate(''), isNotNull);
        expect(Validators.validateExpiryDate(null), isNotNull);
      });
    });

    group('Amount Validation', () {
      test('should validate correct amounts', () {
        expect(Validators.validateAmount('100'), isNull);
        expect(Validators.validateAmount('100.50'), isNull);
        expect(Validators.validateAmount('99999'), isNull);
      });

      test('should reject invalid amounts', () {
        expect(Validators.validateAmount('0'), isNotNull);
        expect(Validators.validateAmount('-100'), isNotNull);
        expect(Validators.validateAmount('100001'), isNotNull);
        expect(Validators.validateAmount('abc'), isNotNull);
        expect(Validators.validateAmount(''), isNotNull);
        expect(Validators.validateAmount(null), isNotNull);
      });
    });

    group('File Validation', () {
      test('should validate correct files', () {
        expect(Validators.validateFile(
          fileName: 'test.jpg',
          fileSizeBytes: 1024 * 1024, // 1MB
          allowedTypes: ['jpg', 'png'],
        ), isNull);
      });

      test('should reject invalid file types', () {
        expect(Validators.validateFile(
          fileName: 'test.exe',
          fileSizeBytes: 1024,
          allowedTypes: ['jpg', 'png'],
        ), isNotNull);
      });

      test('should reject files that are too large', () {
        expect(Validators.validateFile(
          fileName: 'test.jpg',
          fileSizeBytes: 11 * 1024 * 1024, // 11MB
          allowedTypes: ['jpg', 'png'],
          maxSizeMB: 10,
        ), isNotNull);
      });
    });

    group('URL Validation', () {
      test('should validate correct URLs', () {
        expect(Validators.validateUrl('https://example.com'), isNull);
        expect(Validators.validateUrl('http://www.example.co.za'), isNull);
      });

      test('should reject invalid URLs', () {
        expect(Validators.validateUrl('not-a-url'), isNotNull);
        expect(Validators.validateUrl('ftp://example.com'), isNotNull);
        expect(Validators.validateUrl(''), isNotNull);
        expect(Validators.validateUrl(null), isNotNull);
      });
    });

    group('Date Validation', () {
      test('should validate future dates', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(Validators.validateDate(tomorrow.toIso8601String()), isNull);
      });

      test('should reject past dates', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(Validators.validateDate(yesterday.toIso8601String()), isNotNull);
      });

      test('should reject dates too far in the future', () {
        final farFuture = DateTime.now().add(const Duration(days: 366));
        expect(Validators.validateDate(farFuture.toIso8601String()), isNotNull);
      });
    });

    group('Time Validation', () {
      test('should validate correct times', () {
        expect(Validators.validateTime('12:30'), isNull);
        expect(Validators.validateTime('00:00'), isNull);
        expect(Validators.validateTime('23:59'), isNull);
      });

      test('should reject invalid times', () {
        expect(Validators.validateTime('24:00'), isNotNull);
        expect(Validators.validateTime('12:60'), isNotNull);
        expect(Validators.validateTime('12:30:45'), isNotNull);
        expect(Validators.validateTime(''), isNotNull);
        expect(Validators.validateTime(null), isNotNull);
      });
    });

    group('Number Validation', () {
      test('should validate correct numbers', () {
        expect(Validators.validateNumber('100'), isNull);
        expect(Validators.validateNumber('100.5'), isNull);
        expect(Validators.validateNumber('50', min: 0, max: 100), isNull);
      });

      test('should reject invalid numbers', () {
        expect(Validators.validateNumber('abc'), isNotNull);
        expect(Validators.validateNumber('50', min: 100), isNotNull);
        expect(Validators.validateNumber('50', max: 25), isNotNull);
        expect(Validators.validateNumber(''), isNotNull);
        expect(Validators.validateNumber(null), isNotNull);
      });
    });

    group('Integer Validation', () {
      test('should validate correct integers', () {
        expect(Validators.validateInteger('100'), isNull);
        expect(Validators.validateInteger('50', min: 0, max: 100), isNull);
      });

      test('should reject invalid integers', () {
        expect(Validators.validateInteger('100.5'), isNotNull);
        expect(Validators.validateInteger('abc'), isNotNull);
        expect(Validators.validateInteger('50', min: 100), isNotNull);
        expect(Validators.validateInteger('50', max: 25), isNotNull);
        expect(Validators.validateInteger(''), isNotNull);
        expect(Validators.validateInteger(null), isNotNull);
      });
    });

    group('Required Field Validation', () {
      test('should validate non-empty fields', () {
        expect(Validators.validateRequired('test', 'Field'), isNull);
        expect(Validators.validateRequired(' test ', 'Field'), isNull);
      });

      test('should reject empty fields', () {
        expect(Validators.validateRequired('', 'Field'), isNotNull);
        expect(Validators.validateRequired('   ', 'Field'), isNotNull);
        expect(Validators.validateRequired(null, 'Field'), isNotNull);
      });
    });

    group('Length Validation', () {
      test('should validate correct lengths', () {
        expect(Validators.validateLength('test', min: 2, max: 10), isNull);
        expect(Validators.validateLength('test', min: 4), isNull);
        expect(Validators.validateLength('test', max: 10), isNull);
      });

      test('should reject incorrect lengths', () {
        expect(Validators.validateLength('test', min: 10), isNotNull);
        expect(Validators.validateLength('test', max: 2), isNotNull);
      });
    });

    group('Real-time Validation', () {
      test('should provide correct validation results', () {
        final result = Validators.validateRealTime('test@example.com', Validators.validateEmail);
        expect(result.isValid, isTrue);
        expect(result.message, isNull);
        expect(result.isComplete, isTrue);
      });

      test('should handle empty values', () {
        final result = Validators.validateRealTime('', Validators.validateEmail);
        expect(result.isValid, isFalse);
        expect(result.message, isNull);
        expect(result.isComplete, isFalse);
      });

      test('should handle invalid values', () {
        final result = Validators.validateRealTime('invalid', Validators.validateEmail);
        expect(result.isValid, isFalse);
        expect(result.message, isNotNull);
        expect(result.isComplete, isTrue);
      });
    });

    group('Quote Validation', () {
      test('should validate quote expiration dates', () {
        final futureQuote = Quote(
          id: 'quote-123',
          userId: 'user-456',
          pickupLocation: {'address': 'Sandton'},
          dropoffLocation: {'address': 'Airport'},
          vehicleType: 'Luxury Sedan',
          serviceType: 'standard',
          scheduledDate: DateTime.now().add(const Duration(days: 1)),
          passengerCount: 2,
          closeProtectionOfficer: false,
          estimatedPrice: {'basePrice': 1500.0},
          status: 'pending',
          createdAt: DateTime.now(),
          validUntil: DateTime.now().add(const Duration(hours: 25)),
        );

        final expiredQuote = Quote(
          id: 'quote-456',
          userId: 'user-789',
          pickupLocation: {'address': 'Sandton'},
          dropoffLocation: {'address': 'Airport'},
          vehicleType: 'Luxury Sedan',
          serviceType: 'standard',
          scheduledDate: DateTime.now().add(const Duration(days: 1)),
          passengerCount: 2,
          closeProtectionOfficer: false,
          estimatedPrice: {'basePrice': 1500.0},
          status: 'pending',
          createdAt: DateTime.now(),
          validUntil: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(futureQuote.isExpired, isFalse);
        expect(expiredQuote.isExpired, isTrue);
      });
    });

    group('Driver Rating Validation', () {
      test('should validate driver rating values', () {
        // Test valid ratings
        expect(Validators.validateNumber('4.5', min: 1.0, max: 5.0), isNull);
        expect(Validators.validateNumber('1.0', min: 1.0, max: 5.0), isNull);
        expect(Validators.validateNumber('5.0', min: 1.0, max: 5.0), isNull);

        // Test invalid ratings
        expect(Validators.validateNumber('0.5', min: 1.0, max: 5.0), isNotNull);
        expect(Validators.validateNumber('6.0', min: 1.0, max: 5.0), isNotNull);
        expect(Validators.validateNumber('abc', min: 1.0, max: 5.0), isNotNull);
      });
    });

    group('Quote Amount Validation', () {
      test('should validate quote amounts within business rules', () {
        // Valid amounts
        expect(Validators.validateAmount('100.00'), isNull);
        expect(Validators.validateAmount('50000.00'), isNull);

        // Invalid amounts
        expect(Validators.validateAmount('0.00'), isNotNull); // Too low
        expect(Validators.validateAmount('100001.00'), isNotNull); // Too high
        expect(Validators.validateAmount('-100.00'), isNotNull); // Negative
      });
    });

    group('Booking Time Validation', () {
      test('should validate future booking times', () {
        final futureTime = DateTime.now().add(const Duration(hours: 2));
        expect(Validators.validateDate(futureTime.toIso8601String()), isNull);

        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        expect(Validators.validateDate(pastTime.toIso8601String()), isNotNull);
      });

      test('should reject bookings too far in advance', () {
        final tooFarFuture = DateTime.now().add(const Duration(days: 400));
        expect(Validators.validateDate(tooFarFuture.toIso8601String()), isNotNull);
      });
    });
  });

  group('FormValidator', () {
    late FormValidator formValidator;

    setUp(() {
      formValidator = FormValidator();
    });

    test('should validate form fields correctly', () {
      formValidator.addValidator('email', Validators.validateEmail);
      formValidator.addValidator('password', Validators.validatePassword);

      formValidator.setValue('email', 'test@example.com');
      formValidator.setValue('password', 'StrongPass123!');

      expect(formValidator.isValid, isTrue);
      expect(formValidator.getError('email'), isNull);
      expect(formValidator.getError('password'), isNull);
    });

    test('should detect validation errors', () {
      formValidator.addValidator('email', Validators.validateEmail);
      formValidator.addValidator('password', Validators.validatePassword);

      formValidator.setValue('email', 'invalid-email');
      formValidator.setValue('password', 'weak');

      expect(formValidator.isValid, isFalse);
      expect(formValidator.getError('email'), isNotNull);
      expect(formValidator.getError('password'), isNotNull);
    });

    test('should validate all fields when requested', () {
      formValidator.addValidator('email', Validators.validateEmail);
      formValidator.addValidator('password', Validators.validatePassword);

      formValidator.setValue('email', 'test@example.com');
      // Don't set password value

      expect(formValidator.validateAll(), isFalse);
    });

    test('should clear errors when reset', () {
      formValidator.addValidator('email', Validators.validateEmail);
      formValidator.setValue('email', 'invalid-email');

      expect(formValidator.isValid, isFalse);
      expect(formValidator.getError('email'), isNotNull);

      formValidator.clearErrors();
      expect(formValidator.isValid, isTrue);
    });

    test('should reset form completely', () {
      formValidator.addValidator('email', Validators.validateEmail);
      formValidator.setValue('email', 'test@example.com');

      expect(formValidator.getValue('email'), 'test@example.com');

      formValidator.reset();
      expect(formValidator.getValue('email'), '');
      expect(formValidator.isValid, isTrue);
    });
  });
} 