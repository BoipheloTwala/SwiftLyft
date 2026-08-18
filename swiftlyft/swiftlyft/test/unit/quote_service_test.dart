import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftlyft/models/quote.dart';

// Mock classes
class MockApiClient extends Mock {
  // Mock implementation would go here in a real test
}

void main() {
  group('QuoteService Tests', () {

    group('Quote Model Tests', () {
      test('Quote.fromJson creates correct object', () {
        final json = {
          'id': 'quote-123',
          'userId': 'user-456',
          'pickupLocation': {'address': 'Sandton'},
          'dropoffLocation': {'address': 'Airport'},
          'vehicleType': 'Luxury Sedan',
          'serviceType': 'standard',
          'scheduledDate': '2024-01-15T10:00:00.000Z',
          'passengerCount': 2,
          'specialNotes': 'Business trip',
          'closeProtectionOfficer': false,
          'estimatedPrice': {'basePrice': 1500.0},
          'status': 'pending',
          'createdAt': '2024-01-10T09:00:00.000Z',
          'validUntil': DateTime.now().add(const Duration(days: 1)).toIso8601String(), // Future date for non-expired test
        };

        final quote = Quote.fromJson(json);

        expect(quote.id, 'quote-123');
        expect(quote.userId, 'user-456');
        expect(quote.vehicleType, 'Luxury Sedan');
        expect(quote.status, 'pending');
        expect(quote.passengerCount, 2);
        expect(quote.isExpired, false);
      });

      test('Quote.isExpired returns true for expired quotes', () {
        final expiredJson = {
          'id': 'quote-123',
          'userId': 'user-456',
          'pickupLocation': {'address': 'Sandton'},
          'dropoffLocation': {'address': 'Airport'},
          'vehicleType': 'Luxury Sedan',
          'serviceType': 'standard',
          'scheduledDate': '2024-01-15T10:00:00.000Z',
          'passengerCount': 2,
          'specialNotes': 'Business trip',
          'closeProtectionOfficer': false,
          'estimatedPrice': {'basePrice': 1500.0},
          'status': 'pending',
          'createdAt': '2024-01-10T09:00:00.000Z',
          'validUntil': '2024-01-01T10:00:00.000Z', // Past date
        };

        final quote = Quote.fromJson(expiredJson);
        expect(quote.isExpired, true);
      });

      test('Quote.expiresAt returns validUntil or calculated default', () {
        final jsonWithValidUntil = {
          'id': 'quote-123',
          'userId': 'user-456',
          'pickupLocation': {'address': 'Sandton'},
          'dropoffLocation': {'address': 'Airport'},
          'vehicleType': 'Luxury Sedan',
          'serviceType': 'standard',
          'scheduledDate': '2024-01-15T10:00:00.000Z',
          'passengerCount': 2,
          'closeProtectionOfficer': false,
          'estimatedPrice': {'basePrice': 1500.0},
          'status': 'pending',
          'createdAt': '2024-01-10T09:00:00.000Z',
          'validUntil': '2024-01-17T10:00:00.000Z',
        };

        final jsonWithoutValidUntil = {
          'id': 'quote-123',
          'userId': 'user-456',
          'pickupLocation': {'address': 'Sandton'},
          'dropoffLocation': {'address': 'Airport'},
          'vehicleType': 'Luxury Sedan',
          'serviceType': 'standard',
          'scheduledDate': '2024-01-15T10:00:00.000Z',
          'passengerCount': 2,
          'closeProtectionOfficer': false,
          'estimatedPrice': {'basePrice': 1500.0},
          'status': 'pending',
          'createdAt': '2024-01-10T09:00:00.000Z',
        };

        final quoteWithValidUntil = Quote.fromJson(jsonWithValidUntil);
        final quoteWithoutValidUntil = Quote.fromJson(jsonWithoutValidUntil);

        expect(quoteWithValidUntil.expiresAt, DateTime.parse('2024-01-17T10:00:00.000Z'));
        expect(quoteWithoutValidUntil.expiresAt, quoteWithoutValidUntil.createdAt.add(const Duration(hours: 24)));
      });
    });

    group('QuoteAcceptance Model Tests', () {
      test('QuoteAcceptance.fromJson creates correct object', () {
        final json = {
          'id': 'acceptance-123',
          'quoteId': 'quote-456',
          'bookingId': 'booking-789',
          'status': 'accepted',
          'modifications': {'notes': 'VIP service'},
          'acceptedAt': '2024-01-15T10:30:00.000Z',
        };

        final acceptance = QuoteAcceptance.fromJson(json);

        expect(acceptance.id, 'acceptance-123');
        expect(acceptance.quoteId, 'quote-456');
        expect(acceptance.bookingId, 'booking-789');
        expect(acceptance.status, 'accepted');
        expect(acceptance.modifications, {'notes': 'VIP service'});
        expect(acceptance.acceptedAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
      });

      test('QuoteAcceptance.toJson serializes correctly', () {
        final acceptance = QuoteAcceptance(
          id: 'acceptance-123',
          quoteId: 'quote-456',
          bookingId: 'booking-789',
          status: 'accepted',
          modifications: {'notes': 'VIP service'},
          acceptedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        );

        final json = acceptance.toJson();

        expect(json['id'], 'acceptance-123');
        expect(json['quoteId'], 'quote-456');
        expect(json['bookingId'], 'booking-789');
        expect(json['status'], 'accepted');
        expect(json['modifications'], {'notes': 'VIP service'});
        expect(json['acceptedAt'], '2024-01-15T10:30:00.000Z');
      });
    });
  });
}
