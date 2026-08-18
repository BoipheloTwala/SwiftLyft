import 'coordinates.dart';
import 'driver.dart';

/// Vehicle model
class Vehicle {
  final String id;
  final String vehicleId;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final List<String> imageGallery;
  final int seatingCapacity;
  final int passengerCapacity;
  final List<String> features;
  final List<String> badges;
  final Map<String, dynamic> specifications;
  final double basePrice;
  final String city;
  final String status;
  final bool availability;
  final double rating;
  final int totalTrips;
  final Driver? driver;
  final VehiclePricing? pricing;
  final Map<String, dynamic>? currentLocation;
  final Map<String, dynamic>? maintenance;
  final Map<String, dynamic>? insurance;
  final Map<String, dynamic>? documents;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.vehicleId,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.imageGallery,
    required this.seatingCapacity,
    required this.passengerCapacity,
    required this.features,
    this.badges = const [],
    this.specifications = const {},
    required this.basePrice,
    required this.city,
    required this.status,
    required this.availability,
    required this.rating,
    required this.totalTrips,
    this.driver,
    this.pricing,
    this.currentLocation,
    this.maintenance,
    this.insurance,
    this.documents,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if vehicle is available
  /// Backend returns status as 'available' or 'unavailable'
  bool get isAvailable => availability && (status == 'active' || status == 'available');

