import '../models/booking.dart';

/// Helper class for booking cancellation and fee calculation
class CancellationHelper {
  /// Calculate cancellation fee based on timing
  static Map<String, dynamic> calculateCancellationFee(Booking booking) {
    final now = DateTime.now();
    final scheduledTime = booking.pickupTime;
    final timeDifference = scheduledTime.difference(now);
    final hoursUntilTrip = timeDifference.inMinutes / 60.0;
    
    double feePercentage = 0.0;
    double feeAmount = 0.0;
    String feeDescription = '';
    
    if (hoursUntilTrip < 2) {
      feePercentage = 0.5;
      feeAmount = booking.finalPrice * 0.5;
      feeDescription = 'Cancelling less than 2 hours before pickup';
    } else if (hoursUntilTrip < 24) {
      feePercentage = 0.25;
      feeAmount = booking.finalPrice * 0.25;
      feeDescription = 'Cancelling less than 24 hours before pickup';
    } else {
      feePercentage = 0.0;
      feeAmount = 0.0;
      feeDescription = 'Free cancellation (more than 24 hours before pickup)';
    }
    
    return {
      'feePercentage': feePercentage,
      'feeAmount': feeAmount,
      'feeDescription': feeDescription,
      'hoursUntilTrip': hoursUntilTrip,
      'refundAmount': booking.finalPrice - feeAmount,
    };
  }
  
  /// Check if booking can be cancelled
  static bool canCancelBooking(Booking booking) {
    // Can't cancel if already completed or cancelled
    if (booking.status == BookingStatus.completed || 
        booking.status == BookingStatus.cancelled) {
      return false;
    }
    
    // Can't cancel if trip is in progress
    if (booking.status == BookingStatus.inProgress) {
      return false;
    }
    
    return true;
  }
  
  /// Get cancellation policy text
  static String getCancellationPolicy() {
    return '''
Cancellation Policy:
• More than 24 hours before pickup: Free cancellation
• 2-24 hours before pickup: 25% cancellation fee
• Less than 2 hours before pickup: 50% cancellation fee
• During trip: Cancellation not allowed

Refunds will be processed within 5-7 business days.
''';
  }
  
  /// Get time until trip in human-readable format
  static String getTimeUntilTrip(DateTime pickupTime) {
    final now = DateTime.now();
    final difference = pickupTime.difference(now);
    
    if (difference.isNegative) {
      return 'Trip time has passed';
    }
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours >= 24) {
      final days = (hours / 24).floor();
      return '$days day${days > 1 ? 's' : ''} ${hours % 24}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

