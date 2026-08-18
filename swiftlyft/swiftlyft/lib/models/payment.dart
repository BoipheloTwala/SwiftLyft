/// Payment method model
class PaymentMethod {
  final String id;
  final String userId;
  final String type;
  final String cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? holderName;
  final String? brand;
  final bool isDefault;
  final bool isActive;
  final bool isExpired;
  final Map<String, dynamic>? billingAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.holderName,
    this.brand,
    required this.isDefault,
    required this.isActive,
    required this.isExpired,
    this.billingAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'card',
      cardNumber: json['cardNumber'] ?? '',
      expiryMonth: json['expiryMonth'],
      expiryYear: json['expiryYear'],
      holderName: json['holderName'],
      brand: json['brand'],
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? true,
      isExpired: json['isExpired'] ?? false,
      billingAddress: json['billingAddress'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'holderName': holderName,
      'brand': brand,
      'isDefault': isDefault,
      'isActive': isActive,
      'isExpired': isExpired,
      'billingAddress': billingAddress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? userId,
    String? type,
    String? cardNumber,
    String? expiryMonth,
    String? expiryYear,
    String? holderName,
    String? brand,
    bool? isDefault,
    bool? isActive,
    bool? isExpired,
    Map<String, dynamic>? billingAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      holderName: holderName ?? this.holderName,
      brand: brand ?? this.brand,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      isExpired: isExpired ?? this.isExpired,
      billingAddress: billingAddress ?? this.billingAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get maskedCardNumber {
    if (cardNumber.length < 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }
}

/// Payment transaction model
class PaymentTransaction {
  final String id;
  final String userId;
  final String bookingId;
  final String paymentMethodId;
  final double amount;
  final double processingFee;
  final double netAmount;
  final String currency;
  final String status;
  final String transactionType;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? externalTransactionId;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.bookingId,
    required this.paymentMethodId,
    required this.amount,
    required this.processingFee,
    required this.netAmount,
    required this.currency,
    required this.status,
    required this.transactionType,
    this.description,
    this.metadata,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
    this.externalTransactionId,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      paymentMethodId: json['paymentMethodId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      processingFee: (json['processingFee'] ?? 0.0).toDouble(),
      netAmount: (json['netAmount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'ZAR',
      status: json['status'] ?? 'pending',
      transactionType: json['transactionType'] ?? 'payment',
      description: json['description'],
      metadata: json['metadata'],
      failureReason: json['failureReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      externalTransactionId: json['externalTransactionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookingId': bookingId,
      'paymentMethodId': paymentMethodId,
      'amount': amount,
      'processingFee': processingFee,
      'netAmount': netAmount,
      'currency': currency,
      'status': status,
      'transactionType': transactionType,
      'description': description,
      'metadata': metadata,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'externalTransactionId': externalTransactionId,
    };
  }
}

/// Payment method validation model
class PaymentMethodValidation {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? validationDetails;

  PaymentMethodValidation({
    required this.isValid,
    this.errorMessage,
    this.validationDetails,
  });

  factory PaymentMethodValidation.fromJson(Map<String, dynamic> json) {
    return PaymentMethodValidation(
      isValid: json['isValid'] ?? false,
      errorMessage: json['errorMessage'],
      validationDetails: json['validationDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'errorMessage': errorMessage,
      'validationDetails': validationDetails,
    };
  }
}

/// Payment statistics model
class PaymentStats {
  final int totalTransactions;
  final int successfulTransactions;
  final int failedTransactions;
  final double totalAmount;
  final double averageTransactionAmount;
  final Map<String, int> transactionsByStatus;
  final Map<String, double> amountByMethod;
  final DateTime lastUpdated;

  PaymentStats({
    required this.totalTransactions,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.totalAmount,
    required this.averageTransactionAmount,
    required this.transactionsByStatus,
    required this.amountByMethod,
    required this.lastUpdated,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      totalTransactions: json['totalTransactions'] ?? 0,
      successfulTransactions: json['successfulTransactions'] ?? 0,
      failedTransactions: json['failedTransactions'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      averageTransactionAmount: (json['averageTransactionAmount'] ?? 0.0).toDouble(),
      transactionsByStatus: Map<String, int>.from(json['transactionsByStatus'] ?? {}),
      amountByMethod: Map<String, double>.from(json['amountByMethod'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTransactions': totalTransactions,
      'successfulTransactions': successfulTransactions,
      'failedTransactions': failedTransactions,
      'totalAmount': totalAmount,
      'averageTransactionAmount': averageTransactionAmount,
      'transactionsByStatus': transactionsByStatus,
      'amountByMethod': amountByMethod,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
