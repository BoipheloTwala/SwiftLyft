import 'package:flutter/foundation.dart';
import 'quote_api_service.dart';

/// Service for managing quote price estimations with caching
class QuoteEstimationService {
  static final QuoteEstimationService _instance = QuoteEstimationService._internal();
  factory QuoteEstimationService() => _instance;
  
  final QuoteService _quoteService = QuoteService();
  
  // Cache for price estimates
  final Map<String, _CachedEstimate> _estimateCache = {};
  
  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  QuoteEstimationService._internal();
  
  /// Get price estimate with caching
  Future<Map<String, dynamic>> getEstimate({
    required Map<String, double> pickupCoordinates,
    required Map<String, double> dropoffCoordinates,
    required String vehicleType,
    required String serviceType,
    int passengerCount = 1,
    bool forceRefresh = false,
  }) async {
    try {
      // Generate cache key
      final cacheKey = _generateCacheKey(
        pickupCoordinates,
        dropoffCoordinates,
        vehicleType,
        serviceType,
        passengerCount,
      );
      
      // Check cache if not forcing refresh
      if (!forceRefresh && _estimateCache.containsKey(cacheKey)) {
        final cached = _estimateCache[cacheKey]!;
        if (!cached.isExpired) {
          debugPrint('💾 Using cached price estimate');
          return cached.data;
        }
      }
      
      // Validate inputs
      _validateCoordinates(pickupCoordinates, 'pickup');
      _validateCoordinates(dropoffCoordinates, 'dropoff');
      _validateVehicleType(vehicleType);
      _validateServiceType(serviceType);
      _validatePassengerCount(passengerCount);
      
      debugPrint('🔍 Fetching fresh price estimate');
      
      // Fetch from API
      final estimate = await _quoteService.getPriceEstimate(
        pickupCoordinates: pickupCoordinates,
        dropoffCoordinates: dropoffCoordinates,
        vehicleType: vehicleType,
        serviceType: serviceType,
        passengerCount: passengerCount,
      );
      
      // Cache the result
      _estimateCache[cacheKey] = _CachedEstimate(
        data: estimate,
        timestamp: DateTime.now(),
      );
      
      return estimate;
    } on ValidationException catch (e) {
      debugPrint('⚠️ Validation error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Failed to get estimate: $e');
      throw EstimationException('Failed to calculate price estimate: ${e.toString()}');
    }
  }
  
  /// Compare prices across different vehicle types
  Future<Map<String, Map<String, dynamic>>> compareVehicleTypes({
    required Map<String, double> pickupCoordinates,
    required Map<String, double> dropoffCoordinates,
    required String serviceType,
    int passengerCount = 1,
    List<String>? vehicleTypes,
  }) async {
    final types = vehicleTypes ?? ['sedan', 'suv', 'luxury', 'van'];
    final results = <String, Map<String, dynamic>>{};
    
    for (final vehicleType in types) {
      try {
        final estimate = await getEstimate(
          pickupCoordinates: pickupCoordinates,
          dropoffCoordinates: dropoffCoordinates,
          vehicleType: vehicleType,
          serviceType: serviceType,
          passengerCount: passengerCount,
        );
        results[vehicleType] = estimate;
      } catch (e) {
        debugPrint('❌ Failed to get estimate for $vehicleType: $e');
        // Continue with other vehicle types
      }
    }
    
    return results;
  }
  
  /// Compare prices across different service types
  Future<Map<String, Map<String, dynamic>>> compareServiceTypes({
    required Map<String, double> pickupCoordinates,
    required Map<String, double> dropoffCoordinates,
    required String vehicleType,
    int passengerCount = 1,
    List<String>? serviceTypes,
  }) async {
    final types = serviceTypes ?? ['standard', 'premium', 'corporate', 'airport'];
    final results = <String, Map<String, dynamic>>{};
    
    for (final serviceType in types) {
      try {
        final estimate = await getEstimate(
          pickupCoordinates: pickupCoordinates,
          dropoffCoordinates: dropoffCoordinates,
          vehicleType: vehicleType,
          serviceType: serviceType,
          passengerCount: passengerCount,
        );
        results[serviceType] = estimate;
      } catch (e) {
        debugPrint('❌ Failed to get estimate for $serviceType: $e');
        // Continue with other service types
      }
    }
    
    return results;
  }
  
  /// Clear all cached estimates
  void clearCache() {
    _estimateCache.clear();
    debugPrint('🗑️ Estimate cache cleared');
  }
  
  /// Clear expired cache entries
  void cleanExpiredCache() {
    _estimateCache.removeWhere((key, value) => value.isExpired);
    debugPrint('🧹 Expired estimates removed from cache');
  }
  
  // Private helper methods
  
  String _generateCacheKey(
    Map<String, double> pickup,
    Map<String, double> dropoff,
    String vehicleType,
    String serviceType,
    int passengerCount,
  ) {
    return '${pickup['latitude']}_${pickup['longitude']}_'
           '${dropoff['latitude']}_${dropoff['longitude']}_'
           '${vehicleType}_${serviceType}_$passengerCount';
  }
  
  void _validateCoordinates(Map<String, double> coords, String type) {
    if (!coords.containsKey('latitude') || !coords.containsKey('longitude')) {
      throw ValidationException('$type coordinates must contain latitude and longitude');
    }
    
    final lat = coords['latitude']!;
    final lng = coords['longitude']!;
    
    if (lat < -90 || lat > 90) {
      throw ValidationException('Invalid $type latitude: $lat');
    }
    
    if (lng < -180 || lng > 180) {
      throw ValidationException('Invalid $type longitude: $lng');
    }
  }
  
  void _validateVehicleType(String vehicleType) {
    const validTypes = ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle'];
    if (!validTypes.contains(vehicleType.toLowerCase())) {
      throw ValidationException('Invalid vehicle type: $vehicleType. Must be one of: ${validTypes.join(", ")}');
    }
  }
  
  void _validateServiceType(String serviceType) {
    const validTypes = ['standard', 'premium', 'corporate', 'airport', 'security'];
    if (!validTypes.contains(serviceType.toLowerCase())) {
      throw ValidationException('Invalid service type: $serviceType. Must be one of: ${validTypes.join(", ")}');
    }
  }
  
  void _validatePassengerCount(int count) {
    if (count < 1 || count > 20) {
      throw ValidationException('Passenger count must be between 1 and 20');
    }
  }
}

/// Cached estimate data
class _CachedEstimate {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  _CachedEstimate({
    required this.data,
    required this.timestamp,
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp) > QuoteEstimationService._cacheDuration;
  }
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

/// Custom exception for estimation errors
class EstimationException implements Exception {
  final String message;
  
  EstimationException(this.message);
  
  @override
  String toString() => 'EstimationException: $message';
}

