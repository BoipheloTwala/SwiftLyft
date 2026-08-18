import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../models/booking.dart';
import '../providers/app_state.dart';
import '../providers/trip_history_queue_provider.dart';
import '../models/trip_history_queue_item.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/error_handler.dart' as error_handler;
import '../widgets/payment_processing_dialog.dart';
import '../utils/routes.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize queue provider with AppState reference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        final queueProvider = Provider.of<TripHistoryQueueProvider>(context, listen: false);
        
        // Set AppState reference for queue operations
        queueProvider.setAppState(appState);
        
        if (appState.isLoggedIn) {
          // Reload bookings to ensure latest data
          appState.loadBookings(page: 1, reset: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    super.dispose();
  }

  List<Booking> get _activeBookings => Provider.of<AppState>(context, listen: false).activeBookings;
  List<Booking> get _completedBookings => Provider.of<AppState>(context, listen: false).completedBookings;
  List<Booking> get _cancelledBookings => Provider.of<AppState>(context, listen: false).allBookings.where((b) => b.isCancelled).toList();

  @override
  Widget build(BuildContext context) {
    final content = Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoadingBookings) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your trips...'),
              ],
            ),
          );
        }

        if (appState.bookingError != null) {
          return error_handler.ErrorWidget(
            message: appState.bookingError!,
            onRetry: () => appState.loadBookings(),
          );
        }

        return Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_activeBookings, 'No active trips'),
                _buildBookingsList(_completedBookings, 'No completed trips'),
                _buildBookingsList(_cancelledBookings, 'No cancelled trips'),
              ],
            ),
            // Queue status indicator
            _buildQueueIndicator(),
          ],
        );
      },
    );


    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.tripHistory,
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: SwiftLyftTheme.pureWhite,
        foregroundColor: SwiftLyftTheme.deepCharcoal,
        elevation: SwiftLyftTheme.isWeb ? 2 : 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: content,
    );
  }




  Widget _buildBookingsList(List<Booking> bookings, String emptyMessage) {
    final filteredBookings = _filterBookings(bookings);
    
    if (filteredBookings.isEmpty) {
      return error_handler.EmptyStateWidget(
        message: emptyMessage,
        icon: Icons.history,
        onAction: () {
          Navigator.pushNamed(context, AppRoutes.vehicleListing);
        },
        actionLabel: 'Book a Trip',
      );
    }

    final appState = Provider.of<AppState>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () async {
        // Use queue for refresh operation
        final queueProvider = Provider.of<TripHistoryQueueProvider>(context, listen: false);
        queueProvider.enqueue(
          bookingId: '', // No specific booking for refresh
          operation: TripQueueOperation.refreshBooking,
        );
        // Also trigger immediate load as fallback
        await appState.loadBookings(page: 1, reset: true);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
            if (appState.hasMoreBookings && !appState.isLoadingMoreBookings) {
              appState.loadMoreBookings();
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredBookings.length + 1,
          itemBuilder: (context, index) {
            if (index < filteredBookings.length) {
              final booking = filteredBookings[index];
              return _buildBookingCard(booking);
            }
            // Footer loader / end indicator
            if (appState.isLoadingMoreBookings) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!appState.hasMoreBookings) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No more trips')),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    // No client-side filtering needed - server handles filtering via status
    return bookings;
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SwiftLyftTheme.pureWhite,
                SwiftLyftTheme.lightGray.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and price
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(booking.status).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      booking.statusText,
                      style: const TextStyle(
                        color: SwiftLyftTheme.pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  Text(
                    'R${booking.finalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                          fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.primaryBlue,
                    ),
                      ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(booking.pickupTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Vehicle info
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: SwiftLyftTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      booking.vehicleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Route information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SwiftLyftTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
              Row(
                children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: SwiftLyftTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking.pickupAddress,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 3.5, top: 4, bottom: 4),
                      width: 1,
                      height: 20,
                      color: SwiftLyftTheme.mediumGray.withValues(alpha: 0.3),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: SwiftLyftTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking.dropoffAddress,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                  ),
                ],
              ),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  // Pay Now button for unpaid bookings (but not cancelled ones)
                  if (booking.paymentStatus == PaymentStatus.pending && !booking.isCancelled)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _processPayment(booking),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Pay Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SwiftLyftTheme.primaryBlue,
                          foregroundColor: SwiftLyftTheme.pureWhite,
                        ),
                      ),
                    ),
                  if (booking.paymentStatus == PaymentStatus.pending && 
                      (booking.isCompleted || booking.rating != null))
                    const SizedBox(width: 8),
                  if (booking.isCancelled)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDeleteBooking(booking),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: SwiftLyftTheme.pureWhite,
                        ),
                      ),
                    ),
                  if (booking.isActive && !booking.isCompleted) ...[
                    // Show "Mark as Completed" for non-completed active bookings
                    if (booking.status == BookingStatus.pending || 
                        booking.status == BookingStatus.confirmed ||
                        booking.status == BookingStatus.driverAssigned ||
                        booking.status == BookingStatus.driverEnRoute ||
                        booking.status == BookingStatus.driverArrived ||
                        booking.status == BookingStatus.inProgress)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markBookingAsCompleted(booking),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Mark Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SwiftLyftTheme.successGreen,
                            foregroundColor: SwiftLyftTheme.pureWhite,
                          ),
                        ),
                      ),
                    if (booking.status == BookingStatus.pending || 
                        booking.status == BookingStatus.confirmed ||
                        booking.status == BookingStatus.driverAssigned ||
                        booking.status == BookingStatus.driverEnRoute ||
                        booking.status == BookingStatus.driverArrived ||
                        booking.status == BookingStatus.inProgress)
                      const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmCancelBooking(booking),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: SwiftLyftTheme.pureWhite,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return SwiftLyftTheme.warmOrange;
      case BookingStatus.confirmed:
        return SwiftLyftTheme.primaryBlue;
      case BookingStatus.driverAssigned:
        return SwiftLyftTheme.secondaryTeal;
      case BookingStatus.driverEnRoute:
        return SwiftLyftTheme.accentPurple;
      case BookingStatus.driverArrived:
        return SwiftLyftTheme.successGreen;
      case BookingStatus.inProgress:
        return SwiftLyftTheme.successGreen;
      case BookingStatus.completed:
        return SwiftLyftTheme.successGreen;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookingDetailsSheet(booking),
    );
  }

  Widget _buildBookingDetailsSheet(Booking booking) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SwiftLyftTheme.mediumGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          booking.statusText,
                          style: const TextStyle(
                            color: SwiftLyftTheme.pureWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'R${booking.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: SwiftLyftTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Trip details
                  _buildDetailSection('Trip Details', [
                    _buildDetailRow('Booking ID', booking.id),
                    _buildDetailRow('Vehicle', booking.vehicleName),
                    _buildDetailRow('Passengers', '${booking.passengerCount} people'),
                    _buildDetailRow('Pickup', booking.pickupAddress),
                    _buildDetailRow('Dropoff', booking.dropoffAddress),
                    _buildDetailRow('Date', DateFormat('EEEE, MMMM dd, yyyy').format(booking.pickupTime)),
                    _buildDetailRow('Time', DateFormat('HH:mm').format(booking.pickupTime)),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Payment details
                  _buildDetailSection('Payment Details', [
                    if (booking.pricing != null) ...[
                      if (booking.pricing!['baseFare'] != null)
                        _buildDetailRow('Base Fare', 'R${(booking.pricing!['baseFare'] as num).toStringAsFixed(2)}'),
                      if (booking.pricing!['distanceFare'] != null)
                        _buildDetailRow('Distance Fare', 'R${(booking.pricing!['distanceFare'] as num).toStringAsFixed(2)}'),
                      if (booking.pricing!['timeFare'] != null)
                        _buildDetailRow('Time Fare', 'R${(booking.pricing!['timeFare'] as num).toStringAsFixed(2)}'),
                      if (booking.pricing!['serviceFee'] != null && (booking.pricing!['serviceFee'] as num) > 0)
                        _buildDetailRow('Service Fee', 'R${(booking.pricing!['serviceFee'] as num).toStringAsFixed(2)}'),
                      if (booking.pricing!['taxes'] != null)
                        _buildDetailRow('Taxes (VAT)', 'R${(booking.pricing!['taxes'] as num).toStringAsFixed(2)}'),
                      if (booking.pricing!['discount'] != null && (booking.pricing!['discount'] as num) > 0)
                        _buildDetailRow('Discount', '-R${(booking.pricing!['discount'] as num).toStringAsFixed(2)}'),
                      const Divider(),
                    ] else ...[
                      _buildDetailRow('Base Price', 'R${booking.basePrice.toStringAsFixed(2)}'),
                    ],
                    _buildDetailRow('Final Price', 'R${booking.finalPrice.toStringAsFixed(2)}'),
                    _buildDetailRow('Payment Status', booking.paymentStatusText),
                    if (booking.closeProtectionOfficer)
                      _buildDetailRow('Close Protection', 'R500.00'),
                  ]),
                  
                  if (booking.specialNotes != null && booking.specialNotes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDetailSection('Special Notes', [
                      _buildDetailRow('Notes', booking.specialNotes!),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SwiftLyftTheme.deepCharcoal,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _confirmCancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text('Are you sure you want to cancel this booking?\n\n${booking.vehicleName}\n${booking.pickupAddress} → ${booking.dropoffAddress}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: SwiftLyftTheme.pureWhite,
            ),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      final queueProvider = Provider.of<TripHistoryQueueProvider>(context, listen: false);

      // Optimistically update the booking status to cancelled
      final updatedBooking = booking.copyWith(status: BookingStatus.cancelled);
      appState.bookings.updateBookingLocally(updatedBooking);

      // Add to queue for backend processing
      queueProvider.enqueue(
        bookingId: booking.id,
        operation: TripQueueOperation.cancelBooking,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled!'),
          backgroundColor: SwiftLyftTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeleteBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete booking?'),
        content: Text('Are you sure you want to permanently delete this cancelled booking?\n\n${booking.vehicleName}\n${booking.pickupAddress} → ${booking.dropoffAddress}\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: SwiftLyftTheme.pureWhite,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      final queueProvider = Provider.of<TripHistoryQueueProvider>(context, listen: false);
      
      // Add to queue instead of direct deletion
      queueProvider.enqueue(
        bookingId: booking.id,
        operation: TripQueueOperation.deleteBooking,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deletion queued. Processing...'),
          backgroundColor: SwiftLyftTheme.warmOrange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markBookingAsCompleted(Booking booking) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final queueProvider = Provider.of<TripHistoryQueueProvider>(context, listen: false);

    // Optimistically update the booking status to completed
    final updatedBooking = booking.copyWith(status: BookingStatus.completed);
    appState.bookings.updateBookingLocally(updatedBooking);

    // Add to queue for backend processing
    queueProvider.enqueue(
      bookingId: booking.id,
      operation: TripQueueOperation.markComplete,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip marked as completed!'),
        backgroundColor: SwiftLyftTheme.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  
  Future<void> _processPayment(Booking booking) async {
    // Show payment dialog
    final paymentResult = await showPaymentDialog(context, booking);

    if (paymentResult.success && mounted) {
      // Only refresh from server if it wasn't a local payment
      if (!paymentResult.isLocalPayment) {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.loadBookings(page: 1, reset: true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Payment processed successfully!'),
            ],
          ),
          backgroundColor: SwiftLyftTheme.successGreen,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }


  /// Build queue status indicator
  Widget _buildQueueIndicator() {
    return Consumer<TripHistoryQueueProvider>(
      builder: (context, queueProvider, child) {
        if (queueProvider.isEmpty && !queueProvider.isProcessing) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.primaryBlue,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (queueProvider.isProcessing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(SwiftLyftTheme.pureWhite),
                    ),
                  )
                else
                  const Icon(
                    Icons.queue,
                    color: SwiftLyftTheme.pureWhite,
                    size: 16,
                  ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      queueProvider.isProcessing
                          ? 'Processing...'
                          : 'Queue: ${queueProvider.pendingCount}',
                      style: const TextStyle(
                        color: SwiftLyftTheme.pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (queueProvider.processingItems.isNotEmpty)
                      Text(
                        '${queueProvider.processingItems.length} active',
                        style: TextStyle(
                          color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 