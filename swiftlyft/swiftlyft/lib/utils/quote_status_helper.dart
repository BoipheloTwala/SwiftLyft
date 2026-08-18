import 'package:flutter/material.dart';

/// Helper for managing quote statuses and their display
class QuoteStatusHelper {
  /// Get color for quote status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'quoted':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'expired':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for quote status
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'quoted':
        return Icons.receipt_long;
      case 'accepted':
        return Icons.check_circle;
      case 'expired':
        return Icons.event_busy;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Get display name for quote status
  static String getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'quoted':
        return 'Quoted';
      case 'accepted':
        return 'Accepted';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get description for quote status
  static String getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Waiting for quote from SwiftLyft';
      case 'quoted':
        return 'Quote ready for your review';
      case 'accepted':
        return 'Quote accepted, booking in progress';
      case 'expired':
        return 'Quote has expired';
      case 'cancelled':
        return 'Quote cancelled';
      default:
        return 'Unknown status';
    }
  }

  /// Check if quote can be accepted
  static bool canAccept(String status) {
    return status.toLowerCase() == 'quoted';
  }

  /// Check if quote can be cancelled
  static bool canCancel(String status) {
    return status.toLowerCase() == 'pending' || status.toLowerCase() == 'quoted';
  }

  /// Check if quote is actionable
  static bool isActionable(String status) {
    return canAccept(status) || canCancel(status);
  }

  /// Check if quote is expired
  static bool isExpired(DateTime? validUntil) {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil);
  }

  /// Get time remaining string
  static String getTimeRemaining(DateTime? validUntil) {
    if (validUntil == null) return 'No expiration';
    
    final now = DateTime.now();
    if (now.isAfter(validUntil)) return 'Expired';
    
    final difference = validUntil.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} remaining';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} remaining';
    } else {
      return 'Expires soon';
    }
  }

  /// Get all valid statuses
  static List<String> getValidStatuses() {
    return ['pending', 'quoted', 'accepted', 'expired', 'cancelled'];
  }

  /// Validate status transition (from user perspective)
  static bool canUserTransitionTo(String fromStatus, String toStatus) {
    // Users can only cancel quotes
    if (toStatus.toLowerCase() == 'cancelled') {
      return fromStatus.toLowerCase() == 'pending' || 
             fromStatus.toLowerCase() == 'quoted';
    }
    return false;
  }
}

