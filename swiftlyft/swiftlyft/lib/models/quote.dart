/// Quote model
class Quote {
  final String id;
  final String userId;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropoffLocation;
  final String vehicleType;
  final String serviceType;
  final DateTime scheduledDate;
  final int passengerCount;
  final String? specialNotes;
  final bool closeProtectionOfficer;
  final Map<String, dynamic> estimatedPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? validUntil;
  final DateTime? updatedAt;

  Quote({
    required this.id,
    required this.userId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vehicleType,
    required this.serviceType,
    required this.scheduledDate,
    required this.passengerCount,
    this.specialNotes,
    required this.closeProtectionOfficer,
    required this.estimatedPrice,
    required this.status,
    required this.createdAt,
    this.validUntil,
    this.updatedAt,
  });

  /// Get the expiration date (alias for validUntil for backwards compatibility)
  DateTime get expiresAt => validUntil ?? createdAt.add(const Duration(hours: 24));

  /// Check if the quote has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get base price from estimatedPrice
  /// Handles both frontend format (basePrice) and backend format (baseFare)
  double get basePrice => (estimatedPrice['basePrice'] ?? estimatedPrice['baseFare'] ?? 0.0).toDouble();

  /// Get distance fee from estimatedPrice
  /// Handles both frontend format (distanceFee) and backend format (distanceFare)
  double get distanceFee => (estimatedPrice['distanceFee'] ?? estimatedPrice['distanceFare'] ?? 0.0).toDouble();

  /// Get time fee from estimatedPrice
  /// Handles both frontend format (timeFee) and backend format (timeFare)
  double get timeFee => (estimatedPrice['timeFee'] ?? estimatedPrice['timeFare'] ?? 0.0).toDouble();

  /// Get protection officer fee from estimatedPrice
  double get protectionOfficerFee => (estimatedPrice['protectionOfficerFee'] ?? 500.0).toDouble();

  /// Get final price from estimatedPrice
  double get finalPrice => (estimatedPrice['finalPrice'] ?? totalPrice).toDouble();

  /// Calculate total price
  double get totalPrice {
    double total = basePrice;
    total += distanceFee;
    total += timeFee;
    if (closeProtectionOfficer) {
      total += protectionOfficerFee;
    }
    return total;
  }

  /// Get adjusted pricing for luxury service display (frontend-only)
  /// This applies multipliers to make prices realistic for a premium chauffeur service
  /// Backend data remains unchanged - this is for display only
  Map<String, dynamic> get adjustedPricing {
    // Import the helper at the top of the file
    // For now, we'll calculate it directly here to avoid circular imports
    final multipliers = {
      'sedan': 3.5,
      'suv': 4.0,
      'luxury': 5.0,
      'van': 4.5,
      'truck': 4.5,
      'hybrid': 4.0,
    };
    
    final vehicleMultiplier = multipliers[vehicleType.toLowerCase()] ?? 4.0;
    
    // Adjust base price
    final adjustedBase = (basePrice * vehicleMultiplier).roundToDouble();
    
    // Adjust distance fee (multiplier: 2.8 to 3.3)
    final distanceMultiplier = 2.8 + (vehicleMultiplier - 3.5) * 0.3;
    final adjustedDistance = (distanceFee * distanceMultiplier).roundToDouble();
    
    // Adjust time fee (multiplier: 7.0 to 8.25)
    final timeMultiplier = 7.0 + (vehicleMultiplier - 3.5) * 0.5;
    final adjustedTime = (timeFee * timeMultiplier).roundToDouble();
    
    // Get service fee from estimatedPrice if available, otherwise estimate
    final originalServiceFee = (estimatedPrice['serviceFee'] ?? 0.0).toDouble();
    final serviceMultiplier = 6.0 + (vehicleMultiplier - 3.5) * 0.8;
    final adjustedServiceFee = (originalServiceFee * serviceMultiplier).roundToDouble();
    
    // Calculate subtotal
    double subtotal = adjustedBase + adjustedDistance + adjustedTime + adjustedServiceFee;
    if (closeProtectionOfficer) {
      subtotal += protectionOfficerFee;
    }
    
    // Calculate taxes (15% VAT)
    final taxes = (subtotal * 0.15).roundToDouble();
    
    // Calculate total
    var total = (subtotal + taxes).roundToDouble();
    
    // Ensure minimum price of R2500
    if (total < 2500.0) {
      final shortfall = 2500.0 - total;
      final finalBase = adjustedBase + (shortfall * 0.5);
      final finalDistance = adjustedDistance + (shortfall * 0.3);
      final finalTime = adjustedTime + (shortfall * 0.2);
      
      final newSubtotal = finalBase + finalDistance + finalTime + adjustedServiceFee;
      if (closeProtectionOfficer) {
        subtotal = newSubtotal + protectionOfficerFee;
      } else {
        subtotal = newSubtotal;
      }
      final newTaxes = (subtotal * 0.15).roundToDouble();
      total = (subtotal + newTaxes).roundToDouble();
      
      return {
        'baseFare': finalBase.roundToDouble(),
        'distanceFare': finalDistance.roundToDouble(),
        'timeFare': finalTime.roundToDouble(),
        'serviceFee': adjustedServiceFee.roundToDouble(),
        'protectionOfficerFee': closeProtectionOfficer ? protectionOfficerFee : 0.0,
        'taxes': newTaxes,
        'total': total,
      };
    }
    
    return {
      'baseFare': adjustedBase,
      'distanceFare': adjustedDistance,
      'timeFare': adjustedTime,
      'serviceFee': adjustedServiceFee,
      'protectionOfficerFee': closeProtectionOfficer ? protectionOfficerFee : 0.0,
      'taxes': taxes,
      'total': total,
    };
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> normalizeLocation(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is String) {
        return {
          'address': value,
          'coordinates': <String, dynamic>{},
        };
      }
      return <String, dynamic>{};
    }

