import 'booking.dart'; // Import for PaymentStatus

/// Bulk booking models for corporate users
/// Represents bulk transportation bookings for corporate accounts

enum BulkBookingStatus {
  draft,
  pending,
  confirmed,
  completed,
  cancelled,
}

/// Item within a bulk booking
class BulkBookingItem {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final int quantity;
  final double unitPrice;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime pickupTime;
  final int passengerCount;

  BulkBookingItem({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.quantity,
    required this.unitPrice,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    required this.passengerCount,
  });

  factory BulkBookingItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to string
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Map) return value['\$oid']?.toString() ?? value.toString();
      return value.toString();
    }

    return BulkBookingItem(
      id: safeString(json['_id']) != '' ? safeString(json['_id']) : safeString(json['id']),
      vehicleId: safeString(json['vehicleId']),
      vehicleName: safeString(json['vehicleName']),
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      pickupLocation: safeString(json['pickupLocation']),
      dropoffLocation: safeString(json['dropoffLocation']),
      pickupTime: json['pickupTime'] != null
          ? DateTime.parse(json['pickupTime'].toString())
          : DateTime.now(),
      passengerCount: json['passengerCount'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupTime': pickupTime.toIso8601String(),
      'passengerCount': passengerCount,
    };
  }

  double get totalPrice => quantity * unitPrice;
}

/// Bulk booking model
class BulkBooking {
  final String id;
  final String title;
  final String description;
  final List<BulkBookingItem> items;
  final BulkBookingStatus status;
  final PaymentStatus paymentStatus;
  final double totalAmount;
  final double discountAmount;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String? specialNotes;

  BulkBooking({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.discountAmount,
    required this.createdAt,
    this.scheduledDate,
    this.specialNotes,
  });

  factory BulkBooking.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to string
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Map) return value['\$oid']?.toString() ?? value.toString();
      return value.toString();
    }

    return BulkBooking(
      id: safeString(json['_id']) != '' ? safeString(json['_id']) : safeString(json['id']),
      title: safeString(json['title']),
      description: safeString(json['description']),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => BulkBookingItem.fromJson(item))
          .toList() ?? [],
      status: _parseStatus(safeString(json['status'], 'draft')),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['paymentStatus']}',
        orElse: () => PaymentStatus.pending,
      ),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'].toString())
          : null,
      specialNotes: json['specialNotes'] != null ? safeString(json['specialNotes']) : null,
    );
  }

  static BulkBookingStatus _parseStatus(String? status) {
    if (status == null) return BulkBookingStatus.draft;
    try {
      return BulkBookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status,
        orElse: () => BulkBookingStatus.draft,
      );
    } catch (e) {
      return BulkBookingStatus.draft;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'specialNotes': specialNotes,
    };
  }

  // Helper getters
  double get finalAmount => totalAmount - discountAmount;
  int get itemCount => items.length;
  int get totalVehicles => items.fold(0, (sum, item) => sum + item.quantity);
  int get totalPassengers => items.fold(0, (sum, item) => sum + (item.quantity * item.passengerCount));

  bool get isDraft => status == BulkBookingStatus.draft;
  bool get isPending => status == BulkBookingStatus.pending;
  bool get isConfirmed => status == BulkBookingStatus.confirmed;
  bool get isCompleted => status == BulkBookingStatus.completed;
  bool get isCancelled => status == BulkBookingStatus.cancelled;
  bool get isActive => !isCompleted && !isCancelled;
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  String get statusText {
    switch (status) {
      case BulkBookingStatus.draft:
        return 'Draft';
      case BulkBookingStatus.pending:
        return 'Pending';
      case BulkBookingStatus.confirmed:
        return 'Confirmed';
      case BulkBookingStatus.completed:
        return 'Completed';
      case BulkBookingStatus.cancelled:
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

  /// Create a copy of this booking with updated fields
  BulkBooking copyWith({
    String? id,
    String? title,
    String? description,
    List<BulkBookingItem>? items,
    BulkBookingStatus? status,
    PaymentStatus? paymentStatus,
    double? totalAmount,
    double? discountAmount,
    DateTime? createdAt,
    DateTime? scheduledDate,
    String? specialNotes,
  }) {
    return BulkBooking(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      specialNotes: specialNotes ?? this.specialNotes,
    );
  }
}

/// Pagination metadata for bulk bookings
class BulkBookingPagination {
  final int currentPage;
  final int totalPages;
  final int totalBookings;
  final bool hasNextPage;
  final bool hasPrevPage;

  BulkBookingPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalBookings,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory BulkBookingPagination.fromJson(Map<String, dynamic> json) {
    return BulkBookingPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalBookings: json['totalBookings'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalBookings': totalBookings,
      'hasNextPage': hasNextPage,
      'hasPrevPage': hasPrevPage,
    };
  }
}

/// Status counts for bulk bookings
class BulkBookingStatusCounts {
  final int draft;
  final int pending;
  final int confirmed;
  final int completed;
  final int cancelled;

  BulkBookingStatusCounts({
    required this.draft,
    required this.pending,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
  });

  factory BulkBookingStatusCounts.fromJson(Map<String, dynamic> json) {
    return BulkBookingStatusCounts(
      draft: json['draft'] ?? 0,
      pending: json['pending'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'draft': draft,
      'pending': pending,
      'confirmed': confirmed,
      'completed': completed,
      'cancelled': cancelled,
    };
  }

  int get total => draft + pending + confirmed + completed + cancelled;
  int get active => draft + pending + confirmed;
}

/// Summary information for bulk bookings
class BulkBookingSummary {
  final double totalAmount;
  final double totalDiscount;
  final int totalBookings;
  final BulkBookingStatusCounts statusCounts;

  BulkBookingSummary({
    required this.totalAmount,
    required this.totalDiscount,
    required this.totalBookings,
    required this.statusCounts,
  });

  factory BulkBookingSummary.fromJson(Map<String, dynamic> json) {
    return BulkBookingSummary(
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      totalDiscount: (json['totalDiscount'] ?? 0.0).toDouble(),
      totalBookings: json['totalBookings'] ?? 0,
      statusCounts: BulkBookingStatusCounts.fromJson(json['statusCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'totalDiscount': totalDiscount,
      'totalBookings': totalBookings,
      'statusCounts': statusCounts.toJson(),
    };
  }

  double get finalAmount => totalAmount - totalDiscount;
}

/// Complete bulk booking response from API
class BulkBookingsResponse {
  final List<BulkBooking> bulkBookings;
  final BulkBookingPagination pagination;
  final BulkBookingSummary summary;

  BulkBookingsResponse({
    required this.bulkBookings,
    required this.pagination,
    required this.summary,
  });

  factory BulkBookingsResponse.fromJson(Map<String, dynamic> json) {
    return BulkBookingsResponse(
      bulkBookings: (json['bulkBookings'] as List<dynamic>?)
          ?.map((booking) => BulkBooking.fromJson(booking))
          .toList() ?? [],
      pagination: BulkBookingPagination.fromJson(json['pagination'] ?? {}),
      summary: BulkBookingSummary.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bulkBookings': bulkBookings.map((b) => b.toJson()).toList(),
      'pagination': pagination.toJson(),
      'summary': summary.toJson(),
    };
  }

  bool get isEmpty => bulkBookings.isEmpty;
  bool get isNotEmpty => bulkBookings.isNotEmpty;
}

