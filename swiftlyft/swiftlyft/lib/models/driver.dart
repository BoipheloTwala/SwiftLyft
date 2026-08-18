import 'coordinates.dart';

/// Driver model
class Driver {
  final String id;
  final String driverId;
  final String userId;
  final String name;
  final String phone;
  final String email;
  String? photo;
  final double rating;
  final int totalTrips;
  int totalRides = 0;
  final Map<String, dynamic> performance;
  final DriverStatus status;
  final bool isOnline;
  final bool isAvailable;
  final String? currentVehicleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  DateTime? lastActiveAt;

  // Additional fields for backward compatibility
  final String? vehicleType;
  final String? licenseNumber;
  final LatLng? location;

  /// Alias for photo property for backwards compatibility
  String? get photoUrl => photo;

  /// Alias for totalRides as totalRatings for some UI components
  int get totalRatings => totalRides;

  /// Alias for lastActiveAt as lastActive for backwards compatibility
  DateTime get lastActive => lastActiveAt ?? updatedAt;

  Driver({
    required this.id,
    required this.driverId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    String? photo, // Made photo non-final for backward compatibility
    String? photoUrl, // For backward compatibility
    required this.rating,
    required this.totalTrips,
    this.totalRides = 0,
    int? totalRatings, // For backward compatibility
    required this.performance,
    required this.status,
    required this.isOnline,
    required this.isAvailable,
    this.currentVehicleId,
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
    DateTime? lastActive, // For backward compatibility
    this.vehicleType,
    this.licenseNumber,
    this.location,
  }) {
    // Handle backward compatibility for photo/photoUrl
    this.photo = photo ?? photoUrl;

    // Handle backward compatibility for totalRides/totalRatings
    if (totalRatings != null) {
      totalRides = totalRatings;
    }

    // Handle backward compatibility for lastActive/lastActiveAt
    if (lastActiveAt == null && lastActive != null) {
      lastActiveAt = lastActive;
    }
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      photo: json['photo'] ?? json['photoUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      totalRides: json['totalRides'] ?? json['totalRatings'] ?? 0,
      performance: json['performance'] ?? {},
      status: DriverStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'offline'),
        orElse: () => DriverStatus.offline,
      ),
      isOnline: json['isOnline'] ?? false,
      isAvailable: json['isAvailable'] ?? false,
      currentVehicleId: json['currentVehicleId'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt']) : null,
      vehicleType: json['vehicleType'],
      licenseNumber: json['licenseNumber'],
      location: json['location'] != null ? LatLng(
        (json['location']['latitude'] ?? 0.0).toDouble(),
        (json['location']['longitude'] ?? 0.0).toDouble(),
      ) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'photo': photo,
      'photoUrl': photo, // For backward compatibility
      'rating': rating,
      'totalTrips': totalTrips,
      'totalRides': totalRides,
      'totalRatings': totalRides, // For backward compatibility
      'performance': performance,
      'status': status.toString().split('.').last,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'currentVehicleId': currentVehicleId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'lastActive': lastActive.toIso8601String(), // For backward compatibility
      'vehicleType': vehicleType,
      'licenseNumber': licenseNumber,
      'location': location != null ? {
        'latitude': location!.latitude,
        'longitude': location!.longitude,
      } : null,
    };
  }
}

/// Driver status enum
enum DriverStatus {
  offline,
  online,
  busy,
  onTrip,
  maintenance,
  suspended,
}

