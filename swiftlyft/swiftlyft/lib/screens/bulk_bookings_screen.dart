import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/bulk_booking.dart';
import '../models/vehicle.dart';
import '../providers/app_state.dart';
import '../providers/batch_booking_stack_provider.dart';
import '../services/vehicle_api_service.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/bulk_bookings_card.dart';

/// Comprehensive bulk bookings management screen for corporate users
class BulkBookingsManagementScreen extends StatefulWidget {
  const BulkBookingsManagementScreen({super.key});

  @override
  State<BulkBookingsManagementScreen> createState() => _BulkBookingsManagementScreenState();
}

class _BulkBookingsManagementScreenState extends State<BulkBookingsManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load bulk bookings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.auth.isLoggedIn && appState.corporateInfo != null) {
        appState.loadBulkBookings();
        
        // Check if navigating from batch booking stack
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args?['fromStack'] == true) {
          // Open create booking dialog with stack items
          _showCreateBookingDialog(context, appState);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Check if user has corporate account
        if (appState.corporateInfo == null) {
          return _buildNoCorporateAccount(context);
        }

        final content = SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, appState),
              const SizedBox(height: 24),
              const BulkBookingsCard(),
            ],
          ),
        );

        return UnifiedNavigation.buildScaffold(
          context: context,
          currentRoute: AppRoutes.bulkBookings,
          appBar: UnifiedAppBar.buildResponsive(
            context: context,
            title: 'Bulk Bookings',
            subtitle: 'Manage corporate transportation',
            showBackButton: true,
          ),
          body: content,
          floatingActionButton: _buildCreateButton(context, appState),
        );
      },
    );
  }

  Widget _buildNoCorporateAccount(BuildContext context) {
    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.bulkBookings,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Bulk Bookings',
        subtitle: 'Manage corporate transportation',
        showBackButton: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center_outlined,
                size: 80,
                color: SwiftLyftTheme.mediumGray.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Corporate Account Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.deepCharcoal,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bulk bookings are available for corporate accounts only.\nContact support to upgrade your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: SwiftLyftTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SwiftLyftTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState appState) {
    final summary = appState.bulkBookingsSummary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bulk Bookings Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.deepCharcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage multiple transportation bookings for ${appState.corporateInfo?.corporateAccount.companyName ?? "your company"}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: SwiftLyftTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (summary != null) ...[
          const SizedBox(height: 20),
          _buildQuickStats(summary),
        ],
      ],
    );
  }

  Widget _buildQuickStats(BulkBookingSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SwiftLyftTheme.primaryBlue.withOpacity(0.1),
            SwiftLyftTheme.accentPurple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SwiftLyftTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Bookings',
              summary.totalBookings.toString(),
              Icons.event_note,
              SwiftLyftTheme.primaryBlue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: SwiftLyftTheme.lightGray,
          ),
          Expanded(
            child: _buildStatItem(
              'Active',
              summary.statusCounts.active.toString(),
              Icons.pending_actions,
              SwiftLyftTheme.warmOrange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: SwiftLyftTheme.lightGray,
          ),
          Expanded(
            child: _buildStatItem(
              'Total Value',
              'R ${summary.totalAmount.toStringAsFixed(0)}',
              Icons.account_balance_wallet,
              SwiftLyftTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: SwiftLyftTheme.deepCharcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: SwiftLyftTheme.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context, AppState appState) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateBookingDialog(context, appState),
      backgroundColor: SwiftLyftTheme.primaryBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Create Booking'),
    );
  }

  void _showCreateBookingDialog(BuildContext context, AppState appState) {
    final stackProvider = Provider.of<BatchBookingStackProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final fromStack = args?['fromStack'] == true;
    
    // Read stack items (we'll pop them only after successful booking creation)
    // This way if user cancels, items remain in stack
    List<Map<String, dynamic>>? stackItems;
    if (fromStack && stackProvider.stack.isNotEmpty) {
      // Get all items from stack to pass to dialog
      // We'll use stack operations (popMultiple) only after successful booking
      stackItems = stackProvider.stack.map((item) => item.toJson()).toList();
      debugPrint('📦 Reading ${stackItems.length} items from stack for batch booking');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal to preserve form state
      builder: (context) => BulkBookingFormDialog(
        initialStackItems: stackItems,
        onSave: (bookingData) async {
          try {
            // Call the API to create the booking
            await appState.createBulkBooking(bookingData);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bulk booking created successfully!'),
                  backgroundColor: SwiftLyftTheme.successGreen,
                ),
              );
              
              // NOW use stack operations: pop all items from stack (LIFO)
              // This properly consumes the stack and resets it to 0 after successful booking creation
              if (fromStack && stackProvider.count > 0) {
                final poppedCount = stackProvider.count;
                final poppedItems = stackProvider.popMultiple(poppedCount);
                debugPrint('📦 Popped ${poppedItems.length} items from stack using LIFO operation');
                debugPrint('✅ Stack reset to ${stackProvider.count} after successful batch booking creation');
              }
            }
            
            // Refresh the bookings list
            await appState.refreshBulkBookings();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create booking: ${e.toString()}'),
                  backgroundColor: SwiftLyftTheme.errorRed,
                ),
              );
              // If booking fails, items remain in stack (user can try again)
              debugPrint('❌ Booking failed - stack items preserved');
            }
          }
        },
      ),
    );
  }
}

