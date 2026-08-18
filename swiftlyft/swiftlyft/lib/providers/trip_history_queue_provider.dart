import 'package:flutter/foundation.dart';
import 'dart:collection';
import '../models/trip_history_queue_item.dart';
import '../providers/app_state.dart';

/// Provider for managing trip history operations queue
/// Uses FIFO (First In, First Out) queue for processing booking operations
class TripHistoryQueueProvider extends ChangeNotifier {
  final Queue<TripHistoryQueueItem> _queue = Queue<TripHistoryQueueItem>();
  final Map<String, TripHistoryQueueItem> _processingItems = {};
  final Map<String, TripHistoryQueueItem> _completedItems = {};
  bool _isProcessing = false;
  AppState? _appState;

  /// Set AppState reference for backend operations
  void setAppState(AppState appState) {
    _appState = appState;
  }

  /// Get all queue items
  List<TripHistoryQueueItem> get queueItems => List.unmodifiable(_queue);

  /// Get processing items
  List<TripHistoryQueueItem> get processingItems =>
      List.unmodifiable(_processingItems.values);

  /// Get completed items
  List<TripHistoryQueueItem> get completedItems =>
      List.unmodifiable(_completedItems.values);

  /// Get pending count
  int get pendingCount => _queue.length;

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty && _processingItems.isEmpty;

  /// Check if processing
  bool get isProcessing => _isProcessing;

  /// Add operation to queue
  String enqueue({
    required String bookingId,
    required TripQueueOperation operation,
    Map<String, dynamic>? data,
  }) {
    final item = TripHistoryQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: bookingId,
      operation: operation,
      data: data,
    );

    _queue.add(item);
    debugPrint('📥 Queued operation: ${operation.name} for booking $bookingId');
    notifyListeners();

    // Start processing if not already processing
    if (!_isProcessing) {
      _processQueue();
    }

    return item.id;
  }

  /// Process queue (FIFO order)
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    _isProcessing = true;
    notifyListeners();

    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      _processingItems[item.id] = item.copyWith(status: QueueItemStatus.processing);
      notifyListeners();

      try {
        await _processItem(item);
        
        // Mark as completed
        _processingItems.remove(item.id);
        _completedItems[item.id] = item.copyWith(
          status: QueueItemStatus.completed,
          processedAt: DateTime.now(),
        );
        
        debugPrint('✅ Completed operation: ${item.operation.name} for booking ${item.bookingId}');
      } catch (e) {
        // Mark as failed
        _processingItems.remove(item.id);
        _completedItems[item.id] = item.copyWith(
          status: QueueItemStatus.failed,
          error: e.toString(),
          processedAt: DateTime.now(),
        );
        
        debugPrint('❌ Failed operation: ${item.operation.name} for booking ${item.bookingId}: $e');
      }

      notifyListeners();

      // Small delay between operations to avoid overwhelming backend
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isProcessing = false;
    notifyListeners();

    // Clean up old completed items (keep last 50)
    if (_completedItems.length > 50) {
      final sorted = _completedItems.values.toList()
        ..sort((a, b) => b.processedAt!.compareTo(a.processedAt!));
      final toRemove = sorted.skip(50).map((e) => e.id).toList();
      for (final id in toRemove) {
        _completedItems.remove(id);
      }
    }
  }

  /// Process individual queue item
  Future<void> _processItem(TripHistoryQueueItem item) async {
    if (_appState == null) {
      throw Exception('AppState not set');
    }

    switch (item.operation) {
      case TripQueueOperation.updateStatus:
        if (item.data?['status'] != null) {
          await _appState!.updateBookingStatus(
            item.bookingId,
            item.data!['status'] as String,
            notes: item.data?['notes'] as String?,
          );
        }
        break;

      case TripQueueOperation.cancelBooking:
        await _appState!.cancelBooking(item.bookingId);
        break;

      case TripQueueOperation.rateBooking:
        if (item.data?['rating'] != null) {
          await _appState!.rateDriver(
            item.data!['driverId'] as String,
            bookingId: item.bookingId,
            rating: (item.data!['rating'] as num).toDouble(),
            review: item.data?['review'] as String?,
          );
        }
        break;

      case TripQueueOperation.deleteBooking:
        _appState!.removeBooking(item.bookingId);
        break;

      case TripQueueOperation.refreshBooking:
        // Refresh all bookings - bookingId can be empty for this operation
        await _appState!.loadBookings(page: 1, reset: true);
        break;

      case TripQueueOperation.markComplete:
        // Transition through statuses to complete
        final statuses = ['confirmed', 'driverAssigned', 'driverEnRoute', 
                         'driverArrived', 'inProgress', 'completed'];
        for (final status in statuses) {
          try {
            await _appState!.updateBookingStatus(
              item.bookingId,
              status,
              notes: status == 'completed' 
                  ? 'Marked as completed by user' 
                  : 'Status transition',
            );
          } catch (e) {
            // Continue to next status if one fails
            if (status != 'completed') continue;
            rethrow;
          }
        }
        break;
    }
  }

  /// Clear completed items
  void clearCompleted() {
    _completedItems.clear();
    notifyListeners();
  }

  /// Clear all queue items
  void clearQueue() {
    _queue.clear();
    _processingItems.clear();
    _completedItems.clear();
    _isProcessing = false;
    notifyListeners();
  }

  /// Retry failed operation
  void retryFailed(String itemId) {
    final failedItem = _completedItems[itemId];
    if (failedItem != null && failedItem.status == QueueItemStatus.failed) {
      _completedItems.remove(itemId);
      
      // Re-enqueue with same parameters
      enqueue(
        bookingId: failedItem.bookingId,
        operation: failedItem.operation,
        data: failedItem.data,
      );
    }
  }

  /// Get item status
  QueueItemStatus? getItemStatus(String itemId) {
    if (_processingItems.containsKey(itemId)) {
      return QueueItemStatus.processing;
    }
    return _completedItems[itemId]?.status;
  }
}

