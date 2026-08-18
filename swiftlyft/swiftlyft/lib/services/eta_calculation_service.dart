import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/coordinates.dart';

/// Service for calculating and managing ETA (Estimated Time of Arrival)
class ETACalculationService {
  static final ETACalculationService _instance = ETACalculationService._internal();
  factory ETACalculationService() => _instance;

  // Historical data for accuracy improvements
  final List<ETAAccuracyData> _accuracyHistory = [];
  
  // Average speed data by time of day
  final Map<int, double> _averageSpeedByHour = {};
  
  // Traffic multipliers (1.0 = no traffic, 2.0 = double time)
  static const Map<String, double> _trafficMultipliers = {
    'none': 1.0,
    'light': 1.15,
    'moderate': 1.35,
    'heavy': 1.65,
    'severe': 2.0,
  };

  ETACalculationService._internal();

  /// Calculate ETA with multiple factors
  ETAResult calculateETA({
    required LatLng from,
    required LatLng to,
    double? currentSpeed,
    String trafficCondition = 'none',
    DateTime? time,
  }) {
    try {
      // Calculate distance
      final distance = calculateDistance(from, to);
      
      // Determine average speed
      final avgSpeed = _determineAverageSpeed(
        currentSpeed: currentSpeed,
        time: time ?? DateTime.now(),
        trafficCondition: trafficCondition,
      );
      
      // Calculate base ETA
      final baseEtaMinutes = (distance / avgSpeed * 60).round();
      
      // Apply traffic multiplier
      final trafficMultiplier = _trafficMultipliers[trafficCondition] ?? 1.0;
      final adjustedEtaMinutes = (baseEtaMinutes * trafficMultiplier).round();
      
      // Calculate confidence interval
      final confidence = _calculateConfidence(
        distance: distance,
        speed: avgSpeed,
        trafficCondition: trafficCondition,
      );
      
      // Calculate range
      final minEta = (adjustedEtaMinutes * (1 - confidence.errorMargin / 100)).round();
      final maxEta = (adjustedEtaMinutes * (1 + confidence.errorMargin / 100)).round();
      
      debugPrint('🎯 ETA calculated: $adjustedEtaMinutes min (${minEta}-${maxEta} min range)');
      
      return ETAResult(
        etaMinutes: adjustedEtaMinutes,
        minEtaMinutes: minEta,
        maxEtaMinutes: maxEta,
        distance: distance,
        averageSpeed: avgSpeed,
        trafficCondition: trafficCondition,
        confidence: confidence,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error calculating ETA: $e');
      return ETAResult(
        etaMinutes: 0,
        minEtaMinutes: 0,
        maxEtaMinutes: 0,
        distance: 0,
        averageSpeed: 0,
        trafficCondition: 'unknown',
        confidence: ETAConfidence(level: 'low', percentage: 0, errorMargin: 50),
        calculatedAt: DateTime.now(),
      );
    }
  }

  /// Calculate distance using Haversine formula (in km)
  double calculateDistance(LatLng from, LatLng to) {
    const earthRadius = 6371.0; // km
    
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final deltaLat = _toRadians(to.latitude - from.latitude);
    final deltaLon = _toRadians(to.longitude - from.longitude);
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) *
        sin(deltaLon / 2) * sin(deltaLon / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Determine average speed based on multiple factors
  double _determineAverageSpeed({
    double? currentSpeed,
    required DateTime time,
    required String trafficCondition,
  }) {
    // If current speed is available and reasonable, use it
    if (currentSpeed != null && currentSpeed > 0 && currentSpeed < 150) {
      return currentSpeed;
    }
    
    // Use historical average for time of day
    final hour = time.hour;
    if (_averageSpeedByHour.containsKey(hour)) {
      return _averageSpeedByHour[hour]!;
    }
    
    // Default speeds based on time of day and traffic
    return _getDefaultSpeed(hour, trafficCondition);
  }

  /// Get default speed based on time and traffic
  double _getDefaultSpeed(int hour, String trafficCondition) {
    // Base speed for different times of day (km/h)
    double baseSpeed;
    
    if (hour >= 7 && hour <= 9) {
      // Morning rush hour
      baseSpeed = 25.0;
    } else if (hour >= 17 && hour <= 19) {
      // Evening rush hour
      baseSpeed = 28.0;
    } else if (hour >= 22 || hour <= 5) {
      // Night time
      baseSpeed = 55.0;
    } else {
      // Regular hours
      baseSpeed = 40.0;
    }
    
    // Adjust for traffic
    final trafficMultiplier = _trafficMultipliers[trafficCondition] ?? 1.0;
    return baseSpeed / trafficMultiplier;
  }

  /// Calculate confidence level for ETA
  ETAConfidence _calculateConfidence({
    required double distance,
    required double speed,
    required String trafficCondition,
  }) {
    // Start with base confidence
    double confidence = 85.0;
    double errorMargin = 10.0;
    
    // Reduce confidence for longer distances
    if (distance > 50) {
      confidence -= 15;
      errorMargin += 10;
    } else if (distance > 20) {
      confidence -= 10;
      errorMargin += 5;
    } else if (distance > 10) {
      confidence -= 5;
      errorMargin += 3;
    }
    
    // Reduce confidence for worse traffic
    if (trafficCondition == 'severe') {
      confidence -= 20;
      errorMargin += 15;
    } else if (trafficCondition == 'heavy') {
      confidence -= 15;
      errorMargin += 10;
    } else if (trafficCondition == 'moderate') {
      confidence -= 10;
      errorMargin += 5;
    }
    
    // Increase confidence if we have historical data
    if (_accuracyHistory.length > 10) {
      final avgAccuracy = _calculateAverageAccuracy();
      confidence += (avgAccuracy * 10);
      errorMargin -= (avgAccuracy * 5);
    }
    
    // Clamp values
    confidence = confidence.clamp(0, 100);
    errorMargin = errorMargin.clamp(5, 50);
    
    // Determine confidence level
    String level;
    if (confidence >= 80) {
      level = 'high';
    } else if (confidence >= 60) {
      level = 'medium';
    } else {
      level = 'low';
    }
    
    return ETAConfidence(
      level: level,
      percentage: confidence.round(),
      errorMargin: errorMargin.round(),
    );
  }

  /// Calculate average accuracy from history
  double _calculateAverageAccuracy() {
    if (_accuracyHistory.isEmpty) return 0;
    
    final sum = _accuracyHistory.fold<double>(
      0,
      (sum, data) => sum + data.accuracy,
    );
    
    return sum / _accuracyHistory.length;
  }

  /// Record actual ETA for accuracy tracking
  void recordActualETA({
    required ETAResult predictedETA,
    required int actualMinutes,
  }) {
    final accuracy = 1 - ((predictedETA.etaMinutes - actualMinutes).abs() / predictedETA.etaMinutes);
    
    _accuracyHistory.add(ETAAccuracyData(
      predictedMinutes: predictedETA.etaMinutes,
      actualMinutes: actualMinutes,
      accuracy: accuracy.clamp(0, 1),
      timestamp: DateTime.now(),
    ));
    
    // Keep only last 100 records
    if (_accuracyHistory.length > 100) {
      _accuracyHistory.removeAt(0);
    }
    
    // Update average speeds by hour
    final hour = DateTime.now().hour;
    final distance = predictedETA.distance;
    final actualSpeed = distance / (actualMinutes / 60);
    
    if (_averageSpeedByHour.containsKey(hour)) {
      _averageSpeedByHour[hour] = (_averageSpeedByHour[hour]! + actualSpeed) / 2;
    } else {
      _averageSpeedByHour[hour] = actualSpeed;
    }
    
    debugPrint('📊 ETA accuracy recorded: ${(accuracy * 100).toStringAsFixed(1)}%');
  }

  /// Get ETA accuracy statistics
  ETAStatistics getStatistics() {
    if (_accuracyHistory.isEmpty) {
      return ETAStatistics(
        averageAccuracy: 0,
        totalPredictions: 0,
        highAccuracyCount: 0,
        mediumAccuracyCount: 0,
        lowAccuracyCount: 0,
      );
    }
    
    final avgAccuracy = _calculateAverageAccuracy();
    var high = 0;
    var medium = 0;
    var low = 0;
    
    for (final data in _accuracyHistory) {
      if (data.accuracy >= 0.9) {
        high++;
      } else if (data.accuracy >= 0.7) {
        medium++;
      } else {
        low++;
      }
    }
    
    return ETAStatistics(
      averageAccuracy: avgAccuracy,
      totalPredictions: _accuracyHistory.length,
      highAccuracyCount: high,
      mediumAccuracyCount: medium,
      lowAccuracyCount: low,
    );
  }

  /// Calculate time to arrival from distance and speed
  static int calculateTimeFromDistance(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return 0;
    return ((distanceKm / speedKmh) * 60).round();
  }

  /// Calculate remaining distance from ETA and speed
  static double calculateDistanceFromETA(int etaMinutes, double speedKmh) {
    return (etaMinutes / 60) * speedKmh;
  }

  /// Format ETA for display
  static String formatETA(int minutes) {
    if (minutes < 1) {
      return 'Arriving now';
    } else if (minutes == 1) {
      return '1 minute';
    } else if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours ${hours == 1 ? "hour" : "hours"}';
      }
      return '$hours ${hours == 1 ? "hour" : "hours"} $mins min';
    }
  }