/// Dialog for creating/editing bulk bookings
class BulkBookingFormDialog extends StatefulWidget {
  final BulkBooking? booking;
  final Function(Map<String, dynamic>) onSave;
  final List<dynamic>? initialStackItems; // Items from batch booking stack

  const BulkBookingFormDialog({
    super.key,
    this.booking,
    required this.onSave,
    this.initialStackItems,
  });

  @override
  State<BulkBookingFormDialog> createState() => _BulkBookingFormDialogState();
}

class _BulkBookingFormDialogState extends State<BulkBookingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specialNotesController = TextEditingController();
  DateTime? _scheduledDate;
  final List<BulkBookingItemForm> _items = [];

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  Future<void> _initializeItems() async {
    if (widget.booking != null) {
      _titleController.text = widget.booking!.title;
      _descriptionController.text = widget.booking!.description;
      _specialNotesController.text = widget.booking!.specialNotes ?? '';
      _scheduledDate = widget.booking!.scheduledDate;
      // Load existing items
      for (var item in widget.booking!.items) {
        _items.add(BulkBookingItemForm.fromModel(item));
      }
    } else if (widget.initialStackItems != null && widget.initialStackItems!.isNotEmpty) {
      // Load items from batch booking stack - one booking item per vehicle
      // Example: If user long-pressed 3 vehicles, they get 3 booking items/cards
      debugPrint('📦 Initializing bulk booking from stack with ${widget.initialStackItems!.length} vehicles');
      
      final appState = Provider.of<AppState>(context, listen: false);
      final vehicleService = VehicleService();
      
      // Create one booking item for each vehicle in the stack
      for (var stackItem in widget.initialStackItems!) {
        final item = BulkBookingItemForm();
        final vehicleId = stackItem['vehicleId'] as String?;
        final vehicleName = stackItem['vehicleName'] as String?;
        
        debugPrint('  🚗 Loading vehicle: $vehicleName (ID: $vehicleId)');
        
        // Try to find the vehicle in the loaded vehicles list first
        Vehicle? vehicle;
        if (vehicleId != null) {
          try {
            vehicle = appState.allVehicles.firstWhere(
              (v) => v.id == vehicleId,
            );
            debugPrint('    ✅ Vehicle found in loaded vehicles');
          } catch (_) {
            // Vehicle not in loaded list, fetch it from API
            try {
              debugPrint('    🔄 Fetching vehicle from API...');
              vehicle = await vehicleService.getVehicleDetails(vehicleId);
              debugPrint('    ✅ Vehicle fetched successfully');
            } catch (e) {
              debugPrint('    ❌ Failed to load vehicle $vehicleId: $e');
              // Continue without vehicle - user will need to select manually
            }
          }
          
          // Set the vehicle if found (non-null check required)
          if (vehicle != null) {
            item.setVehicle(vehicle!); // Non-null assertion safe here due to check above
            debugPrint('    ✓ Vehicle assigned to booking item');
          } else {
            debugPrint('    ⚠️ Vehicle not found - user will need to select manually');
          }
        }
        
        // Set default values - each vehicle gets quantity 1
        item.quantityController.text = '1';
        _items.add(item);
        debugPrint('    ✓ Booking item ${_items.length} created');
      }
      
      debugPrint('📦 Created ${_items.length} booking items from ${widget.initialStackItems!.length} stack vehicles');
    } else {
      // Add one empty item by default
      _addItem();
    }
    
    // Notify listeners after async initialization
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _specialNotesController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(BulkBookingItemForm());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.booking != null;
    final total = _calculateTotal();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SwiftLyftTheme.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit : Icons.add_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Bulk Booking' : 'Create Bulk Booking',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Booking Title *',
                          hintText: 'e.g., Executive Team - Q4 Meeting',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Describe the purpose of this bulk booking',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Scheduled Date
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Scheduled Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _scheduledDate != null
                                ? DateFormat('MMM dd, yyyy').format(_scheduledDate!)
                                : 'Select date (optional)',
                            style: TextStyle(
                              color: _scheduledDate != null
                                  ? SwiftLyftTheme.deepCharcoal
                                  : SwiftLyftTheme.mediumGray,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Booking Items Section
                      Row(
                        children: [
                          const Text(
                            'Booking Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: SwiftLyftTheme.deepCharcoal,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Items List
                      if (_items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: SwiftLyftTheme.lightGray.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No items added. Click "Add Item" to begin.',
                              style: TextStyle(color: SwiftLyftTheme.mediumGray),
                            ),
                          ),
                        )
                      else
                        ..._items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return _buildItemCard(index, item);
                        }).toList(),

                      const SizedBox(height: 24),

                      // Special Notes
                      TextFormField(
                        controller: _specialNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Special Notes',
                          hintText: 'Any special instructions or requirements',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Estimated Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: SwiftLyftTheme.deepCharcoal,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'R ${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: SwiftLyftTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SwiftLyftTheme.lightGray.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SwiftLyftTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEdit ? 'Update Booking' : 'Create Booking'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, BulkBookingItemForm item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SwiftLyftTheme.deepCharcoal,
                  ),
                ),
                const Spacer(),
                if (_items.length > 1)
                  IconButton(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.delete_outline, color: SwiftLyftTheme.errorRed),
                    tooltip: 'Remove item',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Vehicle selection
            InkWell(
              onTap: () => _selectVehicle(context, item),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Vehicle *',
                  hintText: 'Tap to select vehicle',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_forward_ios, size: 18),
                  isDense: true,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.hasVehicle
                            ? '${item.selectedVehicle!.name} (${item.selectedVehicle!.category})'
                            : 'Select vehicle',
                        style: TextStyle(
                          fontSize: 14,
                          color: item.hasVehicle
                              ? SwiftLyftTheme.deepCharcoal
                              : SwiftLyftTheme.mediumGray,
                          fontWeight: item.hasVehicle ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty < 1) {
                        return 'Min 1';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price *',
                      prefixText: 'R ',
                      border: OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                      fillColor: SwiftLyftTheme.lightGray,
                    ),
                    enabled: false, // Price is uneditable - comes from vehicle
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: SwiftLyftTheme.deepCharcoal,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.pickupLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      if (item.selectedVehicle != null) {
                        setState(() {
                          item.calculatePrice();
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.dropoffLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Dropoff Location *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      if (item.selectedVehicle != null) {
                        setState(() {
                          item.calculatePrice();
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectItemPickupTime(context, item),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Pickup Time *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time, size: 18),
                        isDense: true,
                      ),
                      child: Text(
                        item.pickupTime != null
                            ? DateFormat('MMM dd, HH:mm').format(item.pickupTime!)
                            : 'Select time',
                        style: TextStyle(
                          fontSize: 14,
                          color: item.pickupTime != null
                              ? SwiftLyftTheme.deepCharcoal
                              : SwiftLyftTheme.mediumGray,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.passengerCountController,
                    decoration: const InputDecoration(
                      labelText: 'Passengers/Vehicle *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 1) {
                        return 'Min 1';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Subtotal: R ${item.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: SwiftLyftTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _selectVehicle(BuildContext context, BulkBookingItemForm item) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.vehicleListing,
      arguments: {'selectMode': true},
    );
    
    if (!mounted) return;
    
    // Trigger rebuild to ensure UI reflects current controller values
    setState(() {});
    
    if (result is Map) {
      final vehicleId = result['vehicleId'] as String?;
      
      if (vehicleId != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        Vehicle? vehicle;
        
        try {
          // Try to find vehicle in loaded vehicles first
          vehicle = appState.allVehicles.firstWhere(
            (v) => v.id == vehicleId,
          );
        } catch (_) {
          // Vehicle not in loaded list, try to fetch it
          try {
            final vehicleService = VehicleService();
            vehicle = await vehicleService.getVehicleDetails(vehicleId);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load vehicle: ${e.toString()}'),
                  backgroundColor: SwiftLyftTheme.errorRed,
                ),
              );
            }
            return;
          }
        }
        
        if (vehicle != null && mounted) {
          setState(() {
            item.setVehicle(vehicle!); // Non-null assertion safe due to check above
          });
        }
      }
    }
  }

  Future<void> _selectItemPickupTime(BuildContext context, BulkBookingItemForm item) async {
    final date = await showDatePicker(
      context: context,
      initialDate: item.pickupTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(item.pickupTime ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          item.pickupTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate items
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one booking item'),
          backgroundColor: SwiftLyftTheme.errorRed,
        ),
      );
      return;
    }

    for (var item in _items) {
      if (!item.hasVehicle) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a vehicle for all items'),
            backgroundColor: SwiftLyftTheme.errorRed,
          ),
        );
        return;
      }
      if (item.pickupTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set pickup time for all items'),
            backgroundColor: SwiftLyftTheme.errorRed,
          ),
        );
        return;
      }
      
      // Validate each item's calculated total must be more than the vehicle's base price
      // The price is now calculated similar to single bookings (includes distance, time, service fee, taxes)
      if (item.selectedVehicle != null) {
        final vehicleBasePrice = item.selectedVehicle!.basePrice;
        final itemTotal = item.totalPrice; // Uses calculated price
        
        // Each booking item's total must be MORE than the vehicle's base price
        // This is automatically satisfied since calculation ensures minimum R1200 per item
        // But we verify the unit price (per vehicle) exceeds base price
        if (item.unitPrice <= vehicleBasePrice && item.unitPrice > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Booking item ${_items.indexOf(item) + 1}: Price calculation issue. '
                'Please ensure pickup and dropoff locations are entered.'
              ),
              backgroundColor: SwiftLyftTheme.errorRed,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }
    }

    // Validate overall total price must be more than R1200 (updated from R900 for more realistic pricing)
    final total = _calculateTotal();
    if (total <= 1200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total booking amount must be more than R1200'),
          backgroundColor: SwiftLyftTheme.errorRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Build booking data
    final bookingData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'items': _items.map((item) => item.toJson()).toList(),
      'scheduledDate': _scheduledDate?.toIso8601String(),
      'specialNotes': _specialNotesController.text.trim(),
      'totalAmount': _calculateTotal(),
    };

    Navigator.pop(context);
    widget.onSave(bookingData);
  }
}

