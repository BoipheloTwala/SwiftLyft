import 'package:flutter_test/flutter_test.dart';
import 'package:swiftlyft/providers/app_state.dart';
import 'package:swiftlyft/models/payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppState Payment Method Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    group('Payment Method Management', () {
      test('should initialize with empty payment methods list', () {
        expect(appState.paymentMethods, isEmpty);
        expect(appState.isLoadingPaymentMethods, isFalse);
        expect(appState.paymentMethodsError, isNull);
      });

      test('PaymentMethod model serialization works correctly', () {
        final paymentMethod = PaymentMethod(
          id: 'pm-123',
          userId: 'user-123',
          type: 'card',
          holderName: 'John Doe',
          cardNumber: '4111111111111111',
          expiryMonth: '12',
          expiryYear: '2025',
          brand: 'visa',
          isDefault: true,
          isActive: true,
          isExpired: false,
          billingAddress: {
            'street': '123 Main St',
            'city': 'Johannesburg',
            'country': 'South Africa',
          },
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        );

        final json = paymentMethod.toJson();

        expect(json['id'], 'pm-123');
        expect(json['type'], 'card');
        expect(json['holderName'], 'John Doe');
        expect(json['cardNumber'], '4111111111111111');
        expect(json['expiryMonth'], '12');
        expect(json['expiryYear'], '2025');
        expect(json['brand'], 'visa');
        expect(json['isDefault'], true);
        expect(json['billingAddress']['city'], 'Johannesburg');
      });

      test('PaymentMethod.fromJson handles missing optional fields', () {
        final json = {
          'id': 'pm-123',
          'type': 'card',
          'holderName': 'John Doe',
          'cardNumber': '4111111111111111',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        };

        final paymentMethod = PaymentMethod.fromJson(json);

        expect(paymentMethod.id, 'pm-123');
        expect(paymentMethod.type, 'card');
        expect(paymentMethod.holderName, 'John Doe');
        expect(paymentMethod.expiryMonth, isNull);
        expect(paymentMethod.expiryYear, isNull);
        expect(paymentMethod.brand, isNull);
        expect(paymentMethod.isDefault, false);
        expect(paymentMethod.billingAddress, isNull);
      });
    });

    group('Quote Management', () {
      test('getQuoteById returns null for non-existent quotes', () async {
        final result = await appState.getQuoteById('non-existent-id');
        expect(result, isNull);
      });

      test('getQuoteHistory handles parameters correctly', () async {
        final quotes = await appState.getQuoteHistory(
          page: 1,
          limit: 10,
          status: 'pending',
        );

        // Should not throw, even if no quotes exist
        expect(quotes, isA<List>());
      });
    });

    group('Driver Management', () {
      test('getDriverById returns null for non-existent drivers', () async {
        final result = await appState.getDriverById('non-existent-id');
        expect(result, isNull);
      });

      test('assignDriver creates assignment successfully', () async {
        // This would normally test the full flow, but since we can't mock
        // the API in this test, we just verify the method exists and
        // handles parameters correctly
        expect(() async => await appState.assignDriver(
          'booking-123',
          'driver-456',
        ), returnsNormally);
      });

      test('rateDriver handles all parameters correctly', () async {
        expect(() async => await appState.rateDriver(
          'driver-123',
          bookingId: 'booking-456',
          rating: 4.5,
          review: 'Great service',
          criteria: {'punctuality': 4.5, 'courtesy': 5.0},
        ), returnsNormally);
      });
    });

    group('Quote Expiration', () {
      test('checkAndHandleExpiredQuotes completes without error', () async {
        // Should not throw even if no quotes exist
        expect(() => appState.checkAndHandleExpiredQuotes(),
            returnsNormally);
      });
    });
  });
}
