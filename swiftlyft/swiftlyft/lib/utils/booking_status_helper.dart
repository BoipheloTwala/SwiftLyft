import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'theme.dart';

/// Helper class for booking status management
class BookingStatusHelper {
  /// Get color for a booking status
  static Color getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.driverAssigned:
        return Colors.indigo;
      case BookingStatus.driverEnRoute:
        return Colors.purple;
      case BookingStatus.driverArrived:
        return Colors.teal;
      case BookingStatus.inProgress:
        return SwiftLyftTheme.primaryBlue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return SwiftLyftTheme.errorRed;
    }
  }

  /// Get icon for a booking status
  static IconData getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.driverAssigned:
        return Icons.person_outline;
      case BookingStatus.driverEnRoute:
        return Icons.directions_car;
      case BookingStatus.driverArrived:
        return Icons.location_on;
      case BookingStatus.inProgress:
        return Icons.trip_origin;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Get description for a booking status
  static String getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Your booking is awaiting confirmation';
      case BookingStatus.confirmed:
        return 'Your booking has been confirmed';
      case BookingStatus.driverAssigned:
        return 'A driver has been assigned to your booking';
      case BookingStatus.driverEnRoute:
        return 'Your driver is on the way to pick you up';
      case BookingStatus.driverArrived:
        return 'Your driver has arrived at the pickup location';
      case BookingStatus.inProgress:
        return 'Your trip is currently in progress';
      case BookingStatus.completed:
        return 'Your trip has been completed successfully';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled';
    }
  }

  /// Check if a status transition is valid
  static bool isValidTransition(BookingStatus from, BookingStatus to) {
    // Define valid status transitions
    const validTransitions = {
      BookingStatus.pending: [
        BookingStatus.confirmed,
        BookingStatus.cancelled,
      ],
      BookingStatus.confirmed: [
        BookingStatus.driverAssigned,
        BookingStatus.cancelled,
      ],
      BookingStatus.driverAssigned: [
        BookingStatus.driverEnRoute,
        BookingStatus.cancelled,
      ],
      BookingStatus.driverEnRoute: [
        BookingStatus.driverArrived,
        BookingStatus.cancelled,
      ],
      BookingStatus.driverArrived: [
        BookingStatus.inProgress,
        BookingStatus.cancelled,
      ],
      BookingStatus.inProgress: [
        BookingStatus.completed,
        BookingStatus.cancelled,
      ],
      BookingStatus.completed: [],
      BookingStatus.cancelled: [],
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  /// Get allowed next statuses for a booking
  static List<BookingStatus> getAllowedNextStatuses(BookingStatus current) {
    const validTransitions = {
      BookingStatus.pending: [
        BookingStatus.confirmed,
        BookingStatus.cancelled,
      ],
      BookingStatus.confirmed: [
        BookingStatus.driverAssigned,
        BookingStatus.cancelled,
      ],
      BookingStatus.driverAssigned: [
        BookingStatus.driverEnRoute,
        BookingStatus.cancelled,
      ],
      BookingStatus.driverEnRoute: [
        BookingStatus.driverArrived,
        BookingStatus.cancelled,
      ],
      BookingStatus.driverArrived: [
        BookingStatus.inProgress,
        BookingStatus.cancelled,
      ],
      BookingStatus.inProgress: [
        BookingStatus.completed,
        BookingStatus.cancelled,
      ],
      BookingStatus.completed: [],
      BookingStatus.cancelled: [],
    };

    return validTransitions[current] ?? [];
  }

  /// Check if a booking can be cancelled
  static bool canBeCancelled(BookingStatus status) {
    return status != BookingStatus.completed && 
           status != BookingStatus.cancelled &&
           status != BookingStatus.inProgress;
  }

  /// Check if a booking can be modified
  static bool canBeModified(BookingStatus status) {
    return status == BookingStatus.pending || 
           status == BookingStatus.confirmed;
  }

  /// Check if a booking can be rated
  static bool canBeRated(BookingStatus status, double? existingRating) {
    return status == BookingStatus.completed && existingRating == null;
  }

  /// Get status badge widget
  static Widget getStatusBadge(BookingStatus status, {double fontSize = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getStatusColor(status),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(status),
            size: fontSize + 4,
            color: getStatusColor(status),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusDisplayName(status),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  static String _getStatusDisplayName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.driverAssigned:
        return 'Driver Assigned';
      case BookingStatus.driverEnRoute:
        return 'En Route';
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

  /// Convert BookingStatus enum to string for API
  static String statusToString(BookingStatus status) {
    return status.toString().split('.').last;
  }

  /// Parse string to BookingStatus enum
  static BookingStatus stringToStatus(String statusString) {
    return BookingStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusString,
      orElse: () => BookingStatus.pending,
    );
  }
}

