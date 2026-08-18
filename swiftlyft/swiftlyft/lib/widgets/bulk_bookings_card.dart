import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/bulk_booking.dart';
import '../models/booking.dart';
import '../models/coordinates.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../widgets/payment_processing_dialog.dart';

/// Bottom sheet to show detailed bulk booking information
class BulkBookingDetailSheet extends StatelessWidget {
  final BulkBooking booking;

  const BulkBookingDetailSheet({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final dateOnlyFormat = DateFormat('MMM dd, yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SwiftLyftTheme.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: SwiftLyftTheme.deepCharcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: SwiftLyftTheme.mediumGray,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (booking.description.isNotEmpty) ...[
                        _buildSectionTitle('Description'),
                        const SizedBox(height: 8),
                        Text(
                          booking.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: SwiftLyftTheme.deepCharcoal,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Booking Information
                      _buildSectionTitle('Booking Information'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.calendar_today, 'Created', dateFormat.format(booking.createdAt)),
                      if (booking.scheduledDate != null)
                        _buildInfoRow(Icons.event, 'Scheduled', dateOnlyFormat.format(booking.scheduledDate!)),
                      _buildInfoRow(Icons.directions_car, 'Total Vehicles', '${booking.totalVehicles}'),
                      _buildInfoRow(Icons.people, 'Total Passengers', '${booking.totalPassengers}'),
                      _buildInfoRow(Icons.list, 'Booking Items', '${booking.items.length}'),
                      _buildInfoRow(Icons.payment, 'Payment Status', booking.paymentStatusText),
                      const SizedBox(height: 24),
                      // Pricing Breakdown
                      _buildSectionTitle('Pricing Breakdown'),
                      const SizedBox(height: 12),
                      _buildPricingCard(booking),
                      const SizedBox(height: 24),
                      // Booking Items
                      _buildSectionTitle('Booking Items (${booking.items.length})'),
                      const SizedBox(height: 12),
                      ...booking.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildItemCard(item, index + 1);
                      }).toList(),
                      const SizedBox(height: 24),
                      // Special Notes
                      if (booking.specialNotes != null && booking.specialNotes!.isNotEmpty) ...[
                        _buildSectionTitle('Special Notes'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SwiftLyftTheme.lightGray.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.specialNotes!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: SwiftLyftTheme.deepCharcoal,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Actions (if not completed - allow deletion of cancelled bookings)
                      if (booking.status != BulkBookingStatus.completed) ...[
                        _buildSectionTitle('Actions'),
                        const SizedBox(height: 12),
                        _buildActionButtons(context),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: SwiftLyftTheme.deepCharcoal,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SwiftLyftTheme.mediumGray),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BulkBooking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPricingRow('Subtotal', booking.totalAmount),
          if (booking.discountAmount > 0)
            _buildPricingRow('Discount', -booking.discountAmount, isDiscount: true),
          const Divider(height: 24),
          _buildPricingRow('Total Amount', booking.finalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: SwiftLyftTheme.deepCharcoal,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}R ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isDiscount ? SwiftLyftTheme.successGreen : SwiftLyftTheme.deepCharcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BulkBookingItem item, int index) {
    final timeFormat = DateFormat('MMM dd, HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.vehicleName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.deepCharcoal,
                      ),
                    ),
                    Text(
                      'Quantity: ${item.quantity} • ${item.passengerCount} passengers each',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'R ${item.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1),
          const SizedBox(height: 12),
          _buildItemDetail(Icons.location_on, 'Pickup', item.pickupLocation),
          const SizedBox(height: 8),
          _buildItemDetail(Icons.location_on, 'Dropoff', item.dropoffLocation),
          const SizedBox(height: 8),
          _buildItemDetail(Icons.access_time, 'Pickup Time', timeFormat.format(item.pickupTime)),
          const SizedBox(height: 8),
          _buildItemDetail(Icons.attach_money, 'Unit Price', 'R ${item.unitPrice.toStringAsFixed(2)} per vehicle'),
        ],
      ),
    );
  }

