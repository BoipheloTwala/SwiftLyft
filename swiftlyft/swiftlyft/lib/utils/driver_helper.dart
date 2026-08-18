import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/booking.dart';
import 'theme.dart';

/// Helper class for driver management and assignment
class DriverHelper {
  /// Check if a driver can be assigned to a booking
  static bool canAssignDriver(Booking booking) {
    // Can only assign drivers to pending or confirmed bookings
    return booking.status == BookingStatus.pending ||
           booking.status == BookingStatus.confirmed;
  }

  /// Check if a driver is available for assignment
  static bool isDriverAvailable(Driver driver) {
    return driver.isAvailable && 
           driver.isOnline && 
           driver.status == DriverStatus.online;
  }

  /// Get status color for driver
  static Color getDriverStatusColor(DriverStatus status) {
    switch (status) {
      case DriverStatus.online:
        return Colors.green;
      case DriverStatus.offline:
        return Colors.grey;
      case DriverStatus.onTrip:
        return SwiftLyftTheme.primaryBlue;
      case DriverStatus.busy:
        return Colors.orange;
      case DriverStatus.offline:
        return Colors.red;
    }
  }

  /// Get status icon for driver
  static IconData getDriverStatusIcon(DriverStatus status) {
    switch (status) {
      case DriverStatus.online:
        return Icons.check_circle;
      case DriverStatus.offline:
        return Icons.offline_bolt;
      case DriverStatus.onTrip:
        return Icons.local_taxi;
      case DriverStatus.busy:
        return Icons.timer;
      case DriverStatus.offline:
        return Icons.block;
    }
  }

  /// Get status text for driver
  static String getDriverStatusText(DriverStatus status) {
    switch (status) {
      case DriverStatus.online:
        return 'Available';
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.onTrip:
        return 'On Trip';
      case DriverStatus.busy:
        return 'Busy';
      case DriverStatus.offline:
        return 'Inactive';
    }
  }

  /// Get driver rating badge
  static Widget getRatingBadge(double rating, {int totalTrips = 0}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRatingColor(rating).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRatingColor(rating),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 14,
            color: _getRatingColor(rating),
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getRatingColor(rating),
            ),
          ),
          if (totalTrips > 0) ...[
            Text(
              ' ($totalTrips)',
              style: TextStyle(
                fontSize: 11,
                color: SwiftLyftTheme.mediumGray,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.blue;
    if (rating >= 3.5) return Colors.orange;
    return Colors.red;
  }

  /// Get driver status badge
  static Widget getStatusBadge(DriverStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: getDriverStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getDriverStatusColor(status),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getDriverStatusIcon(status),
            size: 14,
            color: getDriverStatusColor(status),
          ),
          const SizedBox(width: 6),
          Text(
            getDriverStatusText(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: getDriverStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  /// Filter available drivers
  static List<Driver> filterAvailableDrivers(List<Driver> drivers) {
    return drivers.where((driver) => isDriverAvailable(driver)).toList();
  }

  /// Sort drivers by rating
  static List<Driver> sortByRating(List<Driver> drivers, {bool descending = true}) {
    final sortedDrivers = List<Driver>.from(drivers);
    sortedDrivers.sort((a, b) {
      final comparison = a.rating.compareTo(b.rating);
      return descending ? -comparison : comparison;
    });
    return sortedDrivers;
  }

  /// Sort drivers by proximity (placeholder - would use actual location)
  static List<Driver> sortByProximity(
    List<Driver> drivers,
    double pickupLat,
    double pickupLng,
  ) {
    // For now, return as-is
    // In production, calculate distance from driver's current location
    return drivers;
  }

  /// Get driver performance indicator
  static Widget getPerformanceIndicator(Map<String, dynamic>? performance) {
    if (performance == null) {
      return const SizedBox.shrink();
    }

    final completionRate = (performance['completion'] as num?)?.toDouble() ?? 0.0;
    final color = completionRate >= 0.95
        ? Colors.green
        : completionRate >= 0.85
            ? Colors.orange
            : Colors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trending_up, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '${(completionRate * 100).toInt()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Validate driver assignment
  static String? validateDriverAssignment(Booking booking, Driver driver) {
    // Check if booking can have driver assigned
    if (!canAssignDriver(booking)) {
      return 'Cannot assign driver to ${booking.statusText} booking';
    }

    // Check if driver is available
    if (!isDriverAvailable(driver)) {
      return 'Driver is not available (${getDriverStatusText(driver.status)})';
    }

    // Check if driver is already assigned
    if (booking.driverId.isNotEmpty && booking.driverId == driver.id) {
      return 'This driver is already assigned to this booking';
    }

    return null; // Valid assignment
  }

  /// Get recommendation score for driver
  static double getRecommendationScore(Driver driver, Booking booking) {
    double score = 0.0;

    // Rating contribution (0-40 points)
    score += (driver.rating / 5.0) * 40;

    // Experience contribution (0-20 points)
    final experienceScore = (driver.totalTrips / 1000).clamp(0.0, 1.0);
    score += experienceScore * 20;

    // Performance contribution (0-20 points)
    final completionRate = (driver.performance?['completion'] as num?)?.toDouble() ?? 0.8;
    score += completionRate * 20;

    // Availability contribution (0-20 points)
    if (driver.isAvailable && driver.isOnline) {
      score += 20;
    } else if (driver.isOnline) {
      score += 10;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Get recommended drivers (top N by score)
  static List<Driver> getRecommendedDrivers(
    List<Driver> drivers,
    Booking booking, {
    int limit = 5,
  }) {
    final availableDrivers = filterAvailableDrivers(drivers);
    
    // Score and sort
    final scoredDrivers = availableDrivers.map((driver) {
      return {
        'driver': driver,
        'score': getRecommendationScore(driver, booking),
      };
    }).toList();

    scoredDrivers.sort((a, b) {
      final scoreA = a['score'] as double;
      final scoreB = b['score'] as double;
      return scoreB.compareTo(scoreA);
    });

    return scoredDrivers
        .take(limit)
        .map((item) => item['driver'] as Driver)
        .toList();
  }
}