  /// Format ETA range
  static String formatETARange(int minMinutes, int maxMinutes) {
    return '${formatETA(minMinutes)} - ${formatETA(maxMinutes)}';
  }

  /// Clear all historical data
  void clearHistory() {
    _accuracyHistory.clear();
    _averageSpeedByHour.clear();
    debugPrint('🗑️ ETA history cleared');
  }
}

/// ETA calculation result
class ETAResult {
  final int etaMinutes;
  final int minEtaMinutes;
  final int maxEtaMinutes;
  final double distance; // km
  final double averageSpeed; // km/h
  final String trafficCondition;
  final ETAConfidence confidence;
  final DateTime calculatedAt;

  ETAResult({
    required this.etaMinutes,
    required this.minEtaMinutes,
    required this.maxEtaMinutes,
    required this.distance,
    required this.averageSpeed,
    required this.trafficCondition,
    required this.confidence,
    required this.calculatedAt,
  });

  /// Get formatted ETA string
  String get formattedETA => ETACalculationService.formatETA(etaMinutes);

  /// Get formatted ETA range
  String get formattedRange => ETACalculationService.formatETARange(minEtaMinutes, maxEtaMinutes);

  /// Check if ETA is stale (older than 30 seconds)
  bool get isStale {
    return DateTime.now().difference(calculatedAt).inSeconds > 30;
  }

