import 'package:flutter/foundation.dart';
import '../models/booking.dart';

/// Service for handling trip milestone notifications
class TripNotificationService {
  static final TripNotificationService _instance = TripNotificationService._internal();
  factory TripNotificationService() => _instance;

  final Map<String, Set<TripMilestone>> _notifiedMilestones = {};
  final List<Function(TripNotification)> _listeners = [];

  TripNotificationService._internal();

  /// Add a notification listener
  void addListener(Function(TripNotification) listener) {
    _listeners.add(listener);
  }

  /// Remove a notification listener
  void removeListener(Function(TripNotification) listener) {
    _listeners.remove(listener);
  }

  /// Check and notify about trip milestones
  void checkMilestones(Booking booking, {int? eta}) {
    final bookingId = booking.id;
    final notified = _notifiedMilestones[bookingId] ?? <TripMilestone>{};

    // Check status changes
    _checkStatusMilestone(booking, notified);

    // Check ETA milestones
    if (eta != null) {
      _checkETAMilestone(booking, eta, notified);
    }

    _notifiedMilestones[bookingId] = notified;
  }

  void _checkStatusMilestone(Booking booking, Set<TripMilestone> notified) {
    final status = booking.status;

    if (status == BookingStatus.driverAssigned && !notified.contains(TripMilestone.driverAssigned)) {
      final driverName = booking.driverName.isNotEmpty ? booking.driverName : 'Your driver';
      _notify(TripNotification(
        bookingId: booking.id,
        milestone: TripMilestone.driverAssigned,
        title: 'Driver Assigned',
        message: '$driverName is on the way to pick you up',
        icon: '🚗',
      ));
      notified.add(TripMilestone.driverAssigned);
    }

    if (status == BookingStatus.driverArrived && !notified.contains(TripMilestone.driverArrived)) {
      _notify(TripNotification(
        bookingId: booking.id,
        milestone: TripMilestone.driverArrived,
        title: 'Driver Arrived',
        message: 'Your driver has arrived at the pickup location',
        icon: '📍',
      ));
      notified.add(TripMilestone.driverArrived);
    }

    if (status == BookingStatus.inProgress && !notified.contains(TripMilestone.tripStarted)) {
      _notify(TripNotification(
        bookingId: booking.id,
        milestone: TripMilestone.tripStarted,
        title: 'Trip Started',
        message: 'Your trip has started. Enjoy your ride!',
        icon: '🎉',
      ));
      notified.add(TripMilestone.tripStarted);
    }

    if (status == BookingStatus.completed && !notified.contains(TripMilestone.tripCompleted)) {
      _notify(TripNotification(
        bookingId: booking.id,
        milestone: TripMilestone.tripCompleted,
        title: 'Trip Completed',
        message: 'You have arrived at your destination. Thank you for riding with us!',
        icon: '✅',
      ));
      notified.add(TripMilestone.tripCompleted);
    }
  }

  void _checkETAMilestone(Booking booking, int eta, Set<TripMilestone> notified) {
    final status = booking.status;

    // Only check ETA for driver en route
    if (status != BookingStatus.driverAssigned) return;

    if (eta <= 5 && !notified.contains(TripMilestone.eta5Minutes)) {
      _notify(TripNotification(
        bookingId: booking.id,
        milestone: TripMilestone.eta5Minutes,
        title: 'Driver Almost Here',
        message: 'Your driver will arrive in approximately 5 minutes',
        icon: '⏱️',
      ));
      notified.add(TripMilestone.eta5Minutes);
    }

    if (eta <= 2 && !notified.contains(TripMilestone.eta2Minutes)) {
      _notify(TripNotification(
        bookingId: booking.id,
        milestone: TripMilestone.eta2Minutes,
        title: 'Driver Nearby',
        message: 'Your driver will arrive in approximately 2 minutes',
        icon: '🔔',
      ));
      notified.add(TripMilestone.eta2Minutes);
    }
  }

  void _notify(TripNotification notification) {
    debugPrint('📢 ${notification.title}: ${notification.message}');
    
    for (final listener in _listeners) {
      try {
        listener(notification);
      } catch (e) {
        debugPrint('Error in notification listener: $e');
      }
    }
  }

  /// Clear notified milestones for a booking (useful when tracking resumes)
  void clearMilestones(String bookingId) {
    _notifiedMilestones.remove(bookingId);
  }

  /// Clear all data
  void dispose() {
    _notifiedMilestones.clear();
    _listeners.clear();
  }
}

/// Trip milestone enum
enum TripMilestone {
  driverAssigned,
  driverArrived,
  tripStarted,
  tripCompleted,
  eta5Minutes,
  eta2Minutes,
}

/// Trip notification data
class TripNotification {
  final String bookingId;
  final TripMilestone milestone;
  final String title;
  final String message;
  final String icon;

  TripNotification({
    required this.bookingId,
    required this.milestone,
    required this.title,
    required this.message,
    required this.icon,
  });
}