/// Driver profile model
class DriverProfile {
  final String driverId;
  final String bio;
  final String licenseNumber;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlateNumber;
  final List<String> languages;
  final DateTime dateOfBirth;
  final String address;
  final String emergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverProfile({
    required this.driverId,
    required this.bio,
    required this.licenseNumber,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlateNumber,
    required this.languages,
    required this.dateOfBirth,
    required this.address,
    required this.emergencyContact,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      driverId: json['driverId'] ?? '',
      bio: json['bio'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleColor: json['vehicleColor'] ?? '',
      vehiclePlateNumber: json['vehiclePlateNumber'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      dateOfBirth: DateTime.parse(json['dateOfBirth'] ?? DateTime.now().toIso8601String()),
      address: json['address'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'bio': bio,
      'licenseNumber': licenseNumber,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehiclePlateNumber': vehiclePlateNumber,
      'languages': languages,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'address': address,
      'emergencyContact': emergencyContact,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Driver rating model
class DriverRating {
  final String id;
  final String driverId;
  final String bookingId;
  final String userId;
  final double rating;
  final String? review;
  final Map<String, bool>? criteria;
  final DateTime createdAt;

  DriverRating({
    required this.id,
    required this.driverId,
    required this.bookingId,
    required this.userId,
    required this.rating,
    this.review,
    this.criteria,
    required this.createdAt,
  });

  factory DriverRating.fromJson(Map<String, dynamic> json) {
    return DriverRating(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      userId: json['userId'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      review: json['review'],
      criteria: Map<String, bool>.from(json['criteria'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'bookingId': bookingId,
      'userId': userId,
      'rating': rating,
      'review': review,
      'criteria': criteria,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Driver location model
class DriverLocation {
  final String driverId;
  final LatLng location;
  final DateTime timestamp;
  final double speed;
  final double heading;

  DriverLocation({
    required this.driverId,
    required this.location,
    required this.timestamp,
    required this.speed,
    required this.heading,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      driverId: json['driverId'] ?? '',
      location: LatLng(
        (json['location']['latitude'] ?? 0.0).toDouble(),
        (json['location']['longitude'] ?? 0.0).toDouble(),
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      speed: (json['speed'] ?? 0.0).toDouble(),
      heading: (json['heading'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heading': heading,
    };
  }
}

/// Driver stats model
class DriverStats {
  final String driverId;
  final int totalTrips;
  final double averageRating;
  final int completedTrips;
  final int cancelledTrips;
  final double earnings;
  final Map<String, dynamic>? performanceMetrics;
  final DateTime lastUpdated;

  DriverStats({
    required this.driverId,
    required this.totalTrips,
    required this.averageRating,
    required this.completedTrips,
    required this.cancelledTrips,
    required this.earnings,
    this.performanceMetrics,
    required this.lastUpdated,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      driverId: json['driverId'] ?? '',
      totalTrips: json['totalTrips'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      completedTrips: json['completedTrips'] ?? 0,
      cancelledTrips: json['cancelledTrips'] ?? 0,
      earnings: (json['earnings'] ?? 0.0).toDouble(),
      performanceMetrics: json['performanceMetrics'],
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'totalTrips': totalTrips,
      'averageRating': averageRating,
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'earnings': earnings,
      'performanceMetrics': performanceMetrics,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Driver schedule model
class DriverSchedule {
  final String driverId;
  final List<ScheduleSlot> scheduleSlots;
  final DateTime lastUpdated;

  DriverSchedule({
    required this.driverId,
    required this.scheduleSlots,
    required this.lastUpdated,
  });

  factory DriverSchedule.fromJson(Map<String, dynamic> json) {
    return DriverSchedule(
      driverId: json['driverId'] ?? '',
      scheduleSlots: (json['scheduleSlots'] as List<dynamic>?)
          ?.map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'scheduleSlots': scheduleSlots.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Schedule slot model
class ScheduleSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? notes;

  ScheduleSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id'] ?? '',
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['endTime'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'available',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}

/// Driver contact model
class DriverContact {
  final String id;
  final String driverId;
  final String userId;
  final String message;
  final String response;
  final String status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  DriverContact({
    required this.id,
    required this.driverId,
    required this.userId,
    required this.message,
    required this.response,
    required this.status,
    required this.sentAt,
    this.respondedAt,
  });

  factory DriverContact.fromJson(Map<String, dynamic> json) {
    return DriverContact(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      userId: json['userId'] ?? '',
      message: json['message'] ?? '',
      response: json['response'] ?? '',
      status: json['status'] ?? 'pending',
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'userId': userId,
      'message': message,
      'response': response,
      'status': status,
      'sentAt': sentAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }
}

/// Nearby driver model
class NearbyDriver {
  final String driverId;
  final String name;
  final double rating;
  final LatLng location;
  final double distance;
  final Duration estimatedArrival;
  final String? vehicleType;
  final bool isAvailable;

  NearbyDriver({
    required this.driverId,
    required this.name,
    required this.rating,
    required this.location,
    required this.distance,
    required this.estimatedArrival,
    this.vehicleType,
    required this.isAvailable,
  });

  factory NearbyDriver.fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      driverId: json['driverId'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      location: LatLng(
        (json['location']['latitude'] ?? 0.0).toDouble(),
        (json['location']['longitude'] ?? 0.0).toDouble(),
      ),
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedArrival: Duration(minutes: json['estimatedArrival'] ?? 0),
      vehicleType: json['vehicleType'],
      isAvailable: json['isAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'name': name,
      'rating': rating,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'distance': distance,
      'estimatedArrival': estimatedArrival.inMinutes,
      'vehicleType': vehicleType,
      'isAvailable': isAvailable,
    };
  }
}

/// Driver assignment model
class DriverAssignment {
  final String id;
  final String bookingId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String? driverPhotoUrl;
  final String vehicleId;
  final String vehicleName;
  final String status;
  final String? notes;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? assignmentDetails;

  DriverAssignment({
    required this.id,
    required this.bookingId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    this.driverPhotoUrl,
    required this.vehicleId,
    required this.vehicleName,
    required this.status,
    this.notes,
    required this.assignedAt,
    this.completedAt,
    this.assignmentDetails,
  });

  factory DriverAssignment.fromJson(Map<String, dynamic> json) {
    return DriverAssignment(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'] ?? '',
      driverPhotoUrl: json['driverPhotoUrl'],
      vehicleId: json['vehicleId'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      status: json['status'] ?? 'assigned',
      notes: json['notes'],
      assignedAt: DateTime.parse(json['assignedAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      assignmentDetails: json['assignmentDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverPhotoUrl': driverPhotoUrl,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'status': status,
      'notes': notes,
      'assignedAt': assignedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'assignmentDetails': assignmentDetails,
    };
  }
}