/// Form helper for bulk booking items
class BulkBookingItemForm {
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController pickupLocationController;
  final TextEditingController dropoffLocationController;
  final TextEditingController passengerCountController;
  DateTime? pickupTime;
  
  // Selected vehicle (instead of text field)
  Vehicle? selectedVehicle;
  
  // Cached pricing breakdown (similar to single booking)
  double _baseFare = 0.0;
  double _distanceFare = 0.0;
  double _timeFare = 0.0;
  double _serviceFee = 0.0;
  double _taxes = 0.0;
  double _calculatedTotal = 0.0;
  bool _isPriceCalculated = false;

  BulkBookingItemForm()
      : quantityController = TextEditingController(text: '1'),
        unitPriceController = TextEditingController(text: '0'),
        pickupLocationController = TextEditingController(),
        dropoffLocationController = TextEditingController(),
        passengerCountController = TextEditingController(text: '1') {
    // Listen to location changes to recalculate price
    pickupLocationController.addListener(_recalculatePrice);
    dropoffLocationController.addListener(_recalculatePrice);
    quantityController.addListener(_recalculatePrice);
  }

  BulkBookingItemForm.fromModel(BulkBookingItem item)
      : quantityController = TextEditingController(text: item.quantity.toString()),
        unitPriceController = TextEditingController(text: item.unitPrice.toString()),
        pickupLocationController = TextEditingController(text: item.pickupLocation),
        dropoffLocationController = TextEditingController(text: item.dropoffLocation),
        passengerCountController = TextEditingController(text: item.passengerCount.toString()),
        pickupTime = item.pickupTime {
    // Listen to location changes to recalculate price
    pickupLocationController.addListener(_recalculatePrice);
    dropoffLocationController.addListener(_recalculatePrice);
    quantityController.addListener(_recalculatePrice);
  }