  /// Get display price with luxury service adjustment
  /// This applies a multiplier to make prices more realistic for a premium chauffeur service
  /// Backend prices remain unchanged - this is frontend display only
  double get displayPrice {
    if (basePrice <= 0) {
      // If no base price, return category-based pricing
      final categoryPrices = {
        'sedan': 600.0,
        'suv': 950.0,
        'luxury': 1800.0,
        'van': 1200.0,
        'truck': 1400.0,
        'hybrid': 700.0,
      };
      return categoryPrices[category.toLowerCase()] ?? 600.0;
    }
    
    // Apply luxury service multiplier (3.5x - 5.0x based on category)
    final multipliers = {
      'sedan': 3.5,
      'suv': 4.0,
      'luxury': 5.0,
      'van': 4.5,
      'truck': 4.5,
      'hybrid': 4.0,
    };
    
    final multiplier = multipliers[category.toLowerCase()] ?? 4.0;
    return (basePrice * multiplier).roundToDouble();
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      imageGallery: List<String>.from(json['imageGallery'] ?? []),
      seatingCapacity: json['seatingCapacity'] ?? 0,
      passengerCapacity: json['passengerCapacity'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      badges: List<String>.from(json['badges'] ?? []),
      specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      city: json['city'] ?? '',
      status: json['status'] ?? '',
      // Handle availability - can be bool or object with isAvailable field
      availability: json['availability'] is bool 
          ? json['availability'] 
          : (json['availability']?['isAvailable'] ?? false),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      pricing: json['pricing'] != null ? VehiclePricing.fromJson(json['pricing']) : null,
      currentLocation: json['currentLocation'],
      maintenance: json['maintenance'],
      insurance: json['insurance'],
      documents: json['documents'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'imageGallery': imageGallery,
      'seatingCapacity': seatingCapacity,
      'passengerCapacity': passengerCapacity,
      'features': features,
      'badges': badges,
      'specifications': specifications,
      'basePrice': basePrice,
      'city': city,
      'status': status,
      'availability': availability,
      'rating': rating,
      'totalTrips': totalTrips,
      'driver': driver?.toJson(),
      'pricing': pricing?.toJson(),
      'currentLocation': currentLocation,
      'maintenance': maintenance,
      'insurance': insurance,
      'documents': documents,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  LatLng? get currentLatLng {
    if (currentLocation != null &&
        currentLocation!['coordinates'] != null) {
      final coords = currentLocation!['coordinates'];
      if (coords['latitude'] != null && coords['longitude'] != null) {
        return LatLng(coords['latitude'], coords['longitude']);
      }
    }
    return null;
  }

  // CopyWith method for state updates
  Vehicle copyWith({
    String? id,
    String? vehicleId,
    String? name,
    String? description,
    String? category,
    String? imageUrl,
    List<String>? imageGallery,
    int? seatingCapacity,
    int? passengerCapacity,
    List<String>? features,
    List<String>? badges,
    Map<String, dynamic>? specifications,
    double? basePrice,
    String? city,
    String? status,
    bool? availability,
    double? rating,
    int? totalTrips,
    Driver? driver,
    VehiclePricing? pricing,
    Map<String, dynamic>? currentLocation,
    Map<String, dynamic>? maintenance,
    Map<String, dynamic>? insurance,
    Map<String, dynamic>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      imageGallery: imageGallery ?? this.imageGallery,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      features: features ?? this.features,
      badges: badges ?? this.badges,
      specifications: specifications ?? this.specifications,
      basePrice: basePrice ?? this.basePrice,
      city: city ?? this.city,
      status: status ?? this.status,
      availability: availability ?? this.availability,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      driver: driver ?? this.driver,
      pricing: pricing ?? this.pricing,
      currentLocation: currentLocation ?? this.currentLocation,
      maintenance: maintenance ?? this.maintenance,
      insurance: insurance ?? this.insurance,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Vehicle pricing model
class VehiclePricing {
  final double baseFare;
  final double perKm;
  final double perMinute;
  final double minimumFare;
  final double maximumFare;
  final Map<String, double> surgePricing;
  final Map<String, double> discounts;
  final String currency;
  final DateTime lastUpdated;

  VehiclePricing({
    required this.baseFare,
    required this.perKm,
    required this.perMinute,
    required this.minimumFare,
    required this.maximumFare,
    required this.surgePricing,
    required this.discounts,
    required this.currency,
    required this.lastUpdated,
  });

  factory VehiclePricing.fromJson(Map<String, dynamic> json) {
    return VehiclePricing(
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      perKm: (json['perKm'] ?? 0.0).toDouble(),
      perMinute: (json['perMinute'] ?? 0.0).toDouble(),
      minimumFare: (json['minimumFare'] ?? 0.0).toDouble(),
      maximumFare: (json['maximumFare'] ?? 0.0).toDouble(),
      surgePricing: Map<String, double>.from(json['surgePricing'] ?? {}),
      discounts: Map<String, double>.from(json['discounts'] ?? {}),
      currency: json['currency'] ?? 'ZAR',
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseFare': baseFare,
      'perKm': perKm,
      'perMinute': perMinute,
      'minimumFare': minimumFare,
      'maximumFare': maximumFare,
      'surgePricing': surgePricing,
      'discounts': discounts,
      'currency': currency,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Vehicle category model
class VehicleCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int minPassengers;
  final int maxPassengers;
  final List<String> features;
  final bool isActive;

  VehicleCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.minPassengers,
    required this.maxPassengers,
    required this.features,
    required this.isActive,
  });

  factory VehicleCategory.fromJson(Map<String, dynamic> json) {
    return VehicleCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      minPassengers: json['minPassengers'] ?? 1,
      maxPassengers: json['maxPassengers'] ?? 4,
      features: List<String>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'minPassengers': minPassengers,
      'maxPassengers': maxPassengers,
      'features': features,
      'isActive': isActive,
    };
  }
}

/// Vehicle availability model
class VehicleAvailability {
  final String vehicleId;
  final DateTime requestedTime;
  final bool isAvailable;
  final DateTime? nextAvailableTime;
  final List<DateTime> availableSlots;
  final String? reason;

  VehicleAvailability({
    required this.vehicleId,
    required this.requestedTime,
    required this.isAvailable,
    this.nextAvailableTime,
    required this.availableSlots,
    this.reason,
  });

  factory VehicleAvailability.fromJson(Map<String, dynamic> json) {
    return VehicleAvailability(
      vehicleId: json['vehicleId'] ?? '',
      requestedTime: DateTime.parse(json['requestedTime'] ?? DateTime.now().toIso8601String()),
      isAvailable: json['isAvailable'] ?? false,
      nextAvailableTime: json['nextAvailableTime'] != null
          ? DateTime.parse(json['nextAvailableTime'])
          : null,
      availableSlots: (json['availableSlots'] as List<dynamic>?)
          ?.map((slot) => DateTime.parse(slot))
          .toList() ?? [],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'requestedTime': requestedTime.toIso8601String(),
      'isAvailable': isAvailable,
      'nextAvailableTime': nextAvailableTime?.toIso8601String(),
      'availableSlots': availableSlots.map((slot) => slot.toIso8601String()).toList(),
      'reason': reason,
    };
  }
}

/// Vehicle rating model
class VehicleRating {
  final String id;
  final String vehicleId;
  final String userId;
  final String? bookingId;
  final double rating;
  final String? review;
  final List<String> photos;
  final bool isVerified;
  final DateTime createdAt;

  VehicleRating({
    required this.id,
    required this.vehicleId,
    required this.userId,
    this.bookingId,
    required this.rating,
    this.review,
    required this.photos,
    required this.isVerified,
    required this.createdAt,
  });

  factory VehicleRating.fromJson(Map<String, dynamic> json) {
    return VehicleRating(
      id: json['id'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      userId: json['userId'] ?? '',
      bookingId: json['bookingId'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      review: json['review'],
      photos: List<String>.from(json['photos'] ?? []),
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'userId': userId,
      'bookingId': bookingId,
      'rating': rating,
      'review': review,
      'photos': photos,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Vehicle feature model
class VehicleFeature {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final bool isPremium;
  final double? additionalCost;
  final bool isActive;

  VehicleFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.isPremium,
    this.additionalCost,
    required this.isActive,
  });

  factory VehicleFeature.fromJson(Map<String, dynamic> json) {
    return VehicleFeature(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      category: json['category'] ?? '',
      isPremium: json['isPremium'] ?? false,
      additionalCost: json['additionalCost'] != null
          ? (json['additionalCost'] as num).toDouble()
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'isPremium': isPremium,
      'additionalCost': additionalCost,
      'isActive': isActive,
    };
  }
}