import 'package:flutter/foundation.dart';

class CorporateAccount {
  final String id;
  final String companyName;
  final String companyEmail;
  final String contactPerson;
  final String contactPhone;
  final double discountPercentage;
  final double monthlyBudget;
  final double usedBudget;
  final String status; // 'active', 'suspended', 'pending'
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<String> authorizedUsers;

  CorporateAccount({
    required this.id,
    required this.companyName,
    required this.companyEmail,
    required this.contactPerson,
    required this.contactPhone,
    required this.discountPercentage,
    required this.monthlyBudget,
    required this.usedBudget,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    required this.authorizedUsers,
  });

  factory CorporateAccount.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('      🎯 ENTERED CorporateAccount.fromJson');
      
      // Helper to safely convert any value to string
      String safeString(dynamic value, [String defaultValue = '']) {
        if (value == null) return defaultValue;
        if (value is String) return value;
        return value.toString();
      }
      
      // Helper to parse date that might be a string, empty object, or null
      DateTime? parseDateOrNull(dynamic value) {
        if (value == null) return null;
        if (value is String && value.isNotEmpty) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            return null;
          }
        }
        // If it's an empty object {} or invalid, return null
        return null;
      }

      debugPrint('      🔍 About to parse all fields...');
      final id = safeString(json['id']);
      debugPrint('      ✓ id: $id');
      final companyName = safeString(json['companyName']);
      debugPrint('      ✓ companyName: $companyName');
      final companyEmail = safeString(json['companyEmail']);
      debugPrint('      ✓ companyEmail: $companyEmail');
      final contactPerson = safeString(json['contactPerson']);
      debugPrint('      ✓ contactPerson: $contactPerson');
      final contactPhone = safeString(json['contactPhone']);
      debugPrint('      ✓ contactPhone: $contactPhone');
      final discountPercentage = (json['discountPercentage'] ?? 0.0).toDouble();
      debugPrint('      ✓ discountPercentage: $discountPercentage');
      final monthlyBudget = (json['monthlyBudget'] ?? 0.0).toDouble();
      debugPrint('      ✓ monthlyBudget: $monthlyBudget');
      final usedBudget = (json['usedBudget'] ?? 0.0).toDouble();
      debugPrint('      ✓ usedBudget: $usedBudget');
      final status = safeString(json['status'], 'pending');
      debugPrint('      ✓ status: $status');
      final createdAt = parseDateOrNull(json['createdAt']) ?? DateTime.now();
      debugPrint('      ✓ createdAt: $createdAt');
      final expiresAt = parseDateOrNull(json['expiresAt']);
      debugPrint('      ✓ expiresAt: $expiresAt');
      final authorizedUsers = (json['authorizedUsers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      debugPrint('      ✓ authorizedUsers: ${authorizedUsers.length} users');

      debugPrint('      🔧 Creating CorporateAccount object...');
      return CorporateAccount(
        id: id,
        companyName: companyName,
        companyEmail: companyEmail,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
        discountPercentage: discountPercentage,
        monthlyBudget: monthlyBudget,
        usedBudget: usedBudget,
        status: status,
        createdAt: createdAt,
        expiresAt: expiresAt,
        authorizedUsers: authorizedUsers,
      );
    } catch (e, stackTrace) {
      debugPrint('      ❌ CorporateAccount.fromJson error: $e');
      debugPrint('      ❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'companyEmail': companyEmail,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'discountPercentage': discountPercentage,
      'monthlyBudget': monthlyBudget,
      'usedBudget': usedBudget,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      'authorizedUsers': authorizedUsers,
    };
  }

  double get remainingBudget => monthlyBudget - usedBudget;
  double get budgetUsagePercentage => 
      monthlyBudget > 0 ? (usedBudget / monthlyBudget).clamp(0.0, 1.0) : 0.0;
  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isPending => status == 'pending';
}

class CorporateBookingTrip {
  final String tripId;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropoffLocation;
  final DateTime? scheduledTime;
  final String passengerName;
  final String? passengerPhone;
  final double? estimatedCost;
  final String status; // 'pending', 'assigned', 'completed', 'cancelled'
  final String? assignedDriverId;

  CorporateBookingTrip({
    required this.tripId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.scheduledTime,
    required this.passengerName,
    this.passengerPhone,
    this.estimatedCost,
    required this.status,
    this.assignedDriverId,
  });

  factory CorporateBookingTrip.fromJson(Map<String, dynamic> json) {
    return CorporateBookingTrip(
      tripId: json['tripId'] ?? '',
      pickupLocation: json['pickupLocation'] ?? {},
      dropoffLocation: json['dropoffLocation'] ?? {},
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
      passengerName: json['passengerName'] ?? '',
      passengerPhone: json['passengerPhone'],
      estimatedCost: json['estimatedCost'] != null
          ? (json['estimatedCost'] as num).toDouble()
          : null,
      status: json['status'] ?? 'pending',
      assignedDriverId: json['assignedDriverId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      if (scheduledTime != null) 'scheduledTime': scheduledTime!.toIso8601String(),
      'passengerName': passengerName,
      if (passengerPhone != null) 'passengerPhone': passengerPhone,
      if (estimatedCost != null) 'estimatedCost': estimatedCost,
      'status': status,
      if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
    };
  }
}

class CorporateBooking {
  final String id;
  final String title;
  final String? description;
  final String bookingType; // 'one-time', 'recurring'
  final List<CorporateBookingTrip> trips;
  final double totalEstimatedCost;
  final String? specialInstructions;
  final String status; // 'pending', 'confirmed', 'in-progress', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;

  CorporateBooking({
    required this.id,
    required this.title,
    this.description,
    required this.bookingType,
    required this.trips,
    required this.totalEstimatedCost,
    this.specialInstructions,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
  });

  factory CorporateBooking.fromJson(Map<String, dynamic> json) {
    return CorporateBooking(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      bookingType: json['bookingType'] ?? 'one-time',
      trips: (json['trips'] as List<dynamic>?)
          ?.map((e) => CorporateBookingTrip.fromJson(e))
          .toList() ?? [],
      totalEstimatedCost: (json['totalEstimatedCost'] ?? 0.0).toDouble(),
      specialInstructions: json['specialInstructions'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'bookingType': bookingType,
      'trips': trips.map((t) => t.toJson()).toList(),
      'totalEstimatedCost': totalEstimatedCost,
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  int get totalTrips => trips.length;
  int get completedTrips => trips.where((t) => t.status == 'completed').length;
  int get pendingTrips => trips.where((t) => t.status == 'pending').length;
}

class CorporateInfo {
  final CorporateAccount corporateAccount;
  final List<CorporateBooking> bulkBookings;

  CorporateInfo({
    required this.corporateAccount,
    required this.bulkBookings,
  });

  factory CorporateInfo.fromJson(Map<String, dynamic> json) {
    return CorporateInfo(
      corporateAccount: CorporateAccount.fromJson(json['corporateAccount'] ?? {}),
      bulkBookings: (json['bulkBookings'] as List<dynamic>?)
          ?.map((e) => CorporateBooking.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'corporateAccount': corporateAccount.toJson(),
      'bulkBookings': bulkBookings.map((b) => b.toJson()).toList(),
    };
  }
}