  /// Set selected vehicle and recalculate price
  void setVehicle(Vehicle vehicle) {
    selectedVehicle = vehicle;
    calculatePrice();
    _updateUnitPriceController();
  }
  
  /// Calculate price breakdown similar to single booking
  /// This method recalculates when vehicle, locations, or quantity changes
  /// Made public so it can be called from the dialog when locations change
  void calculatePrice() {
    if (selectedVehicle == null) {
      _calculatedTotal = 0.0;
      _isPriceCalculated = false;
      return;
    }
    
    // Get vehicle base price (use adjusted display price for luxury service)
    double vehicleBasePrice = selectedVehicle!.basePrice > 0 
        ? selectedVehicle!.displayPrice
        : _getTypeBasedPrice(selectedVehicle!.category);
    
    // Vehicle type-based base prices (luxury chauffeur service pricing)
    final typeBasedPrices = {
      'sedan': 600.0,
      'suv': 950.0,
      'luxury': 1800.0,
      'van': 1200.0,
      'truck': 1400.0,
      'hybrid': 700.0,
    };
    
    if (vehicleBasePrice == 0) {
      vehicleBasePrice = typeBasedPrices[selectedVehicle!.category.toLowerCase()] ?? 600.0;
    }
    
    // Use deterministic multiplier based on vehicle ID (stable across recalculations)
    final vehicleHash = selectedVehicle!.id.hashCode.abs();
    final basePriceMultiplier = 1.0 + ((vehicleHash % 30) / 100.0); // 1.0 to 1.3 (100% to 130%)
    _baseFare = (vehicleBasePrice * basePriceMultiplier).roundToDouble();
    
    // Calculate distance-based fare (deterministic based on locations)
    final pickupLoc = pickupLocationController.text.trim();
    final dropoffLoc = dropoffLocationController.text.trim();
    
    if (pickupLoc.isNotEmpty && dropoffLoc.isNotEmpty) {
      final distance = _calculateDistance(pickupLoc, dropoffLoc);
      
      // Deterministic per-km rate based on vehicle and distance (luxury service rates)
      final perKmRate = 40.0 + ((vehicleHash % 16) / 1.0); // R40 to R55 per km
      _distanceFare = (distance * perKmRate).roundToDouble();
      
      // Deterministic per-hour rate, estimate time based on distance
      final estimatedTimeHours = (distance / 50.0).clamp(0.5, 4.0); // Assume 50 km/h average
      final perHourRate = 300.0 + ((vehicleHash % 151) / 1.0); // R300 to R450 per hour
      _timeFare = (estimatedTimeHours * perHourRate).roundToDouble();
    } else {
      _distanceFare = 0.0;
      _timeFare = 0.0;
    }

    // Service fee (deterministic based on vehicle, premium service)
    _serviceFee = (60.0 + (vehicleHash % 61)).roundToDouble(); // R60 to R120
    
    // Calculate subtotal
    final subtotal = _baseFare + _distanceFare + _timeFare + _serviceFee;
    
    // Calculate taxes (15% VAT)
    _taxes = (subtotal * 0.15).roundToDouble();
    
    // Calculate total
    var calculatedTotal = subtotal + _taxes;
    
    // Ensure minimum price of R2800 per item (higher minimum for luxury service)
    // If calculated price is below minimum, scale up proportionally
    if (calculatedTotal < 2800.0) {
      final scaleFactor = 2800.0 / calculatedTotal;
      _baseFare = (_baseFare * scaleFactor * 0.4).roundToDouble();
      _distanceFare = (_distanceFare * scaleFactor * 0.35).roundToDouble();
      _timeFare = (_timeFare * scaleFactor * 0.25).roundToDouble();
      // Recalculate with scaled values
      final newSubtotal = _baseFare + _distanceFare + _timeFare + _serviceFee;
      _taxes = (newSubtotal * 0.15).roundToDouble();
      calculatedTotal = newSubtotal + _taxes;
    }
    
    _calculatedTotal = calculatedTotal.roundToDouble();
    _isPriceCalculated = true;
    _updateUnitPriceController();
  }
  
