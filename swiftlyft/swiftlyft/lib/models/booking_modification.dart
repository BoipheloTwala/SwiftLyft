class BookingModification {
  final String id;
  final String bookingId;
  final Map<String, dynamic> requestedChanges;
  final String status; // pending, approved, rejected
  final String? reason;
  final DateTime createdAt;
  final DateTime? processedAt;

  BookingModification({
    required this.id,
    required this.bookingId,
    required this.requestedChanges,
    required this.status,
    this.reason,
    required this.createdAt,
    this.processedAt,
  });

  factory BookingModification.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> normalizeChanges(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      return <String, dynamic>{};
    }

    return BookingModification(
      id: json['id'] ?? json['_id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      requestedChanges: normalizeChanges(json['requestedChanges'] ?? json['changes']),
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'requestedChanges': requestedChanges,
      'status': status,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}


