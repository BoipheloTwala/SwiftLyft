import 'package:flutter/material.dart';
import '../services/quote_estimation_service.dart';
import '../utils/quote_pricing_helper.dart';
import 'quote_pricing_card.dart';

/// Widget for getting quick price estimates
class QuickEstimateWidget extends StatefulWidget {
  final Map<String, double>? pickupCoordinates;
  final Map<String, double>? dropoffCoordinates;
  final String vehicleType;
  final String serviceType;
  final int passengerCount;
  final bool autoFetch;
  final Function(Map<String, dynamic>)? onEstimateReceived;

  const QuickEstimateWidget({
    super.key,
    this.pickupCoordinates,
    this.dropoffCoordinates,
    this.vehicleType = 'sedan',
    this.serviceType = 'standard',
    this.passengerCount = 1,
    this.autoFetch = true,
    this.onEstimateReceived,
  });

  @override
  State<QuickEstimateWidget> createState() => _QuickEstimateWidgetState();
}

class _QuickEstimateWidgetState extends State<QuickEstimateWidget> {
  final QuoteEstimationService _estimationService = QuoteEstimationService();
  
  Map<String, dynamic>? _estimate;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.autoFetch && _canFetchEstimate()) {
      _fetchEstimate();
    }
  }

  @override
  void didUpdateWidget(QuickEstimateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refetch if relevant parameters changed
    if (widget.autoFetch &&
        (widget.pickupCoordinates != oldWidget.pickupCoordinates ||
         widget.dropoffCoordinates != oldWidget.dropoffCoordinates ||
         widget.vehicleType != oldWidget.vehicleType ||
         widget.serviceType != oldWidget.serviceType ||
         widget.passengerCount != oldWidget.passengerCount)) {
      if (_canFetchEstimate()) {
        _fetchEstimate();
      }
    }
  }

  bool _canFetchEstimate() {
    return widget.pickupCoordinates != null && widget.dropoffCoordinates != null;
  }

  Future<void> _fetchEstimate({bool forceRefresh = false}) async {
    if (!_canFetchEstimate()) {
      setState(() {
        _error = 'Please provide pickup and dropoff locations';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final estimate = await _estimationService.getEstimate(
        pickupCoordinates: widget.pickupCoordinates!,
        dropoffCoordinates: widget.dropoffCoordinates!,
        vehicleType: widget.vehicleType,
        serviceType: widget.serviceType,
        passengerCount: widget.passengerCount,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _estimate = estimate;
          _isLoading = false;
        });

        widget.onEstimateReceived?.call(estimate);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } on EstimationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to get estimate: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuotePricingCard(
      pricingData: _estimate?['pricing'],
      distance: _estimate?['distance']?.toDouble(),
      duration: _estimate?['duration']?.toInt(),
      isLoading: _isLoading,
      error: _error,
    );
  }
}

/// Compact estimate display widget
class CompactEstimateWidget extends StatefulWidget {
  final Map<String, double> pickupCoordinates;
  final Map<String, double> dropoffCoordinates;
  final String vehicleType;
  final String serviceType;
  final int passengerCount;

  const CompactEstimateWidget({
    super.key,
    required this.pickupCoordinates,
    required this.dropoffCoordinates,
    this.vehicleType = 'sedan',
    this.serviceType = 'standard',
    this.passengerCount = 1,
  });

  @override
  State<CompactEstimateWidget> createState() => _CompactEstimateWidgetState();
}

class _CompactEstimateWidgetState extends State<CompactEstimateWidget> {
  final QuoteEstimationService _estimationService = QuoteEstimationService();
  
  Map<String, dynamic>? _estimate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEstimate();
  }

  Future<void> _fetchEstimate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final estimate = await _estimationService.getEstimate(
        pickupCoordinates: widget.pickupCoordinates,
        dropoffCoordinates: widget.dropoffCoordinates,
        vehicleType: widget.vehicleType,
        serviceType: widget.serviceType,
        passengerCount: widget.passengerCount,
      );

      if (mounted) {
        setState(() {
          _estimate = estimate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Calculating...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (_estimate == null) {
      return const SizedBox.shrink();
    }

    final total = _estimate!['pricing']?['total'];
    if (total == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_money, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            'Est: ${QuotePricingHelper.formatCurrency(total.toDouble())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