  /// Get type-based price fallback
  double _getTypeBasedPrice(String category) {
    final typeBasedPrices = {
      'sedan': 600.0,
      'suv': 950.0,
      'luxury': 1800.0,
      'van': 1200.0,
      'truck': 1400.0,
      'hybrid': 700.0,
    };
    return typeBasedPrices[category.toLowerCase()] ?? 600.0;
  }
  
  /// Calculate distance from addresses (mock implementation)
  double _calculateDistance(String fromAddress, String toAddress) {
    // Generate mock coordinates from addresses (similar to QuotePricingHelper)
    final fromHash = fromAddress.hashCode.abs();
    final toHash = toAddress.hashCode.abs();
    
    final fromLat = -26.2041 + (fromHash % 100) / 1000.0;
    final fromLng = 28.0473 + (fromHash % 100) / 1000.0;
    final toLat = -26.2041 + (toHash % 100) / 1000.0;
    final toLng = 28.0473 + (toHash % 100) / 1000.0;
    
    // Simplified distance calculation (in km)
    final dLat = (toLat - fromLat).abs() * 111; // 1 degree ≈ 111 km
    final dLon = (toLng - fromLng).abs() * 111;
    
    // Ensure minimum distance of 5km for realistic pricing
    final distance = (dLat * dLat + dLon * dLon) * 0.5;
    return distance.clamp(5.0, 100.0); // Clamp between 5km and 100km
  }
  