  Widget _buildItemDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SwiftLyftTheme.mediumGray),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: SwiftLyftTheme.mediumGray,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Pay Now button for unpaid bookings (but not cancelled or completed ones)
        if (booking.paymentStatus == PaymentStatus.pending &&
            booking.status != BulkBookingStatus.cancelled &&
            booking.status != BulkBookingStatus.completed) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _processBulkPayment(context),
              icon: const Icon(Icons.payment, size: 18),
              label: Text('Pay Now - R ${booking.finalAmount.toStringAsFixed(2)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SwiftLyftTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
                child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCancelDialog(context);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SwiftLyftTheme.errorRed,
                  side: BorderSide(color: SwiftLyftTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (booking.status == BulkBookingStatus.draft) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement edit functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit functionality coming soon')),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SwiftLyftTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bulk Booking'),
        content: Text(
          'Are you sure you want to delete "${booking.title}"? This action cannot be undone and the booking will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await appState.cancelBulkBooking(booking.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close detail sheet
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bulk booking deleted successfully'),
                      backgroundColor: SwiftLyftTheme.successGreen,
                    ),
                  );
                  // UI is already updated via optimistic removal
                  // Refresh in background to sync with server
                  final appStateProvider = Provider.of<AppState>(context, listen: false);
                  appStateProvider.refreshBulkBookings(preserveFilter: true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete booking: ${e.toString()}'),
                      backgroundColor: SwiftLyftTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: SwiftLyftTheme.errorRed,
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBulkPayment(BuildContext context) async {
    // Show payment dialog - we'll create a mock booking object for the payment dialog
    final mockBooking = _createMockBookingForPayment();

    final paymentResult = await showPaymentDialog(context, mockBooking);

    if (paymentResult.success && context.mounted) {
      final appState = Provider.of<AppState>(context, listen: false);

      // Update the bulk booking payment status and status locally
      final updatedBooking = booking.copyWith(
        paymentStatus: PaymentStatus.paid,
        status: BulkBookingStatus.confirmed, // Change from draft to confirmed when paid
      );
      await appState.updateBulkBookingLocally(updatedBooking);

      // Only refresh from server if it wasn't a local payment
      if (!paymentResult.isLocalPayment) {
        await appState.refreshBulkBookings(preserveFilter: true);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Bulk booking payment processed successfully!'),
              ],
            ),
            backgroundColor: SwiftLyftTheme.successGreen,
          ),
        );

        // Close the detail sheet
        Navigator.pop(context);
      }
    }
  }

  /// Create a mock Booking object for the payment dialog
  /// The payment dialog expects a Booking object, so we create one with bulk booking data
  Booking _createMockBookingForPayment() {
    return Booking(
      id: booking.id,
      userId: '', // Will be filled by auth
      vehicleId: '', // Bulk booking has multiple vehicles
      vehicleName: '${booking.totalVehicles} Vehicles',
      driverId: '', // Bulk booking doesn't have a single driver
      driverName: 'Multiple Drivers',
      driverPhone: '',
      driverPhotoUrl: '',
      pickupAddress: booking.items.isNotEmpty ? booking.items.first.pickupLocation : 'Multiple Locations',
      dropoffAddress: booking.items.isNotEmpty ? booking.items.first.dropoffLocation : 'Multiple Locations',
      pickupLocation: const LatLng(-26.2041, 28.0473), // Default Johannesburg coordinates
      dropoffLocation: const LatLng(-26.2041, 28.0473), // Default Johannesburg coordinates
      pickupTime: booking.scheduledDate ?? DateTime.now(),
      passengerCount: booking.totalPassengers,
      basePrice: booking.finalAmount,
      finalPrice: booking.finalAmount,
      specialNotes: booking.specialNotes,
      closeProtectionOfficer: false,
      status: BookingStatus.confirmed, // Bulk bookings are confirmed when created
      paymentStatus: booking.paymentStatus,
      createdAt: booking.createdAt,
      updatedAt: DateTime.now(),
      pricing: {
        'baseFare': booking.finalAmount,
        'distanceFare': 0.0,
        'timeFare': 0.0,
        'serviceFee': 0.0,
        'taxes': 0.0,
        'discount': booking.discountAmount,
        'loyaltyDiscount': 0.0,
        'surgeMultiplier': 1.0,
        'total': booking.finalAmount,
        'currency': 'ZAR',
      },
    );
  }

  Color _getStatusColor(BulkBookingStatus status) {
    switch (status) {
      case BulkBookingStatus.draft:
        return SwiftLyftTheme.mediumGray;
      case BulkBookingStatus.pending:
        return SwiftLyftTheme.warmOrange;
      case BulkBookingStatus.confirmed:
        return SwiftLyftTheme.primaryBlue;
      case BulkBookingStatus.completed:
        return SwiftLyftTheme.successGreen;
      case BulkBookingStatus.cancelled:
        return SwiftLyftTheme.errorRed;
    }
  }
}

