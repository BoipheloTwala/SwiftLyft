import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/eta_calculation_service.dart';

/// State management for ETA calculations and updates
class ETAState extends ChangeNotifier {
  final ETACalculationService _etaService;
  
  // Current ETA data
  ETAResult? _currentETA;
  Timer? _updateTimer;
  
  // Trip data
  LatLng? _origin;
  LatLng? _destination;
  LatLng? _currentLocation;
  double? _currentSpeed;
  String _trafficCondition = 'none';
  
  // Update settings
  static const Duration _updateInterval = Duration(seconds: 10);
  bool _autoUpdateEnabled = false;
  
  // Loading and error states
  bool _isCalculating = false;
  String? _error;
  
  ETAState(this._etaService);

  // Getters
  ETAResult? get currentETA => _currentETA;
  bool get autoUpdateEnabled => _autoUpdateEnabled;
  bool get isCalculating => _isCalculating;
  String? get error => _error;
  int? get etaMinutes => _currentETA?.etaMinutes;
  String? get formattedETA => _currentETA?.formattedETA;
  DateTime? get arrivalTime => _currentETA?.arrivalTime;
  bool get hasValidETA => _currentETA != null && !_currentETA!.isStale;

  /// Set trip route
  void setRoute({
    required LatLng origin,
    required LatLng destination,
    String trafficCondition = 'none',
  }) {
    _origin = origin;
    _destination = destination;
    _trafficCondition = trafficCondition;
    
    debugPrint('📍 Route set: $origin -> $destination');
    
    // Calculate initial ETA
    calculateETA();
  }

  /// Update current location
  void updateLocation(LatLng location, {double? speed}) {
    _currentLocation = location;
    _currentSpeed = speed;
    
    // Recalculate ETA if auto-update is enabled
    if (_autoUpdateEnabled && _destination != null) {
      calculateETA();
    }
  }

  /// Update traffic condition
  void updateTrafficCondition(String condition) {
    if (_trafficCondition != condition) {
      _trafficCondition = condition;
      debugPrint('🚦 Traffic condition updated: $condition');
      
      // Recalculate ETA
      if (_origin != null && _destination != null) {
        calculateETA();
      }
    }
  }

  /// Calculate ETA
  Future<void> calculateETA() async {
    if (_isCalculating) return;
    
    // Use current location as origin if available
    final from = _currentLocation ?? _origin;
    
    if (from == null || _destination == null) {
      debugPrint('⚠️ Cannot calculate ETA: missing origin or destination');
      return;
    }
    
    _isCalculating = true;
    _clearError();
    notifyListeners();
    
    try {
      final result = _etaService.calculateETA(
        from: from,
        to: _destination!,
        currentSpeed: _currentSpeed,
        trafficCondition: _trafficCondition,
        time: DateTime.now(),
      );
      
      _currentETA = result;
      
      debugPrint('✅ ETA calculated: ${result.formattedETA}');
    } catch (e) {
      _setError('Failed to calculate ETA: $e');
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  /// Start automatic ETA updates
  void startAutoUpdate() {
    if (_autoUpdateEnabled) {
      debugPrint('⚠️ Auto-update already enabled');
      return;
    }
    
    debugPrint('🔄 Starting ETA auto-update');
    _autoUpdateEnabled = true;
    
    // Initial calculation
    calculateETA();
    
    // Set up periodic updates
    _updateTimer = Timer.periodic(_updateInterval, (_) {
      calculateETA();
    });
    
    notifyListeners();
  }

  /// Stop automatic ETA updates
  void stopAutoUpdate() {
    if (!_autoUpdateEnabled) return;
    
    debugPrint('🛑 Stopping ETA auto-update');
    _autoUpdateEnabled = false;
    
    _updateTimer?.cancel();
    _updateTimer = null;
    
    notifyListeners();
  }

  /// Record actual arrival for accuracy tracking
  void recordActualArrival(int actualMinutes) {
    if (_currentETA == null) return;
    
    _etaService.recordActualETA(
      predictedETA: _currentETA!,
      actualMinutes: actualMinutes,
    );
    
    debugPrint('📊 Actual arrival recorded for accuracy tracking');
  }

  /// Get ETA statistics
  ETAStatistics getStatistics() {
    return _etaService.getStatistics();
  }

  /// Check if ETA needs update (stale)
  bool needsUpdate() {
    return _currentETA == null || _currentETA!.isStale;
  }

  /// Get time until arrival
  Duration? getTimeUntilArrival() {
    if (_currentETA == null) return null;
    return _currentETA!.arrivalTime.difference(DateTime.now());
  }

  /// Get remaining distance
  double? getRemainingDistance() {
    if (_currentLocation == null || _destination == null) return null;
    
    return _etaService.calculateDistance(
      _currentLocation!,
      _destination!,
    );
  }

  /// Get progress percentage (0-100)
  double? getProgressPercentage() {
    if (_origin == null || _destination == null || _currentLocation == null) {
      return null;
    }
    
    final totalDistance = _etaService.calculateDistance(_origin!, _destination!);
    final remaining = _etaService.calculateDistance(_currentLocation!, _destination!);
    
    if (totalDistance == 0) return 100.0;
    
    final progress = ((totalDistance - remaining) / totalDistance * 100).clamp(0.0, 100.0);
    return progress.toDouble();
  }

  /// Check if close to destination (within 100m)
  bool isCloseToDestination() {
    if (_currentLocation == null || _destination == null) return false;
    
    final distance = _etaService.calculateDistance(
      _currentLocation!,
      _destination!,
    );
    
    return distance < 0.1; // 100 meters
  }

  /// Reset ETA state
  void reset() {
    stopAutoUpdate();
    _currentETA = null;
    _origin = null;
    _destination = null;
    _currentLocation = null;
    _currentSpeed = null;
    _trafficCondition = 'none';
    _clearError();
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    debugPrint('❌ $error');
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    stopAutoUpdate();
    super.dispose();
  }
}

