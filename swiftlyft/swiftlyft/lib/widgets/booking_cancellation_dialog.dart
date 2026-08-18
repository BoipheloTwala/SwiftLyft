import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../providers/app_state.dart';
import '../utils/cancellation_helper.dart';
import '../utils/theme.dart';

class BookingCancellationDialog extends StatefulWidget {
  final Booking booking;
  final Function(bool cancelled)? onCancelled;

  const BookingCancellationDialog({
    super.key,
    required this.booking,
    this.onCancelled,
  });

  @override
  State<BookingCancellationDialog> createState() => _BookingCancellationDialogState();
}

class _BookingCancellationDialogState extends State<BookingCancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  late Map<String, dynamic> _feeInfo;

  @override
  void initState() {
    super.initState();
    _feeInfo = CancellationHelper.calculateCancellationFee(widget.booking);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirmCancellation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      final success = await appState.cancelBooking(widget.booking.id);

      if (success && mounted) {
        widget.onCancelled?.call(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Booking cancelled. ${_feeInfo['feeAmount'] > 0 ? 'Refund: R${_feeInfo['refundAmount'].toStringAsFixed(2)}' : 'Full refund issued'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.of(context).pop(true);
      } else {
        _showError('Failed to cancel booking');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: SwiftLyftTheme.errorRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feeAmount = _feeInfo['feeAmount'] as double;
    final refundAmount = _feeInfo['refundAmount'] as double;
    final hoursUntilTrip = _feeInfo['hoursUntilTrip'] as double;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Cancel Booking?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'ID: ${widget.booking.id.substring(0, 8)}...',
              style: TextStyle(
                fontSize: 14,
                color: SwiftLyftTheme.mediumGray,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Time until trip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time until pickup',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          CancellationHelper.getTimeUntilTrip(widget.booking.pickupTime),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fee Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: feeAmount > 0
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: feeAmount > 0 ? Colors.orange : Colors.green,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Booking Total',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'R ${widget.booking.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  if (feeAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Cancellation Fee',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${(_feeInfo['feePercentage'] * 100).toInt()}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: SwiftLyftTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '- R ${feeAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const Divider(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Refund Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'R ${refundAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: feeAmount > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fee description
            Text(
              _feeInfo['feeDescription'],
              style: TextStyle(
                fontSize: 13,
                color: SwiftLyftTheme.mediumGray,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Reason (optional)
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                hintText: 'e.g., Change of plans, Emergency, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              enabled: !_isLoading,
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Keep Booking'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmCancellation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            'Cancel Booking',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Policy info
            TextButton.icon(
              onPressed: () => _showPolicyDialog(),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text(
                'View Cancellation Policy',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancellation Policy'),
        content: SingleChildScrollView(
          child: Text(CancellationHelper.getCancellationPolicy()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Show booking cancellation dialog
Future<bool?> showBookingCancellationDialog({
  required BuildContext context,
  required Booking booking,
  Function(bool cancelled)? onCancelled,
}) {
  // Check if can cancel
  if (!CancellationHelper.canCancelBooking(booking)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cannot cancel ${booking.statusText} booking',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: SwiftLyftTheme.errorRed,
      ),
    );
    return Future.value(false);
  }

  return showDialog<bool>(
    context: context,
    builder: (context) => BookingCancellationDialog(
      booking: booking,
      onCancelled: onCancelled,
    ),
  );
}

