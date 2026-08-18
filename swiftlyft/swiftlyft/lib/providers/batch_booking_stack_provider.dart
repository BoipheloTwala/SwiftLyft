import 'package:flutter/material.dart';
import '../models/batch_booking_stack_item.dart';
import '../models/vehicle.dart';

/// Provider for managing batch booking stack (LIFO) for corporate users
/// Corporate users can add vehicles to a stack and create batch bookings from them
class BatchBookingStackProvider extends ChangeNotifier {
  final List<BatchBookingStackItem> _stack = [];

  List<BatchBookingStackItem> get stack => List.unmodifiable(_stack);
  int get count => _stack.length;
  bool get isEmpty => _stack.isEmpty;

  /// Add vehicle to top of stack (LIFO - push operation)
  void addVehicle(Vehicle vehicle) {
    // Check if vehicle already exists in stack
    if (_stack.any((item) => item.vehicleId == vehicle.id)) {
      // Remove existing instance (if any)
      _stack.removeWhere((item) => item.vehicleId == vehicle.id);
    }
    // Add to top of stack (LIFO)
    _stack.add(BatchBookingStackItem.fromVehicle(vehicle));
    notifyListeners();
  }

  /// Remove vehicle from stack
  void removeFromStack(String vehicleId) {
    _stack.removeWhere((item) => item.vehicleId == vehicleId);
    notifyListeners();
  }

  /// Clear entire stack
  void clearStack() {
    _stack.clear();
    notifyListeners();
  }

  /// Check if vehicle is in stack
  bool contains(String vehicleId) {
    return _stack.any((item) => item.vehicleId == vehicleId);
  }

  /// Get top item (most recently added - LIFO)
  BatchBookingStackItem? get top => _stack.isEmpty ? null : _stack.last;

  /// Pop top item from stack (LIFO - remove most recently added)
  BatchBookingStackItem? pop() {
    if (_stack.isEmpty) return null;
    final item = _stack.removeLast();
    notifyListeners();
    return item;
  }

  /// Pop multiple items from top of stack
  List<BatchBookingStackItem> popMultiple(int count) {
    final items = <BatchBookingStackItem>[];
    for (int i = 0; i < count && _stack.isNotEmpty; i++) {
      items.add(_stack.removeLast());
    }
    notifyListeners();
    return items;
  }

  /// Get total estimated price for all items in stack
  double get totalEstimatedPrice {
    return _stack.fold(0.0, (sum, item) => sum + item.displayPrice);
  }

  /// Get items grouped by vehicle type/category
  Map<String, List<BatchBookingStackItem>> getItemsByCategory() {
    final grouped = <String, List<BatchBookingStackItem>>{};
    for (final item in _stack) {
      if (!grouped.containsKey(item.vehicleCategory)) {
        grouped[item.vehicleCategory] = [];
      }
      grouped[item.vehicleCategory]!.add(item);
    }
    return grouped;
  }
}