  /// Get arrival time
  DateTime get arrivalTime {
    return calculatedAt.add(Duration(minutes: etaMinutes));
  }

  Map<String, dynamic> toJson() {
    return {
      'etaMinutes': etaMinutes,
      'minEtaMinutes': minEtaMinutes,
      'maxEtaMinutes': maxEtaMinutes,
      'distance': distance,
      'averageSpeed': averageSpeed,
      'trafficCondition': trafficCondition,
      'confidence': {
        'level': confidence.level,
        'percentage': confidence.percentage,
        'errorMargin': confidence.errorMargin,
      },
      'calculatedAt': calculatedAt.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
    };
  }
}

/// ETA confidence level
class ETAConfidence {
  final String level; // 'high', 'medium', 'low'
  final int percentage; // 0-100
  final int errorMargin; // percentage

  ETAConfidence({
    required this.level,
    required this.percentage,
    required this.errorMargin,
  });

  /// Get color for confidence level
  String get color {
    switch (level) {
      case 'high':
        return 'green';
      case 'medium':
        return 'yellow';
      case 'low':
        return 'red';
      default:
        return 'grey';
    }
  }
}

/// Historical accuracy data
class ETAAccuracyData {
  final int predictedMinutes;
  final int actualMinutes;
  final double accuracy; // 0-1
  final DateTime timestamp;

  ETAAccuracyData({
    required this.predictedMinutes,
    required this.actualMinutes,
    required this.accuracy,
    required this.timestamp,
  });
}

/// ETA statistics
class ETAStatistics {
  final double averageAccuracy; // 0-1
  final int totalPredictions;
  final int highAccuracyCount; // >= 90%
  final int mediumAccuracyCount; // 70-89%
  final int lowAccuracyCount; // < 70%

  ETAStatistics({
    required this.averageAccuracy,
    required this.totalPredictions,
    required this.highAccuracyCount,
    required this.mediumAccuracyCount,
    required this.lowAccuracyCount,
  });

  /// Get accuracy percentage
  int get accuracyPercentage => (averageAccuracy * 100).round();

  /// Get high accuracy percentage
  double get highAccuracyPercentage {
    if (totalPredictions == 0) return 0;
    return (highAccuracyCount / totalPredictions) * 100;
  }
}