    Map<String, dynamic> normalizePricing(dynamic value) {
      if (value is Map<String, dynamic>) {
        // Map backend field names to frontend expected names
        // Backend uses: baseFare, distanceFare, timeFare
        // Frontend expects: basePrice, distanceFee, timeFee
        final Map<String, dynamic> mapped = Map<String, dynamic>.from(value);
        
        // Map baseFare -> basePrice
        if (mapped.containsKey('baseFare') && !mapped.containsKey('basePrice')) {
          mapped['basePrice'] = mapped['baseFare'];
        }
        
        // Map distanceFare -> distanceFee
        if (mapped.containsKey('distanceFare') && !mapped.containsKey('distanceFee')) {
          mapped['distanceFee'] = mapped['distanceFare'];
        }
        
        // Map timeFare -> timeFee
        if (mapped.containsKey('timeFare') && !mapped.containsKey('timeFee')) {
          mapped['timeFee'] = mapped['timeFare'];
        }
        
        // Ensure finalPrice exists (use total if available)
        if (!mapped.containsKey('finalPrice') && mapped.containsKey('total')) {
          mapped['finalPrice'] = mapped['total'];
        }
        
        return mapped;
      }
      if (value is num) return {'finalPrice': value.toDouble()};
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return {'finalPrice': parsed};
      }
      return <String, dynamic>{};
    }

    // Handle both dateTime and scheduledDate for backwards compatibility
    String? dateValue;
    if (json['scheduledDate'] != null) {
      dateValue = json['scheduledDate'].toString();
    } else if (json['dateTime'] != null) {
      dateValue = json['dateTime'].toString();
    }
    
    return Quote(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      pickupLocation: normalizeLocation(json['pickupLocation']),
      dropoffLocation: normalizeLocation(json['dropoffLocation']),
      vehicleType: json['vehicleType'] ?? '',
      serviceType: json['serviceType'] ?? '',
      scheduledDate: dateValue != null 
          ? DateTime.parse(dateValue)
          : DateTime.parse(DateTime.now().toIso8601String()),
      passengerCount: json['passengerCount'] ?? 1,
      specialNotes: json['specialNotes'] ?? json['specialRequirements'],
      closeProtectionOfficer: json['closeProtectionOfficer'] ?? false,
      estimatedPrice: normalizePricing(json['estimatedPrice'] ?? json['pricing']),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      validUntil: json['validUntil'] != null ? DateTime.parse(json['validUntil']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'vehicleType': vehicleType,
      'serviceType': serviceType,
      'scheduledDate': scheduledDate.toIso8601String(),
      'passengerCount': passengerCount,
      'specialNotes': specialNotes,
      'closeProtectionOfficer': closeProtectionOfficer,
      'estimatedPrice': estimatedPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Quote copyWith({
    String? id,
    String? userId,
    Map<String, dynamic>? pickupLocation,
    Map<String, dynamic>? dropoffLocation,
    String? vehicleType,
    String? serviceType,
    DateTime? scheduledDate,
    int? passengerCount,
    String? specialNotes,
    bool? closeProtectionOfficer,
    Map<String, dynamic>? estimatedPrice,
    String? status,
    DateTime? createdAt,
    DateTime? validUntil,
    DateTime? updatedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      vehicleType: vehicleType ?? this.vehicleType,
      serviceType: serviceType ?? this.serviceType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      passengerCount: passengerCount ?? this.passengerCount,
      specialNotes: specialNotes ?? this.specialNotes,
      closeProtectionOfficer: closeProtectionOfficer ?? this.closeProtectionOfficer,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      validUntil: validUntil ?? this.validUntil,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Quote acceptance model
class QuoteAcceptance {
  final String id;
  final String quoteId;
  final String bookingId;
  final String status;
  final Map<String, dynamic>? modifications;
  final DateTime acceptedAt;

  QuoteAcceptance({
    required this.id,
    required this.quoteId,
    required this.bookingId,
    required this.status,
    this.modifications,
    required this.acceptedAt,
  });

  factory QuoteAcceptance.fromJson(Map<String, dynamic> json) {
    return QuoteAcceptance(
      id: json['id'] ?? '',
      quoteId: json['quoteId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      status: json['status'] ?? 'pending',
      modifications: json['modifications'],
      acceptedAt: DateTime.parse(json['acceptedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoteId': quoteId,
      'bookingId': bookingId,
      'status': status,
      'modifications': modifications,
      'acceptedAt': acceptedAt.toIso8601String(),
    };
  }
}

/// Quote modification model
class QuoteModification {
  final String id;
  final String quoteId;
  final String modificationType;
  final Map<String, dynamic> originalData;
  final Map<String, dynamic> requestedChanges;
  final String status;
  final String? reason;
  final String? adminResponse;
  final DateTime requestedAt;
  final DateTime? processedAt;

  QuoteModification({
    required this.id,
    required this.quoteId,
    required this.modificationType,
    required this.originalData,
    required this.requestedChanges,
    required this.status,
    this.reason,
    this.adminResponse,
    required this.requestedAt,
    this.processedAt,
  });

  factory QuoteModification.fromJson(Map<String, dynamic> json) {
    return QuoteModification(
      id: json['id'] ?? '',
      quoteId: json['quoteId'] ?? '',
      modificationType: json['modificationType'] ?? '',
      originalData: json['originalData'] ?? {},
      requestedChanges: json['requestedChanges'] ?? {},
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      adminResponse: json['adminResponse'],
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoteId': quoteId,
      'modificationType': modificationType,
      'originalData': originalData,
      'requestedChanges': requestedChanges,
      'status': status,
      'reason': reason,
      'adminResponse': adminResponse,
      'requestedAt': requestedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}

/// Quote statistics model
class QuoteStats {
  final int totalQuotes;
  final int acceptedQuotes;
  final int rejectedQuotes;
  final int expiredQuotes;
  final int pendingQuotes;
  final double averageQuoteValue;
  final Map<String, int> quotesByStatus;
  final Map<String, int> quotesByVehicleType;
  final DateTime lastUpdated;

  QuoteStats({
    required this.totalQuotes,
    required this.acceptedQuotes,
    required this.rejectedQuotes,
    required this.expiredQuotes,
    required this.pendingQuotes,
    required this.averageQuoteValue,
    required this.quotesByStatus,
    required this.quotesByVehicleType,
    required this.lastUpdated,
  });

  factory QuoteStats.fromJson(Map<String, dynamic> json) {
    return QuoteStats(
      totalQuotes: json['totalQuotes'] ?? 0,
      acceptedQuotes: json['acceptedQuotes'] ?? 0,
      rejectedQuotes: json['rejectedQuotes'] ?? 0,
      expiredQuotes: json['expiredQuotes'] ?? 0,
      pendingQuotes: json['pendingQuotes'] ?? 0,
      averageQuoteValue: (json['averageQuoteValue'] ?? 0.0).toDouble(),
      quotesByStatus: Map<String, int>.from(json['quotesByStatus'] ?? {}),
      quotesByVehicleType: Map<String, int>.from(json['quotesByVehicleType'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuotes': totalQuotes,
      'acceptedQuotes': acceptedQuotes,
      'rejectedQuotes': rejectedQuotes,
      'expiredQuotes': expiredQuotes,
      'pendingQuotes': pendingQuotes,
      'averageQuoteValue': averageQuoteValue,
      'quotesByStatus': quotesByStatus,
      'quotesByVehicleType': quotesByVehicleType,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Quote template model
class QuoteTemplate {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> templateData;
  final List<String> applicableVehicleTypes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuoteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.templateData,
    required this.applicableVehicleTypes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuoteTemplate.fromJson(Map<String, dynamic> json) {
    return QuoteTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      templateData: json['templateData'] ?? {},
      applicableVehicleTypes: List<String>.from(json['applicableVehicleTypes'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'templateData': templateData,
      'applicableVehicleTypes': applicableVehicleTypes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Quote share model
class QuoteShare {
  final String id;
  final String quoteId;
  final List<String> recipientEmails;
  final String shareUrl;
  final DateTime sharedAt;
  final DateTime expiresAt;
  final int viewCount;

  QuoteShare({
    required this.id,
    required this.quoteId,
    required this.recipientEmails,
    required this.shareUrl,
    required this.sharedAt,
    required this.expiresAt,
    required this.viewCount,
  });

  factory QuoteShare.fromJson(Map<String, dynamic> json) {
    return QuoteShare(
      id: json['id'] ?? '',
      quoteId: json['quoteId'] ?? '',
      recipientEmails: List<String>.from(json['recipientEmails'] ?? []),
      shareUrl: json['shareUrl'] ?? '',
      sharedAt: DateTime.parse(json['sharedAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
      viewCount: json['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoteId': quoteId,
      'recipientEmails': recipientEmails,
      'shareUrl': shareUrl,
      'sharedAt': sharedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewCount': viewCount,
    };
  }
}
