import 'package:flutter/material.dart';
import '../services/quote_estimation_service.dart';
import '../utils/quote_pricing_helper.dart';
import '../utils/theme.dart';
import '../widgets/unified_navigation.dart';
import '../utils/routes.dart';

/// Dedicated screen for price estimation with comparison features
class PriceEstimatorScreen extends StatefulWidget {
  const PriceEstimatorScreen({super.key});

  @override
  State<PriceEstimatorScreen> createState() => _PriceEstimatorScreenState();
}

class _PriceEstimatorScreenState extends State<PriceEstimatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final QuoteEstimationService _estimationService = QuoteEstimationService();

  String _vehicleType = 'sedan';
  String _serviceType = 'standard';
  int _passengerCount = 1;

  Map<String, dynamic>? _singleEstimate;
  Map<String, Map<String, dynamic>>? _vehicleComparison;
  Map<String, Map<String, dynamic>>? _serviceComparison;

  bool _isLoading = false;
  String? _error;
  String _comparisonMode = 'single'; // 'single', 'vehicles', 'services'

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _getSingleEstimate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _comparisonMode = 'single';
    });

    try {
      final pickupCoords = QuotePricingHelper.getMockCoordinates(_pickupController.text);
      final dropoffCoords = QuotePricingHelper.getMockCoordinates(_dropoffController.text);

      final estimate = await _estimationService.getEstimate(
        pickupCoordinates: pickupCoords,
        dropoffCoordinates: dropoffCoords,
        vehicleType: _vehicleType,
        serviceType: _serviceType,
        passengerCount: _passengerCount,
      );

      setState(() {
        _singleEstimate = estimate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _compareVehicleTypes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _comparisonMode = 'vehicles';
    });

    try {
      final pickupCoords = QuotePricingHelper.getMockCoordinates(_pickupController.text);
      final dropoffCoords = QuotePricingHelper.getMockCoordinates(_dropoffController.text);

      final comparison = await _estimationService.compareVehicleTypes(
        pickupCoordinates: pickupCoords,
        dropoffCoordinates: dropoffCoords,
        serviceType: _serviceType,
        passengerCount: _passengerCount,
      );

      setState(() {
        _vehicleComparison = comparison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _compareServiceTypes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _comparisonMode = 'services';
    });

    try {
      final pickupCoords = QuotePricingHelper.getMockCoordinates(_pickupController.text);
      final dropoffCoords = QuotePricingHelper.getMockCoordinates(_dropoffController.text);

      final comparison = await _estimationService.compareServiceTypes(
        pickupCoordinates: pickupCoords,
        dropoffCoordinates: dropoffCoords,
        vehicleType: _vehicleType,
        passengerCount: _passengerCount,
      );

      setState(() {
        _serviceComparison = comparison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.home,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Price Estimator',
        subtitle: 'Compare prices and get estimates',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: WebContainer(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                if (_isLoading) _buildLoadingState(),
                if (_error != null) _buildErrorState(),
                if (!_isLoading && _error == null) _buildResults(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pickupController,
              decoration: const InputDecoration(
                labelText: 'Pickup Location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dropoffController,
              decoration: const InputDecoration(
                labelText: 'Dropoff Location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _vehicleType,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'sedan', child: Text('Sedan')),
                      DropdownMenuItem(value: 'suv', child: Text('SUV')),
                      DropdownMenuItem(value: 'luxury', child: Text('Luxury')),
                      DropdownMenuItem(value: 'van', child: Text('Van')),
                    ],
                    onChanged: (value) =>
                        setState(() => _vehicleType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _serviceType,
                    decoration: const InputDecoration(
                      labelText: 'Service Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'standard', child: Text('Standard')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                      DropdownMenuItem(value: 'corporate', child: Text('Corporate')),
                      DropdownMenuItem(value: 'airport', child: Text('Airport')),
                    ],
                    onChanged: (value) =>
                        setState(() => _serviceType = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Passengers:'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _passengerCount > 1
                      ? () => setState(() => _passengerCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_passengerCount',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _passengerCount < 10
                      ? () => setState(() => _passengerCount++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getSingleEstimate,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Get Estimate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SwiftLyftTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _compareVehicleTypes,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare Vehicles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _compareServiceTypes,
                  icon: const Icon(Icons.compare),
                  label: const Text('Compare Services'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Calculating prices...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(_error ?? 'An error occurred')),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_comparisonMode == 'single' && _singleEstimate != null) {
      return _buildSingleEstimateResult();
    } else if (_comparisonMode == 'vehicles' && _vehicleComparison != null) {
      return _buildVehicleComparisonResult();
    } else if (_comparisonMode == 'services' && _serviceComparison != null) {
      return _buildServiceComparisonResult();
    }
    return const SizedBox.shrink();
  }

  Widget _buildSingleEstimateResult() {
    final pricing = _singleEstimate!['pricing'];
    final distance = _singleEstimate!['distance']?.toDouble();
    final duration = _singleEstimate!['duration']?.toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estimate Result',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (distance != null)
              _buildInfoRow('Distance', QuotePricingHelper.formatDistance(distance)),
            if (duration != null)
              _buildInfoRow('Duration', QuotePricingHelper.formatDuration(duration)),
            const Divider(height: 24),
            _buildInfoRow('Base Fare', QuotePricingHelper.formatCurrency(pricing['baseFare']?.toDouble() ?? 0)),
            _buildInfoRow('Distance Fare', QuotePricingHelper.formatCurrency(pricing['distanceFare']?.toDouble() ?? 0)),
            _buildInfoRow('Time Fare', QuotePricingHelper.formatCurrency(pricing['timeFare']?.toDouble() ?? 0)),
            _buildInfoRow('Service Fee', QuotePricingHelper.formatCurrency(pricing['serviceFee']?.toDouble() ?? 0)),
            _buildInfoRow('Taxes', QuotePricingHelper.formatCurrency(pricing['taxes']?.toDouble() ?? 0)),
            const Divider(height: 24),
            _buildInfoRow(
              'Total',
              QuotePricingHelper.formatCurrency(pricing['total']?.toDouble() ?? 0),
              isBold: true,
              fontSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleComparisonResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Type Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._vehicleComparison!.entries.map((entry) {
              final total = entry.value['pricing']?['total']?.toDouble() ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    QuotePricingHelper.formatCurrency(total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceComparisonResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Type Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._serviceComparison!.entries.map((entry) {
              final total = entry.value['pricing']?['total']?.toDouble() ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.room_service),
                  title: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    QuotePricingHelper.formatCurrency(total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