/// Widget to display bulk bookings for corporate users
class BulkBookingsCard extends StatefulWidget {
  const BulkBookingsCard({super.key});

  @override
  State<BulkBookingsCard> createState() => _BulkBookingsCardState();
}

class _BulkBookingsCardState extends State<BulkBookingsCard> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Load bulk bookings when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.auth.isLoggedIn) {
        appState.loadBulkBookings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Check if user has corporate account
        if (appState.corporateInfo == null) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStatusFilter(appState),
                const SizedBox(height: 16),
                if (appState.isLoadingBulkBookings)
                  _buildLoading()
                else if (appState.bulkBookingsError != null)
                  _buildError(appState)
                else if (appState.bulkBookings.isEmpty)
                  _buildEmptyState()
                else
                  _buildContent(appState),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.business_center,
            color: SwiftLyftTheme.primaryBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bulk Bookings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.deepCharcoal,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Corporate transportation management',
                style: TextStyle(
                  fontSize: 13,
                  color: SwiftLyftTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(AppState appState) {
    final statuses = ['All', 'draft', 'pending', 'confirmed', 'completed', 'cancelled'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final isSelected = (status == 'All' && _selectedStatus == null) || 
                           (_selectedStatus == status);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                status == 'All' ? 'All' : _capitalizeFirst(status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : SwiftLyftTheme.mediumGray,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = status == 'All' ? null : status;
                });
                appState.loadBulkBookings(status: _selectedStatus, page: 1);
              },
              backgroundColor: Colors.white,
              selectedColor: SwiftLyftTheme.primaryBlue,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? SwiftLyftTheme.primaryBlue : SwiftLyftTheme.lightGray,
                width: 1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: SwiftLyftTheme.errorRed,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load bulk bookings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SwiftLyftTheme.deepCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appState.bulkBookingsError ?? 'Unknown error',
              style: const TextStyle(
                fontSize: 13,
                color: SwiftLyftTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => appState.refreshBulkBookings(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SwiftLyftTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: SwiftLyftTheme.mediumGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedStatus == null 
                ? 'No Bulk Bookings Yet'
                : 'No ${_capitalizeFirst(_selectedStatus!)} Bookings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SwiftLyftTheme.deepCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bulk bookings will appear here once created',
              style: TextStyle(
                fontSize: 13,
                color: SwiftLyftTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppState appState) {
    final summary = appState.bulkBookingsSummary;
    final pagination = appState.bulkBookingsPagination;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary stats
        if (summary != null) _buildSummaryStats(summary),
        
        const SizedBox(height: 20),
        
        // Bookings list
        _buildBookingsList(appState.bulkBookings),

        // Pagination
        if (pagination != null && pagination.totalPages > 1)
          _buildPagination(appState, pagination),
      ],
    );
  }

  Widget _buildSummaryStats(BulkBookingSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  'Total Amount',
                  'R ${summary.totalAmount.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  SwiftLyftTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryStat(
                  'Total Discount',
                  'R ${summary.totalDiscount.toStringAsFixed(2)}',
                  Icons.discount,
                  SwiftLyftTheme.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  'Total Bookings',
                  summary.totalBookings.toString(),
                  Icons.event_note,
                  SwiftLyftTheme.warmOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryStat(
                  'Active',
                  summary.statusCounts.active.toString(),
                  Icons.pending_actions,
                  SwiftLyftTheme.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SwiftLyftTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: SwiftLyftTheme.deepCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<BulkBooking> bookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Bookings',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: SwiftLyftTheme.deepCharcoal,
          ),
        ),
        const SizedBox(height: 12),
        ...bookings.map((booking) => _buildBookingItem(booking)).toList(),
      ],
    );
  }

  Widget _buildBookingItem(BulkBooking booking) {
    final statusColor = _getStatusColor(booking.status);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return InkWell(
      onTap: () => _showBookingDetails(context, booking),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SwiftLyftTheme.lightGray,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: SwiftLyftTheme.deepCharcoal.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: SwiftLyftTheme.deepCharcoal,
                        ),
                      ),
                      if (booking.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          booking.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: SwiftLyftTheme.mediumGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Payment status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.isPaid
                        ? SwiftLyftTheme.successGreen.withOpacity(0.1)
                        : SwiftLyftTheme.warmOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.paymentStatusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: booking.isPaid
                          ? SwiftLyftTheme.successGreen
                          : SwiftLyftTheme.warmOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.directions_car,
                    '${booking.totalVehicles} vehicles',
                    SwiftLyftTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.people,
                    '${booking.totalPassengers} passengers',
                    SwiftLyftTheme.accentPurple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.list,
                    '${booking.items.length} items',
                    SwiftLyftTheme.warmOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: SwiftLyftTheme.lightGray),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 11,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                    Text(
                      'R ${booking.finalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: SwiftLyftTheme.deepCharcoal,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: SwiftLyftTheme.mediumGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(booking.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showBookingDetails(context, booking),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: SwiftLyftTheme.primaryBlue,
                  ),
                ),
                // Show action button for all statuses except completed
                if (booking.status != BulkBookingStatus.completed) ...[
                  const SizedBox(width: 8),
                  _buildActionButton(booking),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(BulkBooking booking) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: SwiftLyftTheme.mediumGray),
      onSelected: (value) => _handleAction(context, booking, value),
      itemBuilder: (context) => [
        // Pay Now option for unpaid bookings (but not cancelled or completed ones)
        if (booking.paymentStatus == PaymentStatus.pending &&
            booking.status != BulkBookingStatus.cancelled &&
            booking.status != BulkBookingStatus.completed)
          const PopupMenuItem(
            value: 'pay',
            child: Row(
              children: [
                Icon(Icons.payment, size: 18, color: SwiftLyftTheme.primaryBlue),
                SizedBox(width: 8),
                Text('Pay Now'),
              ],
            ),
          ),
        if (booking.status == BulkBookingStatus.draft)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: SwiftLyftTheme.primaryBlue),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        // Allow deletion of draft, pending, and cancelled bookings
        // Only prevent deletion of confirmed and completed bookings
        if (booking.status != BulkBookingStatus.completed)
          const PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: SwiftLyftTheme.errorRed),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
      ],
    );
  }
  
  void _handleAction(BuildContext context, BulkBooking booking, String action) {
    final appState = Provider.of<AppState>(context, listen: false);

    switch (action) {
      case 'pay':
        _showBookingDetails(context, booking); // Open detail sheet which has the Pay Now button
        break;
      case 'cancel':
        _showCancelDialog(context, booking, appState);
        break;
      case 'edit':
        // TODO: Navigate to edit screen or show edit dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
        break;
    }
  }
  
  void _showCancelDialog(BuildContext context, BulkBooking booking, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bulk Booking'),
        content: Text(
          'Are you sure you want to delete "${booking.title}"? This action cannot be undone and the booking will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
              onPressed: () async {
              Navigator.pop(context);
              try {
                await appState.cancelBulkBooking(booking.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bulk booking deleted successfully'),
                      backgroundColor: SwiftLyftTheme.successGreen,
                    ),
                  );
                  // UI is already updated via optimistic removal
                  // Refresh in background to sync with server
                  appState.refreshBulkBookings(preserveFilter: true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete booking: ${e.toString()}'),
                      backgroundColor: SwiftLyftTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: SwiftLyftTheme.errorRed,
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showBookingDetails(BuildContext context, BulkBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BulkBookingDetailSheet(booking: booking),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(AppState appState, BulkBookingPagination pagination) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: pagination.hasPrevPage
                ? () => appState.loadBulkBookings(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: SwiftLyftTheme.primaryBlue,
          ),
          Text(
            'Page ${pagination.currentPage} of ${pagination.totalPages}',
            style: TextStyle(
              fontSize: 13,
              color: SwiftLyftTheme.deepCharcoal,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            onPressed: pagination.hasNextPage
                ? () => appState.loadBulkBookings(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: SwiftLyftTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BulkBookingStatus status) {
    switch (status) {
      case BulkBookingStatus.draft:
        return SwiftLyftTheme.mediumGray;
      case BulkBookingStatus.pending:
        return SwiftLyftTheme.warmOrange;
      case BulkBookingStatus.confirmed:
        return SwiftLyftTheme.primaryBlue;
      case BulkBookingStatus.completed:
        return SwiftLyftTheme.successGreen;
      case BulkBookingStatus.cancelled:
        return SwiftLyftTheme.errorRed;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

