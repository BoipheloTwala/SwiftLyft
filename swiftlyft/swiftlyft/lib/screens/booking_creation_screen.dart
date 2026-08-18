import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coordinates.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../providers/payment_state.dart';
import '../models/payment.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../utils/card_utils.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/payment_card_widget.dart';

class BookingCreationScreen extends StatefulWidget {
  final String? vehicleId;
  final String? vehicleName;
  final String? vehicleType;
  // Repeat booking parameters
  final String? pickupAddress;
  final String? dropoffAddress;
  final int? passengerCount;
  final String? specialNotes;
  final bool? closeProtectionOfficer;

  const BookingCreationScreen({
    super.key,
    this.vehicleId,
    this.vehicleName,
    this.vehicleType,
    this.pickupAddress,
    this.dropoffAddress,
    this.passengerCount,
    this.specialNotes,
    this.closeProtectionOfficer,
  });

  @override
  State<BookingCreationScreen> createState() => _BookingCreationScreenState();
}

class _BookingCreationScreenState extends State<BookingCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _specialNotesController = TextEditingController();
  final _customerNotesController = TextEditingController();

  // Booking details
  String? _selectedVehicleId;
  String? _selectedVehicleName;
  String? _selectedVehicleType;
  String _serviceType = 'point-to-point';
  
  // Locations
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  
  // Date and time
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 2));
  bool _isFlexibleTime = false;
  int _flexibleWindow = 15;
  
  // Passengers and luggage
  int _passengerCount = 1;
  int _luggageCount = 0;
  
  // Payment
  String _paymentMethod = 'card';
  String? _selectedPaymentMethodId;
  
  // Pricing
  double _baseFare = 50.0;
  double _distanceFare = 0.0;
  double _timeFare = 0.0;
  double _serviceFee = 5.0;
  double _taxes = 0.0;
  double _discount = 0.0;
  double _total = 0.0;

  bool _isLoading = false;
  bool _isPriceCalculated = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
    _selectedVehicleName = widget.vehicleName;
    _selectedVehicleType = widget.vehicleType ?? 'sedan';

    // Set locations - use repeat booking values if provided, otherwise defaults
    _pickupLocation = const LatLng(-26.2041, 28.0473);
    _dropoffLocation = const LatLng(-26.1076, 28.0567);
    _pickupAddress = widget.pickupAddress ?? 'Johannesburg City Center, Gauteng';
    _dropoffAddress = widget.dropoffAddress ?? 'Sandton, Gauteng';
    _passengerCount = widget.passengerCount ?? 1;

    _pickupController.text = _pickupAddress;
    _dropoffController.text = _dropoffAddress;

    // Set special notes if provided
    if (widget.specialNotes != null && widget.specialNotes!.isNotEmpty) {
      _specialNotesController.text = widget.specialNotes!;
    }

    // Set close protection officer if provided
    if (widget.closeProtectionOfficer != null) {
      // Note: This would need to be added to the UI state if we want to pre-select it
    }
    
    _calculatePrice();
    
    // Load payment methods (only if not already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final appState = Provider.of<AppState>(context, listen: false);

        // Check if payment methods are already loaded
        if (appState.payments.paymentMethods.isNotEmpty) {
          debugPrint('✅ Payment methods already loaded (${appState.payments.paymentMethods.length}), using existing data');

          // Auto-select default payment method
          final defaultMethod = appState.payments.paymentMethods
              .where((m) => m.isDefault && m.isActive && !CardUtils.isCardExpired(m.expiryMonth, m.expiryYear))
              .firstOrNull;

          if (defaultMethod != null && mounted) {
            setState(() {
              _selectedPaymentMethodId = defaultMethod.id;
            });
          }
          return;
        }

        debugPrint('🔄 Loading payment methods in booking creation...');
        appState.payments.loadPaymentMethods().then((_) {
          if (!mounted) return;

          // Auto-select default payment method
          final defaultMethod = appState.payments.paymentMethods
              .where((m) => m.isDefault && m.isActive && !CardUtils.isCardExpired(m.expiryMonth, m.expiryYear))
              .firstOrNull;

          if (defaultMethod != null && mounted) {
            setState(() {
              _selectedPaymentMethodId = defaultMethod.id;
            });
          }
        }).catchError((e) {
          debugPrint('Error loading payment methods: $e');
        });
      } catch (e) {
        debugPrint('Error accessing payment state: $e');
      }
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _specialNotesController.dispose();
    _customerNotesController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    // Get vehicle base price from AppState if vehicle is selected
    double vehicleBasePrice = 600.0; // Default fallback for luxury service
    
    // Vehicle type-based base prices (luxury chauffeur service pricing)
    final typeBasedPrices = {
      'sedan': 600.0,
      'suv': 950.0,
      'luxury': 1800.0,
      'van': 1200.0,
      'truck': 1400.0,
      'hybrid': 700.0,
    };
    
    if (_selectedVehicleId != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      try {
        final vehicle = appState.allVehicles.firstWhere(
          (v) => v.id == _selectedVehicleId,
        );
        // Use vehicle's display price (adjusted for luxury service) if available, otherwise use type-based
        if (vehicle.basePrice > 0) {
          vehicleBasePrice = vehicle.displayPrice;
        } else {
          vehicleBasePrice = typeBasedPrices[vehicle.category] ?? typeBasedPrices[_selectedVehicleType ?? 'sedan'] ?? 600.0;
        }
      } catch (e) {
        // Vehicle not found, use type-based pricing
        vehicleBasePrice = typeBasedPrices[_selectedVehicleType ?? 'sedan'] ?? 600.0;
      }
    } else {
      // If no vehicle selected, use type-based pricing
      vehicleBasePrice = typeBasedPrices[_selectedVehicleType ?? 'sedan'] ?? 600.0;
    }
    
    // Add randomness to base price (±20%)
    final random = (DateTime.now().millisecondsSinceEpoch % 41) / 100.0; // 0.0 to 0.4
    final basePriceMultiplier = 0.9 + random; // 0.9 to 1.3 (90% to 130%)
    _baseFare = (vehicleBasePrice * basePriceMultiplier).roundToDouble();
    
    // Calculate distance-based fare with randomness
    if (_pickupLocation != null && _dropoffLocation != null) {
      final distance = _calculateDistance(_pickupLocation!, _dropoffLocation!);
      
      // Random per-km rate between R35 and R55 (luxury service rates)
      final perKmRandom = 35.0 + (DateTime.now().millisecondsSinceEpoch % 21); // R35-R55
      _distanceFare = (distance * perKmRandom).roundToDouble();
      
      // Random per-hour rate between R280 and R450, estimate time based on distance
      final estimatedTimeHours = (distance / 50.0).clamp(0.5, 3.0); // Assume 50 km/h average
      final perHourRandom = 280.0 + (DateTime.now().millisecondsSinceEpoch % 171); // R280-R450
      _timeFare = (estimatedTimeHours * perHourRandom).roundToDouble();
    } else {
      _distanceFare = 0.0;
      _timeFare = 0.0;
    }

    // Service fee with slight variation (R50 to R120 for premium service)
    final serviceFeeRandom = 50.0 + (DateTime.now().millisecondsSinceEpoch % 71);
    _serviceFee = serviceFeeRandom.roundToDouble();
    
    // Calculate subtotal
    final subtotal = _baseFare + _distanceFare + _timeFare + _serviceFee;
    
    // Calculate taxes (15% VAT)
    _taxes = (subtotal * 0.15).roundToDouble();
    
    // Calculate total before discount
    var calculatedTotal = subtotal + _taxes - _discount;
    
    // Ensure minimum price of R2500 for luxury chauffeur service
    if (calculatedTotal < 2500.0) {
      final shortfall = 2500.0 - calculatedTotal;
      // Distribute shortfall proportionally to make it look natural
      _baseFare = (_baseFare + (shortfall * 0.5)).roundToDouble();
      _distanceFare = (_distanceFare + (shortfall * 0.3)).roundToDouble();
      _timeFare = (_timeFare + (shortfall * 0.2)).roundToDouble();
      calculatedTotal = _baseFare + _distanceFare + _timeFare + _serviceFee + _taxes - _discount;
    }
    
    _total = calculatedTotal.roundToDouble();
    
    setState(() {
      _isPriceCalculated = true;
    });
  }

  double _calculateDistance(LatLng from, LatLng to) {
    // Simplified distance calculation (in km)
    // In production, use proper distance calculation or API
    final lat1 = from.latitude;
    final lon1 = from.longitude;
    final lat2 = to.latitude;
    final lon2 = to.longitude;
    
    final dLat = (lat2 - lat1).abs() * 111; // 1 degree ≈ 111 km
    final dLon = (lon2 - lon1).abs() * 111;
    
    return (dLat * dLat + dLon * dLon) * 0.5; // Simplified
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SwiftLyftTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _scheduledDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _scheduledDate.hour,
          _scheduledDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SwiftLyftTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _scheduledDate = DateTime(
          _scheduledDate.year,
          _scheduledDate.month,
          _scheduledDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _createBooking() async {
    // Comprehensive validation before submission
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please complete all required fields');
      return;
    }

    // Validate locations
    if (_pickupLocation == null || _dropoffLocation == null) {
      _showErrorMessage('Please select both pickup and dropoff locations');
      return;
    }

    if (_pickupAddress.isEmpty || _dropoffAddress.isEmpty) {
      _showErrorMessage('Please enter valid addresses for pickup and dropoff');
      return;
    }

    // Validate vehicle selection
    if (_selectedVehicleId == null || _selectedVehicleId!.isEmpty) {
      _showErrorMessage('Please select a vehicle before creating a booking');
      return;
    }

    // Validate scheduled date is in the future
    if (_scheduledDate.isBefore(DateTime.now())) {
      _showErrorMessage('Scheduled date must be in the future');
      return;
    }

    // Validate passenger count
    if (_passengerCount < 1 || _passengerCount > 10) {
      _showErrorMessage('Passenger count must be between 1 and 10');
      return;
    }

    // Validate pricing
    if (_total <= 0) {
      _showErrorMessage('Invalid pricing calculation. Please try again.');
      return;
    }
    
    // Validate payment method selection
    if (_selectedPaymentMethodId == null) {
      _showErrorMessage('Please select a payment method');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Build location objects with proper structure
      final pickupLocationData = {
        'address': _pickupAddress,
        'city': 'Johannesburg',
        'province': 'Gauteng',
        'coordinates': {
          'latitude': _pickupLocation!.latitude,
          'longitude': _pickupLocation!.longitude,
        },
      };

      final dropoffLocationData = {
        'address': _dropoffAddress,
        'city': 'Sandton',
        'province': 'Gauteng',
        'coordinates': {
          'latitude': _dropoffLocation!.latitude,
          'longitude': _dropoffLocation!.longitude,
        },
      };

      // Build pricing object matching backend schema
      final pricingData = {
        'baseFare': _baseFare,
        'distanceFare': _distanceFare,
        'timeFare': _timeFare,
        'serviceFee': _serviceFee,
        'taxes': _taxes,
        'discount': _discount,
        'loyaltyDiscount': 0.0,
        'surgeMultiplier': 1.0,
        'total': _total,
        'currency': 'ZAR',
      };

      debugPrint('📋 Creating booking with data:');
      debugPrint('  Vehicle: $_selectedVehicleId ($_selectedVehicleName)');
      debugPrint('  From: $_pickupAddress');
      debugPrint('  To: $_dropoffAddress');
      debugPrint('  Date: $_scheduledDate');
      debugPrint('  Passengers: $_passengerCount');
      debugPrint('  Total: R${_total.toStringAsFixed(2)}');
      
      // Map UI service type to backend enum
      String backendServiceType;
      switch (_serviceType) {
        case 'airport':
          backendServiceType = 'airport';
          break;
        case 'corporate':
          backendServiceType = 'corporate';
          break;
        default:
          backendServiceType = 'standard';
      }

      final booking = await appState.createBooking(
        vehicleId: _selectedVehicleId!,
        vehicleName: _selectedVehicleName ?? 'Unknown Vehicle',
        vehicleType: _selectedVehicleType ?? 'sedan',
        serviceType: backendServiceType,
        pickupLocation: pickupLocationData,
        dropoffLocation: dropoffLocationData,
        pickupAddress: _pickupAddress,
        dropoffAddress: _dropoffAddress,
        scheduledDate: _scheduledDate,
        pickupTime: _scheduledDate,
        passengerCount: _passengerCount,
        luggageCount: _luggageCount,
        isFlexibleTime: _isFlexibleTime,
        flexibleWindow: _flexibleWindow,
        pricing: pricingData,
        basePrice: _baseFare,
        finalPrice: _total,
        specialNotes: _specialNotesController.text.trim().isNotEmpty 
            ? _specialNotesController.text.trim() 
            : null,
        customerNotes: _customerNotesController.text.trim().isNotEmpty 
            ? _customerNotesController.text.trim() 
            : null,
        paymentMethod: _paymentMethod,
      );

      if (booking != null && mounted) {
        debugPrint('✅ Booking created successfully: ${booking.id}');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Booking created! ID: ${booking.id}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Reload bookings to show new booking in trip history
        await appState.loadBookings(page: 1, reset: true);
        
        // Navigate to home screen instead of trip tracking
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
        );
      } else {
        _showErrorMessage('Booking creation failed. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ Booking creation error: $e');
      if (mounted) {
        String errorMessage = 'Failed to create booking';
        
        // Parse error message for better user feedback
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('network') || errorStr.contains('connection')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
          errorMessage = 'Session expired. Please login again.';
        } else if (errorStr.contains('validation') || errorStr.contains('400')) {
          errorMessage = 'Invalid booking data. Please check all fields.';
        } else if (errorStr.contains('coordinates')) {
          errorMessage = 'Invalid location coordinates. Please re-select locations.';
        }
        
        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: SwiftLyftTheme.errorRed,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.bookingCreation,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Create Booking',
        subtitle: 'Book your premium ride',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVehicleSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),
                    _buildPassengerSection(),
                    const SizedBox(height: 24),
                    _buildServiceTypeSection(),
                    const SizedBox(height: 24),
                    _buildPaymentMethodSection(),
                    const SizedBox(height: 24),
                    _buildNotesSection(),
                    const SizedBox(height: 24),
                    _buildPricingSection(),
                    const SizedBox(height: 32),
                    _buildCreateButton(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVehicleSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: SwiftLyftTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text(
                  'Vehicle Selection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedVehicleName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: SwiftLyftTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedVehicleName!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _selectedVehicleType ?? 'sedan',
                            style: TextStyle(
                              fontSize: 14,
                              color: SwiftLyftTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          AppRoutes.vehicleListing,
                          arguments: {'selectMode': true},
                        );
                        if (!mounted) return;
                        if (result is Map) {
                          setState(() {
                            _selectedVehicleId = result['vehicleId'] as String?;
                            _selectedVehicleName = result['vehicleName'] as String?;
                            _selectedVehicleType = (result['vehicleType'] as String?) ?? 'sedan';
                            _calculatePrice(); // Recalculate price with new vehicle
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRoutes.vehicleListing,
                    arguments: {'selectMode': true},
                  );
                  if (!mounted) return;
                  if (result is Map) {
                    setState(() {
                      _selectedVehicleId = result['vehicleId'] as String?;
                      _selectedVehicleName = result['vehicleName'] as String?;
                      _selectedVehicleType = (result['vehicleType'] as String?) ?? 'sedan';
                      _calculatePrice(); // Recalculate price with new vehicle
                    });
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Select Vehicle'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: SwiftLyftTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text(
                  'Trip Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pickupController,
              decoration: InputDecoration(
                labelText: 'Pickup Location',
                prefixIcon: const Icon(Icons.my_location, color: SwiftLyftTheme.primaryBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pickup location';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _pickupAddress = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dropoffController,
              decoration: InputDecoration(
                labelText: 'Dropoff Location',
                prefixIcon: const Icon(Icons.location_on, color: SwiftLyftTheme.errorRed),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dropoff location';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _dropoffAddress = value;
                  _calculatePrice();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: SwiftLyftTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateFormat.format(_scheduledDate)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(timeFormat.format(_scheduledDate)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Flexible Time'),
              subtitle: Text(_isFlexibleTime 
                  ? 'Can pickup within $_flexibleWindow minutes of scheduled time'
                  : 'Exact pickup time required'),
              value: _isFlexibleTime,
              onChanged: (value) {
                setState(() {
                  _isFlexibleTime = value;
                });
              },
              activeColor: SwiftLyftTheme.primaryBlue,
            ),
            if (_isFlexibleTime) ...[
              const SizedBox(height: 8),
              Text(
                'Flexible Window: $_flexibleWindow minutes',
                style: const TextStyle(fontSize: 14),
              ),
              Slider(
                value: _flexibleWindow.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: '$_flexibleWindow min',
                onChanged: (value) {
                  setState(() {
                    _flexibleWindow = value.toInt();
                  });
                },
                activeColor: SwiftLyftTheme.primaryBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: SwiftLyftTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text(
                  'Passengers & Luggage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Passengers', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _passengerCount > 1
                                ? () => setState(() => _passengerCount--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_passengerCount',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _passengerCount < 8
                                ? () => setState(() => _passengerCount++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Luggage', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _luggageCount > 0
                                ? () => setState(() => _luggageCount--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_luggageCount',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _luggageCount < 10
                                ? () => setState(() => _luggageCount++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: SwiftLyftTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text(
                  'Service Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _serviceType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'point-to-point', child: Text('Point to Point')),
                DropdownMenuItem(value: 'airport', child: Text('Airport Transfer')),
                DropdownMenuItem(value: 'corporate', child: Text('Corporate Event')),
              ],
              onChanged: (value) {
                setState(() {
                  _serviceType = value!;
                  _calculatePrice();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payment, color: SwiftLyftTheme.primaryBlue),
                    const SizedBox(width: 12),
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.paymentMethods);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<AppState>(
              builder: (context, appState, child) {
                if (appState.payments.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final activeMethods = appState.payments.paymentMethods
                    .where((m) => m.isActive && !CardUtils.isCardExpired(m.expiryMonth, m.expiryYear))
                    .toList();
                
                if (activeMethods.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SwiftLyftTheme.warmOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SwiftLyftTheme.warmOrange),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.credit_card_off,
                          size: 40,
                          color: SwiftLyftTheme.warmOrange,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No payment methods available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please add a payment method to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.paymentMethods);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Payment Method'),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: activeMethods.map((method) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CompactPaymentCardWidget(
                        paymentMethod: method,
                        isSelected: _selectedPaymentMethodId == method.id,
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethodId = method.id;
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: SwiftLyftTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialNotesController,
              decoration: InputDecoration(
                labelText: 'Special Instructions',
                hintText: 'Any special requirements or instructions',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: SwiftLyftTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text(
                  'Price Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Base Fare', _baseFare),
            _buildPriceRow('Distance', _distanceFare),
            _buildPriceRow('Time', _timeFare),
            _buildPriceRow('Service Fee', _serviceFee),
            if (_discount > 0) _buildPriceRow('Discount', -_discount, isDiscount: true),
            const Divider(height: 24),
            _buildPriceRow('Taxes (15%)', _taxes),
            const Divider(height: 24),
            _buildPriceRow('Total', _total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : null,
            ),
          ),
          Text(
            'R ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? Colors.green : (isTotal ? SwiftLyftTheme.primaryBlue : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _createBooking,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: SwiftLyftTheme.primaryBlue,
        foregroundColor: SwiftLyftTheme.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(SwiftLyftTheme.pureWhite),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline),
                const SizedBox(width: 12),
                Text(
                  'Create Booking - R ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}

