import 'package:flutter/foundation.dart';

/// Helper for calculating and displaying quote pricing
class QuotePricingHelper {
  // Note: For price estimation, use QuoteEstimationService instead
  // This class now only contains formatting and mapping utilities

  /// Map frontend vehicle category to backend vehicle type
  static String mapVehicleType(String vehicleName) {
    final name = vehicleName.toLowerCase();
    
    if (name.contains('luxury')) return 'luxury';
    if (name.contains('suv')) return 'suv';
    if (name.contains('van')) return 'van';
    if (name.contains('truck')) return 'truck';
    if (name.contains('motorcycle') || name.contains('bike')) return 'motorcycle';
    
    return 'sedan'; // Default
  }

  /// Map service features to backend service type
  static String mapServiceType({
    bool isPremium = false,
    bool isCorporate = false,
    bool isAirport = false,
    bool isSecurity = false,
  }) {
    if (isSecurity) return 'security';
    if (isAirport) return 'airport';
    if (isCorporate) return 'corporate';
    if (isPremium) return 'premium';
    
    return 'standard';
  }

  /// Format currency (South African Rand)
  static String formatCurrency(double amount) {
    return 'R${amount.toStringAsFixed(2)}';
  }

  /// Format distance
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  /// Format duration
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }

  /// Calculate estimated coordinates from address (mock implementation)
  /// In production, this should use Google Geocoding API
  static Map<String, double> getMockCoordinates(String address) {
    // Mock coordinates for Johannesburg area
    // In production, replace with actual geocoding
    final hash = address.hashCode.abs();
    final lat = -26.2041 + (hash % 100) / 1000.0; // Range: -26.2041 to -26.1041
    final lng = 28.0473 + (hash % 100) / 1000.0;  // Range: 28.0473 to 28.1473
    
    return {
      'latitude': lat,
      'longitude': lng,
    };
  }

  /// Validate pricing data
  static bool isValidPricing(Map<String, dynamic>? pricing) {
    if (pricing == null) return false;
    
    final total = pricing['total'];
    if (total == null) return false;
    
    return total is num && total > 0;
  }

  /// Get pricing breakdown for display
  static List<Map<String, dynamic>> getPricingBreakdown(Map<String, dynamic> pricing) {
    final breakdown = <Map<String, dynamic>>[];
    
    if (pricing['baseFare'] != null) {
      breakdown.add({
        'label': 'Base Fare',
        'amount': pricing['baseFare'],
        'type': 'base',
      });
    }
    
    if (pricing['distanceFare'] != null && pricing['distanceFare'] > 0) {
      breakdown.add({
        'label': 'Distance Charge',
        'amount': pricing['distanceFare'],
        'type': 'distance',
      });
    }
    
    if (pricing['timeFare'] != null && pricing['timeFare'] > 0) {
      breakdown.add({
        'label': 'Time Charge',
        'amount': pricing['timeFare'],
        'type': 'time',
      });
    }
    
    if (pricing['serviceFee'] != null && pricing['serviceFee'] > 0) {
      breakdown.add({
        'label': 'Service Fee',
        'amount': pricing['serviceFee'],
        'type': 'fee',
      });
    }
    
    if (pricing['taxes'] != null && pricing['taxes'] > 0) {
      breakdown.add({
        'label': 'Taxes (15%)',
        'amount': pricing['taxes'],
        'type': 'tax',
      });
    }
    
    return breakdown;
  }

  /// Adjust backend pricing to luxury service pricing (frontend-only)
  /// This applies multipliers to make prices realistic for a premium chauffeur service
  /// Backend data remains unchanged - this is for display only
  static Map<String, dynamic> adjustToLuxuryPricing(
    Map<String, dynamic> backendPricing,
    String vehicleType,
  ) {
    final adjusted = Map<String, dynamic>.from(backendPricing);
    
    // Vehicle type multipliers (same as in Vehicle model)
    final multipliers = {
      'sedan': 3.5,
      'suv': 4.0,
      'luxury': 5.0,
      'van': 4.5,
      'truck': 4.5,
      'hybrid': 4.0,
    };
    
    final vehicleMultiplier = multipliers[vehicleType.toLowerCase()] ?? 4.0;
    
    // Adjust base fare (apply vehicle multiplier)
    if (adjusted['baseFare'] != null) {
      final baseFare = (adjusted['baseFare'] as num).toDouble();
      adjusted['baseFare'] = (baseFare * vehicleMultiplier).roundToDouble();
    }
    
    // Adjust distance fare (backend: ~R1.50/km, frontend: R35-R55/km)
    // Apply multiplier of ~2.5-3.5x depending on base fare
    if (adjusted['distanceFare'] != null) {
      final distanceFare = (adjusted['distanceFare'] as num).toDouble();
      // Higher multiplier for distance to reach luxury rates
      final distanceMultiplier = 2.8 + (vehicleMultiplier - 3.5) * 0.3; // 2.8 to 3.3
      adjusted['distanceFare'] = (distanceFare * distanceMultiplier).roundToDouble();
    }
    
    // Adjust time fare (backend: ~R40/hour, frontend: R280-R450/hour)
    // Apply multiplier of ~7-8x
    if (adjusted['timeFare'] != null) {
      final timeFare = (adjusted['timeFare'] as num).toDouble();
      final timeMultiplier = 7.0 + (vehicleMultiplier - 3.5) * 0.5; // 7.0 to 8.25
      adjusted['timeFare'] = (timeFare * timeMultiplier).roundToDouble();
    }
    
    // Adjust service fee (backend: ~10% of base, frontend: R50-R120)
    // Apply multiplier of ~6-8x
    if (adjusted['serviceFee'] != null) {
      final serviceFee = (adjusted['serviceFee'] as num).toDouble();
      final serviceMultiplier = 6.0 + (vehicleMultiplier - 3.5) * 0.8; // 6.0 to 8.2
      adjusted['serviceFee'] = (serviceFee * serviceMultiplier).roundToDouble();
    }
    
    // Recalculate subtotal
    final subtotal = (adjusted['baseFare'] ?? 0.0) +
                     (adjusted['distanceFare'] ?? 0.0) +
                     (adjusted['timeFare'] ?? 0.0) +
                     (adjusted['serviceFee'] ?? 0.0);
    
    // Recalculate taxes (15% VAT)
    final taxes = (subtotal * 0.15).roundToDouble();
    adjusted['taxes'] = taxes;
    
    // Recalculate total
    final total = (subtotal + taxes).roundToDouble();
    adjusted['total'] = total;
    
    // Ensure minimum price of R2500 for luxury service
    if (total < 2500.0) {
      final shortfall = 2500.0 - total;
      // Distribute shortfall proportionally
      final currentBase = (adjusted['baseFare'] ?? 0.0).toDouble();
      final currentDistance = (adjusted['distanceFare'] ?? 0.0).toDouble();
      final currentTime = (adjusted['timeFare'] ?? 0.0).toDouble();
      
      adjusted['baseFare'] = (currentBase + (shortfall * 0.5)).roundToDouble();
      adjusted['distanceFare'] = (currentDistance + (shortfall * 0.3)).roundToDouble();
      adjusted['timeFare'] = (currentTime + (shortfall * 0.2)).roundToDouble();
      
      // Recalculate with adjusted values
      final newSubtotal = (adjusted['baseFare'] ?? 0.0) +
                          (adjusted['distanceFare'] ?? 0.0) +
                          (adjusted['timeFare'] ?? 0.0) +
                          (adjusted['serviceFee'] ?? 0.0);
      adjusted['taxes'] = (newSubtotal * 0.15).roundToDouble();
      adjusted['total'] = (newSubtotal + adjusted['taxes']).roundToDouble();
    }
    
    return adjusted;
  }
}

