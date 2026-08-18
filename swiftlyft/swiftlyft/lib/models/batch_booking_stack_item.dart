import '../models/vehicle.dart';

/// Represents a vehicle item in the batch booking stack for corporate users
/// Uses LIFO (Last In, First Out) stack behavior
class BatchBookingStackItem {
  final String vehicleId;
  final String vehicleName;
  final String vehicleCategory;
  final double displayPrice;
  final String? city;
  final DateTime addedAt;

  BatchBookingStackItem({
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleCategory,
    required this.displayPrice,
    this.city,
    required this.addedAt,
  });

  factory BatchBookingStackItem.fromVehicle(Vehicle vehicle) {
    return BatchBookingStackItem(
      vehicleId: vehicle.id,
      vehicleName: vehicle.name,
      vehicleCategory: vehicle.category,
      displayPrice: vehicle.displayPrice,
      city: vehicle.city,
      addedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'vehicleCategory': vehicleCategory,
      'displayPrice': displayPrice,
      'city': city,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory BatchBookingStackItem.fromJson(Map<String, dynamic> json) {
    return BatchBookingStackItem(
      vehicleId: json['vehicleId'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      vehicleCategory: json['vehicleCategory'] ?? '',
      displayPrice: (json['displayPrice'] ?? json['basePrice'] ?? 0.0).toDouble(), // Fallback to basePrice for backward compatibility
      city: json['city'],
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