  /// Recalculate price when fields change (called by listeners)
  void _recalculatePrice() {
    if (selectedVehicle != null) {
      calculatePrice();
    }
  }
  
  /// Update unit price controller with calculated price per vehicle
  void _updateUnitPriceController() {
    if (_isPriceCalculated && _calculatedTotal > 0) {
      unitPriceController.text = _calculatedTotal.toStringAsFixed(2);
    } else if (selectedVehicle != null) {
      unitPriceController.text = selectedVehicle!.basePrice.toStringAsFixed(2);
    }
  }

  /// Get total price (quantity × calculated unit price per vehicle)
  double get totalPrice {
    if (!_isPriceCalculated || _calculatedTotal == 0) {
      // Fallback to simple calculation if price not calculated yet
      final qty = int.tryParse(quantityController.text) ?? 0;
      final price = double.tryParse(unitPriceController.text) ?? 0.0;
      return qty * price;
    }
    
    final qty = int.tryParse(quantityController.text) ?? 1;
    return (qty * _calculatedTotal).roundToDouble();
  }
  
  /// Get unit price (calculated price per vehicle)
  double get unitPrice {
    if (_isPriceCalculated && _calculatedTotal > 0) {
      return _calculatedTotal;
    }
    return double.tryParse(unitPriceController.text) ?? 0.0;
  }

  bool get hasVehicle => selectedVehicle != null;

  String get vehicleDisplayName => selectedVehicle?.name ?? 'No vehicle selected';
  
  bool get hasLocations => 
      pickupLocationController.text.trim().isNotEmpty && 
      dropoffLocationController.text.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': selectedVehicle?.id ?? '',
      'vehicleName': selectedVehicle?.name ?? '',
      'quantity': int.parse(quantityController.text),
      'unitPrice': double.parse(unitPriceController.text),
      'pickupLocation': pickupLocationController.text.trim(),
      'dropoffLocation': dropoffLocationController.text.trim(),
      'pickupTime': pickupTime?.toIso8601String(),
      'passengerCount': int.parse(passengerCountController.text),
    };
  }

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    pickupLocationController.dispose();
    dropoffLocationController.dispose();
    passengerCountController.dispose();
  }
}

