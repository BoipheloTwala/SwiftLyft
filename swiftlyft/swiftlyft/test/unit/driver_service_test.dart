import 'package:flutter_test/flutter_test.dart';
import 'package:swiftlyft/models/driver.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('DriverService Tests', () {
    group('DriverAssignment Model Tests', () {
      test('DriverAssignment.fromJson creates correct object', () {
        final json = {
          'id': 'assignment-123',
          'bookingId': 'booking-456',
          'driverId': 'driver-789',
          'driverName': 'John Smith',
          'driverPhone': '+27123456789',
          'driverPhotoUrl': 'https://example.com/photo.jpg',
          'vehicleId': 'vehicle-123',
          'vehicleName': 'Mercedes S-Class',
          'status': 'assigned',
          'notes': 'VIP client',
          'assignedAt': '2024-01-15T10:00:00.000Z',
          'completedAt': '2024-01-15T12:00:00.000Z',
          'assignmentDetails': {'priority': 'high'},
        };

        final assignment = DriverAssignment.fromJson(json);

        expect(assignment.id, 'assignment-123');
        expect(assignment.bookingId, 'booking-456');
        expect(assignment.driverId, 'driver-789');
        expect(assignment.driverName, 'John Smith');
        expect(assignment.driverPhone, '+27123456789');
        expect(assignment.driverPhotoUrl, 'https://example.com/photo.jpg');
        expect(assignment.vehicleId, 'vehicle-123');
        expect(assignment.vehicleName, 'Mercedes S-Class');
        expect(assignment.status, 'assigned');
        expect(assignment.notes, 'VIP client');
        expect(assignment.assignedAt, DateTime.parse('2024-01-15T10:00:00.000Z'));
        expect(assignment.completedAt, DateTime.parse('2024-01-15T12:00:00.000Z'));
        expect(assignment.assignmentDetails, {'priority': 'high'});
      });

      test('DriverAssignment.toJson serializes correctly', () {
        final assignment = DriverAssignment(
          id: 'assignment-123',
          bookingId: 'booking-456',
          driverId: 'driver-789',
          driverName: 'John Smith',
          driverPhone: '+27123456789',
          driverPhotoUrl: 'https://example.com/photo.jpg',
          vehicleId: 'vehicle-123',
          vehicleName: 'Mercedes S-Class',
          status: 'assigned',
          notes: 'VIP client',
          assignedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
          completedAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
          assignmentDetails: {'priority': 'high'},
        );

        final json = assignment.toJson();

        expect(json['id'], 'assignment-123');
        expect(json['bookingId'], 'booking-456');
        expect(json['driverId'], 'driver-789');
        expect(json['driverName'], 'John Smith');
        expect(json['driverPhone'], '+27123456789');
        expect(json['driverPhotoUrl'], 'https://example.com/photo.jpg');
        expect(json['vehicleId'], 'vehicle-123');
        expect(json['vehicleName'], 'Mercedes S-Class');
        expect(json['status'], 'assigned');
        expect(json['notes'], 'VIP client');
        expect(json['assignedAt'], '2024-01-15T10:00:00.000Z');
        expect(json['completedAt'], '2024-01-15T12:00:00.000Z');
        expect(json['assignmentDetails'], {'priority': 'high'});
      });

      test('DriverAssignment handles null values correctly', () {
        final json = {
          'id': 'assignment-123',
          'bookingId': 'booking-456',
          'driverId': 'driver-789',
          'driverName': 'John Smith',
          'driverPhone': '+27123456789',
          'vehicleId': 'vehicle-123',
          'vehicleName': 'Mercedes S-Class',
          'status': 'assigned',
          'assignedAt': '2024-01-15T10:00:00.000Z',
        };

        final assignment = DriverAssignment.fromJson(json);

        expect(assignment.driverPhotoUrl, isNull);
        expect(assignment.notes, isNull);
        expect(assignment.completedAt, isNull);
        expect(assignment.assignmentDetails, isNull);
      });
    });

    group('DriverRating Model Tests', () {
      test('DriverRating.fromJson creates correct object', () {
        final json = {
          'id': 'rating-123',
          'driverId': 'driver-456',
          'bookingId': 'booking-789',
          'userId': 'user-101',
          'rating': 4.5,
          'review': 'Excellent service',
          'criteria': {'punctuality': true, 'courtesy': true},
          'createdAt': '2024-01-15T12:30:00.000Z',
        };

        final rating = DriverRating.fromJson(json);

        expect(rating.id, 'rating-123');
        expect(rating.driverId, 'driver-456');
        expect(rating.bookingId, 'booking-789');
        expect(rating.userId, 'user-101');
        expect(rating.rating, 4.5);
        expect(rating.review, 'Excellent service');
        expect(rating.criteria, {'punctuality': true, 'courtesy': true});
        expect(rating.createdAt, DateTime.parse('2024-01-15T12:30:00.000Z'));
      });

      test('DriverRating.toJson serializes correctly', () {
        final rating = DriverRating(
          id: 'rating-123',
          driverId: 'driver-456',
          bookingId: 'booking-789',
          userId: 'user-101',
          rating: 4.5,
          review: 'Excellent service',
          criteria: {'punctuality': true, 'courtesy': true},
          createdAt: DateTime.parse('2024-01-15T12:30:00.000Z'),
        );

        final json = rating.toJson();

        expect(json['id'], 'rating-123');
        expect(json['driverId'], 'driver-456');
        expect(json['bookingId'], 'booking-789');
        expect(json['userId'], 'user-101');
        expect(json['rating'], 4.5);
        expect(json['review'], 'Excellent service');
        expect(json['criteria'], {'punctuality': true, 'courtesy': true});
        expect(json['createdAt'], '2024-01-15T12:30:00.000Z');
      });
    });

    group('Driver Model Tests', () {
      test('Driver.fromJson creates correct object', () {
        final json = {
          'id': 'driver-123',
          'name': 'John Smith',
          'email': 'john@example.com',
          'phone': '+27123456789',
          'photoUrl': 'https://example.com/photo.jpg',
          'rating': 4.7,
          'totalRatings': 150,
          'vehicleType': 'Luxury Sedan',
          'licenseNumber': 'DL123456',
          'status': 'available',
          'location': {
            'latitude': -26.2041,
            'longitude': 28.0473,
          },
          'updatedAt': '2024-01-15T10:00:00.000Z',
          'lastActive': '2024-01-15T10:00:00.000Z',
        };

        final driver = Driver.fromJson(json);

        expect(driver.id, 'driver-123');
        expect(driver.name, 'John Smith');
        expect(driver.email, 'john@example.com');
        expect(driver.phone, '+27123456789');
        expect(driver.photoUrl, 'https://example.com/photo.jpg');
        expect(driver.rating, 4.7);
        expect(driver.totalRatings, 150);
        expect(driver.vehicleType, 'Luxury Sedan');
        expect(driver.licenseNumber, 'DL123456');
        expect(driver.status, DriverStatus.offline);
        expect(driver.location!.latitude, -26.2041);
        expect(driver.location!.longitude, 28.0473);
        expect(driver.lastActive, DateTime.parse('2024-01-15T10:00:00.000Z'));
      });

      test('Driver.toJson serializes correctly', () {
        final driver = Driver(
          id: 'driver-123',
          driverId: 'driver-123',
          userId: 'user-123',
          name: 'John Smith',
          email: 'john@example.com',
          phone: '+27123456789',
          photoUrl: 'https://example.com/photo.jpg',
          rating: 4.7,
          totalRides: 150,
          totalTrips: 150,
          performance: {'rating': 4.7, 'completion': 0.95},
          vehicleType: 'Luxury Sedan',
          licenseNumber: 'DL123456',
          status: DriverStatus.online,
          isOnline: true,
          isAvailable: true,
          createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
          updatedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
          location: const LatLng(-26.2041, 28.0473),
          lastActive: DateTime.parse('2024-01-15T10:00:00.000Z'),
        );

        final json = driver.toJson();

        expect(json['id'], 'driver-123');
        expect(json['name'], 'John Smith');
        expect(json['email'], 'john@example.com');
        expect(json['phone'], '+27123456789');
        expect(json['photoUrl'], 'https://example.com/photo.jpg');
        expect(json['rating'], 4.7);
        expect(json['totalRatings'], 150);
        expect(json['vehicleType'], 'Luxury Sedan');
        expect(json['licenseNumber'], 'DL123456');
        expect(json['status'], 'online');
        expect(json['location']['latitude'], -26.2041);
        expect(json['location']['longitude'], 28.0473);
        expect(json['lastActive'], '2024-01-15T10:00:00.000Z');
      });
    });
  });
}
