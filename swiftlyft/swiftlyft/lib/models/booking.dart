import 'coordinates.dart';

enum BookingStatus {
  pending,
  confirmed,
  driverAssigned,
  driverEnRoute,
  driverArrived,
  inProgress,
  completed,
  cancelled,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

class Booking {
  final String id;
  final String userId;
  final String vehicleId;
  final String vehicleName;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String driverPhotoUrl;
  final String pickupAddress;
  final String dropoffAddress;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final DateTime pickupTime;
  final DateTime? actualPickupTime;
  final DateTime? actualDropoffTime;
  final int passengerCount;
  final double basePrice;
  final double finalPrice;
  final String? specialNotes;
  final bool closeProtectionOfficer;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? paymentMethodId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? rating;
  final String? review;
  final Map<String, dynamic>? routeInfo;
  final Map<String, dynamic>? pricing;

  /// Check if booking is active (not completed or cancelled)
  bool get isActive => status != BookingStatus.completed && status != BookingStatus.cancelled;

  /// Check if booking is completed
  bool get isCompleted => status == BookingStatus.completed;

  /// Check if booking is cancelled
  bool get isCancelled => status == BookingStatus.cancelled;

  Booking({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.vehicleName,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverPhotoUrl,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    this.actualPickupTime,
    this.actualDropoffTime,
    required this.passengerCount,
    required this.basePrice,
    required this.finalPrice,
    this.specialNotes,
    required this.closeProtectionOfficer,
    required this.status,
    required this.paymentStatus,
    this.paymentMethodId,
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    this.review,
    this.routeInfo,
    this.pricing,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'] ?? '',
      driverPhotoUrl: json['driverPhotoUrl'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffAddress: json['dropoffAddress'] ?? '',
      pickupLocation: json['pickupLocation'] != null ? LatLng(
        json['pickupLocation']['latitude'] ?? 0.0,
        json['pickupLocation']['longitude'] ?? 0.0,
      ) : const LatLng(0.0, 0.0),
      dropoffLocation: json['dropoffLocation'] != null ? LatLng(
        json['dropoffLocation']['latitude'] ?? 0.0,
        json['dropoffLocation']['longitude'] ?? 0.0,
      ) : const LatLng(0.0, 0.0),
      pickupTime: DateTime.parse(json['pickupTime'] ?? DateTime.now().toIso8601String()),
      actualPickupTime: json['actualPickupTime'] != null 
          ? DateTime.parse(json['actualPickupTime']) 
          : null,
      actualDropoffTime: json['actualDropoffTime'] != null 
          ? DateTime.parse(json['actualDropoffTime']) 
          : null,
      passengerCount: json['passengerCount'] ?? 1,
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0.0).toDouble(),
      specialNotes: json['specialNotes'],
      closeProtectionOfficer: json['closeProtectionOfficer'] ?? false,
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${json['status']}',
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['paymentStatus']}',
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethodId: json['paymentMethodId'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      rating: json['rating']?.toDouble(),
      review: json['review'],
      routeInfo: json['routeInfo'],
      pricing: json['pricing'] != null ? Map<String, dynamic>.from(json['pricing']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverPhotoUrl': driverPhotoUrl,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLocation': {
        'latitude': pickupLocation.latitude,
        'longitude': pickupLocation.longitude,
      },
      'dropoffLocation': {
        'latitude': dropoffLocation.latitude,
        'longitude': dropoffLocation.longitude,
      },
      'pickupTime': pickupTime.toIso8601String(),
      'actualPickupTime': actualPickupTime?.toIso8601String(),
      'actualDropoffTime': actualDropoffTime?.toIso8601String(),
      'passengerCount': passengerCount,
      'basePrice': basePrice,
      'finalPrice': finalPrice,
      'specialNotes': specialNotes,
      'closeProtectionOfficer': closeProtectionOfficer,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentMethodId': paymentMethodId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rating': rating,
      'review': review,
      'routeInfo': routeInfo,
      'pricing': pricing,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? vehicleName,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhotoUrl,
    String? pickupAddress,
    String? dropoffAddress,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    DateTime? pickupTime,
    DateTime? actualPickupTime,
    DateTime? actualDropoffTime,
    int? passengerCount,
    double? basePrice,
    double? finalPrice,
    String? specialNotes,
    bool? closeProtectionOfficer,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentMethodId,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    String? review,
    Map<String, dynamic>? routeInfo,
    Map<String, dynamic>? pricing,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupTime: pickupTime ?? this.pickupTime,
      actualPickupTime: actualPickupTime ?? this.actualPickupTime,
      actualDropoffTime: actualDropoffTime ?? this.actualDropoffTime,
      passengerCount: passengerCount ?? this.passengerCount,
      basePrice: basePrice ?? this.basePrice,
      finalPrice: finalPrice ?? this.finalPrice,
      specialNotes: specialNotes ?? this.specialNotes,
      closeProtectionOfficer: closeProtectionOfficer ?? this.closeProtectionOfficer,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      routeInfo: routeInfo ?? this.routeInfo,
      pricing: pricing ?? this.pricing,
    );
  }

  // Helper methods
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.driverAssigned:
        return 'Driver Assigned';
      case BookingStatus.driverEnRoute:
        return 'Driver En Route';
      case BookingStatus.driverArrived:
        return 'Driver Arrived';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Booking rating model
class BookingRating {
  final String id;
  final String bookingId;
  final String userId;
  final double overallRating;
  final String? review;
  final Map<String, double> categoryRatings; // driver, vehicle, service, etc.
  final List<String> tags;
  final bool isVerified;
  final DateTime createdAt;

  BookingRating({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.overallRating,
    this.review,
    required this.categoryRatings,
    required this.tags,
    required this.isVerified,
    required this.createdAt,
  });

  factory BookingRating.fromJson(Map<String, dynamic> json) {
    return BookingRating(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      userId: json['userId'] ?? '',
      overallRating: (json['overallRating'] ?? 0.0).toDouble(),
      review: json['review'],
      categoryRatings: Map<String, double>.from(json['categoryRatings'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'overallRating': overallRating,
      'review': review,
      'categoryRatings': categoryRatings,
      'tags': tags,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Booking tracking model
class BookingTracking {
  final String bookingId;
  final BookingStatus status;
  final LatLng? driverLocation;
  final LatLng? vehicleLocation;
  final double? distanceToPickup;
  final Duration? estimatedArrival;
  final Duration? estimatedTripTime;
  final List<TrackingUpdate> updates;
  final DateTime lastUpdated;

  BookingTracking({
    required this.bookingId,
    required this.status,
    this.driverLocation,
    this.vehicleLocation,
    this.distanceToPickup,
    this.estimatedArrival,
    this.estimatedTripTime,
    required this.updates,
    required this.lastUpdated,
  });

  factory BookingTracking.fromJson(Map<String, dynamic> json) {
    return BookingTracking(
      bookingId: json['bookingId'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      driverLocation: json['driverLocation'] != null
          ? LatLng(json['driverLocation']['latitude'], json['driverLocation']['longitude'])
          : null,
      vehicleLocation: json['vehicleLocation'] != null
          ? LatLng(json['vehicleLocation']['latitude'], json['vehicleLocation']['longitude'])
          : null,
      distanceToPickup: json['distanceToPickup'] != null
          ? (json['distanceToPickup'] as num).toDouble()
          : null,
      estimatedArrival: json['estimatedArrival'] != null
          ? Duration(minutes: json['estimatedArrival'])
          : null,
      estimatedTripTime: json['estimatedTripTime'] != null
          ? Duration(minutes: json['estimatedTripTime'])
          : null,
      updates: (json['updates'] as List<dynamic>?)
          ?.map((update) => TrackingUpdate.fromJson(update))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'status': status.toString().split('.').last,
      'driverLocation': driverLocation != null ? {
        'latitude': driverLocation!.latitude,
        'longitude': driverLocation!.longitude,
      } : null,
      'vehicleLocation': vehicleLocation != null ? {
        'latitude': vehicleLocation!.latitude,
        'longitude': vehicleLocation!.longitude,
      } : null,
      'distanceToPickup': distanceToPickup,
      'estimatedArrival': estimatedArrival?.inMinutes,
      'estimatedTripTime': estimatedTripTime?.inMinutes,
      'updates': updates.map((update) => update.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Tracking update model
class TrackingUpdate {
  final String id;
  final String type;
  final String message;
  final LatLng? location;
  final DateTime timestamp;

  TrackingUpdate({
    required this.id,
    required this.type,
    required this.message,
    this.location,
    required this.timestamp,
  });

  factory TrackingUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingUpdate(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      location: json['location'] != null
          ? LatLng(json['location']['latitude'], json['location']['longitude'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'location': location != null ? {
        'latitude': location!.latitude,
        'longitude': location!.longitude,
      } : null,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Booking statistics model
class BookingStats {
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int activeBookings;
  final double totalSpent;
  final double averageRating;
  final String favoriteVehicle;
  final String mostUsedPickupLocation;
  final Map<String, int> bookingsByMonth;
  final Map<String, int> bookingsByStatus;

  BookingStats({
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.activeBookings,
    required this.totalSpent,
    required this.averageRating,
    required this.favoriteVehicle,
    required this.mostUsedPickupLocation,
    required this.bookingsByMonth,
    required this.bookingsByStatus,
  });

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      activeBookings: json['activeBookings'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      favoriteVehicle: json['favoriteVehicle'] ?? '',
      mostUsedPickupLocation: json['mostUsedPickupLocation'] ?? '',
      bookingsByMonth: Map<String, int>.from(json['bookingsByMonth'] ?? {}),
      bookingsByStatus: Map<String, int>.from(json['bookingsByStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'activeBookings': activeBookings,
      'totalSpent': totalSpent,
      'averageRating': averageRating,
      'favoriteVehicle': favoriteVehicle,
      'mostUsedPickupLocation': mostUsedPickupLocation,
      'bookingsByMonth': bookingsByMonth,
      'bookingsByStatus': bookingsByStatus,
    };
  }
}

/// Booking modification model
class BookingModification {
  final String id;
  final String bookingId;
  final String modificationType;
  final Map<String, dynamic> originalData;
  final Map<String, dynamic> requestedChanges;
  final String status;
  final String? reason;
  final String? adminNote;
  final DateTime requestedAt;
  final DateTime? processedAt;

  BookingModification({
    required this.id,
    required this.bookingId,
    required this.modificationType,
    required this.originalData,
    required this.requestedChanges,
    required this.status,
    this.reason,
    this.adminNote,
    required this.requestedAt,
    this.processedAt,
  });

  factory BookingModification.fromJson(Map<String, dynamic> json) {
    return BookingModification(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      modificationType: json['modificationType'] ?? '',
      originalData: json['originalData'] ?? {},
      requestedChanges: json['requestedChanges'] ?? {},
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      adminNote: json['adminNote'],
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'modificationType': modificationType,
      'originalData': originalData,
      'requestedChanges': requestedChanges,
      'status': status,
      'reason': reason,
      'adminNote': adminNote,
      'requestedAt': requestedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}

/// Booking receipt model
class BookingReceipt {
  final String id;
  final String bookingId;
  final String invoiceNumber;
  final String customerName;
  final String customerEmail;
  final Map<String, dynamic> serviceDetails;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final String paymentMethod;
  final String status;
  final DateTime issuedAt;
  final DateTime? paidAt;
  final String? pdfUrl;

  BookingReceipt({
    required this.id,
    required this.bookingId,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerEmail,
    required this.serviceDetails,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.issuedAt,
    this.paidAt,
    this.pdfUrl,
  });

  factory BookingReceipt.fromJson(Map<String, dynamic> json) {
    return BookingReceipt(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      serviceDetails: json['serviceDetails'] ?? {},
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'ZAR',
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? 'pending',
      issuedAt: DateTime.parse(json['issuedAt'] ?? DateTime.now().toIso8601String()),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      pdfUrl: json['pdfUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'serviceDetails': serviceDetails,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status,
      'issuedAt': issuedAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'pdfUrl': pdfUrl,
    };
  }
} 