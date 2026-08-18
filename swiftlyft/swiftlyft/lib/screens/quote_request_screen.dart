import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coordinates.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/quote_pricing_card.dart';
import '../utils/quote_pricing_helper.dart';
import '../services/quote_estimation_service.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/vehicle.dart';

class QuoteRequestScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const QuoteRequestScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<QuoteRequestScreen> createState() => _QuoteRequestScreenState();
}

class _QuoteRequestScreenState extends State<QuoteRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _notesController = TextEditingController();
  final QuoteEstimationService _estimationService = QuoteEstimationService();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _passengerCount = 1;
  int _luggageCount = 0;
  String _serviceType = 'standard';
  
  // Pricing state
  Map<String, dynamic>? _pricingData;
  double? _distance;
  int? _duration;
  bool _isPricingLoading = false;
  String? _pricingError;
  
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadPrefilledData();
    
    // Add listeners to trigger pricing calculation
    _pickupController.addListener(_onLocationChanged);
    _dropoffController.addListener(_onLocationChanged);
  }
  
  void _onLocationChanged() {
    // Debounce pricing calculation
    if (_pickupController.text.isNotEmpty && _dropoffController.text.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _pickupController.text.isNotEmpty && _dropoffController.text.isNotEmpty) {
          _calculatePricingFromBackend();
        }
      });
    }
  }

  Future<void> _loadPrefilledData() async {
    if (_isDisposed) return;
    
    try {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && mounted) {
      setState(() {
        _pickupController.text = args['pickupAddress'] ?? '';
        _dropoffController.text = args['dropoffAddress'] ?? '';
        _passengerCount = args['passengerCount'] ?? 1;
        _notesController.text = args['specialNotes'] ?? '';
      });
      }
    } catch (e) {
      debugPrint('Error loading prefilled data: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pickupController.dispose();
    _dropoffController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _calculatePricingFromBackend() async {
    if (_isDisposed || !mounted) return;
    
    // Validate inputs
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _isPricingLoading = true;
      _pricingError = null;
    });
    
    try {
      // Get mock coordinates from addresses
      final pickupCoords = QuotePricingHelper.getMockCoordinates(_pickupController.text);
      final dropoffCoords = QuotePricingHelper.getMockCoordinates(_dropoffController.text);
      
      // Map vehicle type
      final vehicleType = QuotePricingHelper.mapVehicleType(widget.vehicleName);
      
      debugPrint('📍 Calculating price: $vehicleType, $_serviceType, passengers: $_passengerCount');
      
      // Get price estimate from estimation service (with caching)
      final estimate = await _estimationService.getEstimate(
        pickupCoordinates: pickupCoords,
        dropoffCoordinates: dropoffCoords,
        vehicleType: vehicleType,
        serviceType: _serviceType,
        passengerCount: _passengerCount,
      );
      
      if (!mounted || _isDisposed) return;
      
      // Adjust backend pricing to luxury service pricing (frontend-only)
      final backendPricing = estimate['pricing'] as Map<String, dynamic>;
      final adjustedPricing = QuotePricingHelper.adjustToLuxuryPricing(
        backendPricing,
        vehicleType,
      );
      
      setState(() {
        _pricingData = adjustedPricing;
        _distance = estimate['distance']?.toDouble();
        _duration = estimate['duration']?.toInt();
        _isPricingLoading = false;
        _pricingError = null;
      });
      
      debugPrint('✅ Price calculated (backend: ${backendPricing['total']}, adjusted: ${adjustedPricing['total']})');
    } on ValidationException catch (e) {
      debugPrint('⚠️ Validation error: ${e.message}');
      
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _isPricingLoading = false;
        _pricingError = e.message;
      });
    } on EstimationException catch (e) {
      debugPrint('❌ Estimation error: ${e.message}');
      
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _isPricingLoading = false;
        _pricingError = e.message;
      });
    } catch (e) {
      debugPrint('❌ Failed to calculate price: $e');
      
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _isPricingLoading = false;
        _pricingError = 'Unable to calculate price. Please try again.';
      });
    }
  }


  void _submitQuoteRequest() async {
    if (_isDisposed) return;
    
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix the errors in the form'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Prevent multiple submissions
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate business logic
      if (_selectedDate.isBefore(DateTime.now())) {
        throw Exception('Please select a future date');
      }

      if (_passengerCount < 1 || _passengerCount > 10) {
        throw Exception('Invalid number of passengers');
      }

      // Get coordinates
      final pickupCoords = QuotePricingHelper.getMockCoordinates(_pickupController.text);
      final dropoffCoords = QuotePricingHelper.getMockCoordinates(_dropoffController.text);
      
      // Map vehicle type
      final vehicleType = QuotePricingHelper.mapVehicleType(widget.vehicleName);
      
      // Create scheduled datetime
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Submit quote via AppState
      final appState = Provider.of<AppState>(context, listen: false);
      
      await appState.createQuote(
        pickupLocation: LatLng(
          pickupCoords['latitude']!,
          pickupCoords['longitude']!,
        ),
        dropoffLocation: LatLng(
          dropoffCoords['latitude']!,
          dropoffCoords['longitude']!,
        ),
        vehicleType: vehicleType,
        serviceType: _serviceType,
        scheduledDate: scheduledDateTime,
        passengerCount: _passengerCount,
        pickupAddress: _pickupController.text,
        dropoffAddress: _dropoffController.text,
        specialNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
        luggageCount: _luggageCount,
      );

      if (_isDisposed) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showConfirmationDialog();
      }
    } catch (e) {
      if (_isDisposed) return;
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _submitQuoteRequest,
            ),
          ),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    final totalPrice = _pricingData != null 
        ? QuotePricingHelper.formatCurrency(_pricingData!['total']?.toDouble() ?? 0.0)
        : 'Price pending';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 12),
            const Text('Quote Request Submitted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle: ${widget.vehicleName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated Price: $totalPrice',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pickup: ${_pickupController.text}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Dropoff: ${_dropoffController.text}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'We will contact you within 2 hours with a detailed quote.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: WebContainer(
      child: Form(
        key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleInfo(),
              const SizedBox(height: 24),
              _buildTripDetails(),
              const SizedBox(height: 24),
              _buildAdditionalOptions(),
              const SizedBox(height: 24),
              // Pricing Card
              QuotePricingCard(
                pricingData: _pricingData,
                distance: _distance,
                duration: _duration,
                isLoading: _isPricingLoading,
                error: _pricingError,
              ),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );

    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.quoteRequest,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Request Quote',
        subtitle: 'Get a custom quote for your trip',
        showBackButton: true,
      ),
      body: content,
    );
  }


  Widget _buildVehicleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SwiftLyftTheme.primaryBlue, SwiftLyftTheme.accentPurple],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_car,
              color: SwiftLyftTheme.pureWhite,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicleName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Luxury Vehicle',
                  style: TextStyle(
                    fontSize: 14,
                    color: SwiftLyftTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            if (value.trim().length < 10) {
              return '$label must be at least 10 characters';
            }
            return null;
          },
          onChanged: (value) {
            // Real-time validation feedback
            if (value.isNotEmpty && value.length < 10) {
              setState(() {
                // Update UI to show validation state
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: SwiftLyftTheme.mediumGray),
            suffixIcon: IconButton(
              onPressed: () {
                // Location picker functionality
                _showLocationPicker();
              },
              icon: const Icon(Icons.my_location, color: SwiftLyftTheme.primaryBlue),
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: const Text('Location picker functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Mock location selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location picker coming soon!')),
              );
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }






  Widget _buildTripDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip Details',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildLocationField(
          controller: _pickupController,
          label: 'Pickup Location',
          hint: 'Enter pickup address',
          icon: Icons.location_on,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pickup location is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildLocationField(
          controller: _dropoffController,
          label: 'Dropoff Location',
          hint: 'Enter dropoff address',
          icon: Icons.location_on,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Dropoff location is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateTimeField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPassengerField(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Options',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Service Type Selector
        _buildServiceTypeSelector(),
        const SizedBox(height: 16),
        
        // Luggage Count
        _buildLuggageCountSelector(),
        const SizedBox(height: 16),
        
        // Special Notes
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Special Notes',
            hintText: 'Any special requirements or notes...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildServiceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _serviceType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(value: 'standard', child: Text('Standard')),
            DropdownMenuItem(value: 'corporate', child: Text('Corporate')),
            DropdownMenuItem(value: 'airport', child: Text('Airport Transfer')),
          ],
          onChanged: (value) {
            setState(() {
              _serviceType = value ?? 'standard';
            });
            _calculatePricingFromBackend();
          },
        ),
      ],
    );
  }
  
  Widget _buildLuggageCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Luggage Count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _luggageCount > 0
                  ? () {
                      setState(() {
                        _luggageCount--;
                      });
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_luggageCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: _luggageCount < 20
                  ? () {
                      setState(() {
                        _luggageCount++;
                      });
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
            const SizedBox(width: 8),
            const Text('bags'),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateTime(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: SwiftLyftTheme.mediumGray),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: SwiftLyftTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${DateFormat('MMM dd, yyyy').format(_selectedDate)} at ${_selectedTime.format(context)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: SwiftLyftTheme.mediumGray),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Passengers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: SwiftLyftTheme.mediumGray),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_passengerCount > 1) {
                    setState(() {
                      _passengerCount--;
                    });
                    _calculatePricingFromBackend();
                  }
                },
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$_passengerCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_passengerCount < 10) {
                    setState(() {
                      _passengerCount++;
                    });
                    _calculatePricingFromBackend();
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      final time = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: _selectedTime,
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitQuoteRequest,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Request Quote',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
} 