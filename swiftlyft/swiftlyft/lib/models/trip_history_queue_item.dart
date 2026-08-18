/// Model for items in the trip history processing queue
class TripHistoryQueueItem {
  final String id;
  final String bookingId;
  final TripQueueOperation operation;
  final Map<String, dynamic>? data;
  final DateTime queuedAt;
  final QueueItemStatus status;
  String? error;
  DateTime? processedAt;

  TripHistoryQueueItem({
    required this.id,
    required this.bookingId,
    required this.operation,
    this.data,
    DateTime? queuedAt,
    this.status = QueueItemStatus.pending,
    this.error,
    this.processedAt,
  }) : queuedAt = queuedAt ?? DateTime.now();

  /// Create from JSON
  factory TripHistoryQueueItem.fromJson(Map<String, dynamic> json) {
    return TripHistoryQueueItem(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      operation: TripQueueOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => TripQueueOperation.updateStatus,
      ),
      data: json['data'] as Map<String, dynamic>?,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      status: QueueItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QueueItemStatus.pending,
      ),
      error: json['error'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'operation': operation.name,
      'data': data,
      'queuedAt': queuedAt.toIso8601String(),
      'status': status.name,
      'error': error,
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated status
  TripHistoryQueueItem copyWith({
    QueueItemStatus? status,
    String? error,
    DateTime? processedAt,
  }) {
    return TripHistoryQueueItem(
      id: id,
      bookingId: bookingId,
      operation: operation,
      data: data,
      queuedAt: queuedAt,
      status: status ?? this.status,
      error: error ?? this.error,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

/// Types of operations that can be queued
enum TripQueueOperation {
  updateStatus,
  cancelBooking,
  rateBooking,
  deleteBooking,
  refreshBooking,
  markComplete,
}

/// Status of queue items
enum QueueItemStatus {
  pending,
  processing,
  completed,
  failed,
}

