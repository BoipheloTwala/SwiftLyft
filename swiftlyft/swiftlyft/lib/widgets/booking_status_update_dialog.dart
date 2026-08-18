import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../providers/app_state.dart';
import '../utils/booking_status_helper.dart';
import '../utils/theme.dart';

class BookingStatusUpdateDialog extends StatefulWidget {
  final Booking booking;
  final Function(Booking updatedBooking)? onStatusUpdated;

  const BookingStatusUpdateDialog({
    super.key,
    required this.booking,
    this.onStatusUpdated,
  });

  @override
  State<BookingStatusUpdateDialog> createState() => _BookingStatusUpdateDialogState();
}

class _BookingStatusUpdateDialogState extends State<BookingStatusUpdateDialog> {
  BookingStatus? _selectedStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) {
      _showErrorSnackBar('Please select a new status');
      return;
    }

    if (_selectedStatus == widget.booking.status) {
      _showErrorSnackBar('Selected status is the same as current status');
      return;
    }

    // Validate transition
    if (!BookingStatusHelper.isValidTransition(
      widget.booking.status,
      _selectedStatus!,
    )) {
      _showErrorSnackBar(
        'Cannot change status from ${widget.booking.statusText} to ${BookingStatusHelper._getStatusDisplayName(_selectedStatus!)}',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      final updatedBooking = await appState.updateBookingStatus(
        widget.booking.id,
        BookingStatusHelper.statusToString(_selectedStatus!),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        // Call callback if provided
        widget.onStatusUpdated?.call(updatedBooking);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Status updated to ${updatedBooking.statusText}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Close dialog
        Navigator.of(context).pop(updatedBooking);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update status: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowedStatuses = BookingStatusHelper.getAllowedNextStatuses(
      widget.booking.status,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: SwiftLyftTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Booking Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking ID: ${widget.booking.id.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 13,
                          color: SwiftLyftTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: SwiftLyftTheme.mediumGray,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Current Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  BookingStatusHelper.getStatusBadge(
                    widget.booking.status,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status Selection
            if (allowedStatuses.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No status changes available for ${widget.booking.statusText} bookings',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Select New Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...allowedStatuses.map((status) => _buildStatusOption(status)),
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any additional notes about this status change...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                if (allowedStatuses.isNotEmpty)
                  ElevatedButton(
                    onPressed: _isLoading || _selectedStatus == null ? null : _updateStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SwiftLyftTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Update Status',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(BookingStatus status) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? BookingStatusHelper.getStatusColor(status).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BookingStatusHelper.getStatusColor(status)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BookingStatusHelper.getStatusColor(status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                BookingStatusHelper.getStatusIcon(status),
                color: BookingStatusHelper.getStatusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BookingStatusHelper._getStatusDisplayName(status),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? BookingStatusHelper.getStatusColor(status)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    BookingStatusHelper.getStatusDescription(status),
                    style: TextStyle(
                      fontSize: 13,
                      color: SwiftLyftTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: BookingStatusHelper.getStatusColor(status),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Show status update dialog
Future<Booking?> showBookingStatusUpdateDialog({
  required BuildContext context,
  required Booking booking,
  Function(Booking updatedBooking)? onStatusUpdated,
}) {
  return showDialog<Booking>(
    context: context,
    builder: (context) => BookingStatusUpdateDialog(
      booking: booking,
      onStatusUpdated: onStatusUpdated,
    ),
  );
}

