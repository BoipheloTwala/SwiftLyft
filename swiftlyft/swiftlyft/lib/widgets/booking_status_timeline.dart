import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/booking_status_helper.dart';
import '../utils/theme.dart';

class BookingStatusTimeline extends StatelessWidget {
  final Booking booking;
  final bool showAll;

  const BookingStatusTimeline({
    super.key,
    required this.booking,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusList = _getStatusList();

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
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: SwiftLyftTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Booking Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                BookingStatusHelper.getStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 24),
            ...statusList.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isLast = index == statusList.length - 1;
              final isCurrent = status == booking.status;
              final isPast = _isStatusPast(status);
              final isFuture = !isCurrent && !isPast;

              return _TimelineItem(
                status: status,
                isLast: isLast,
                isCurrent: isCurrent,
                isPast: isPast,
                isFuture: isFuture,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<BookingStatus> _getStatusList() {
    if (booking.status == BookingStatus.cancelled) {
      // Show path up to cancellation
      return [
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.cancelled,
      ];
    }

    if (showAll || booking.status == BookingStatus.completed) {
      // Show full journey
      return [
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.driverAssigned,
        BookingStatus.driverEnRoute,
        BookingStatus.driverArrived,
        BookingStatus.inProgress,
        BookingStatus.completed,
      ];
    }

    // Show up to current status + next possible status
    final statuses = [
      BookingStatus.pending,
      BookingStatus.confirmed,
      BookingStatus.driverAssigned,
      BookingStatus.driverEnRoute,
      BookingStatus.driverArrived,
      BookingStatus.inProgress,
      BookingStatus.completed,
    ];

    final currentIndex = statuses.indexOf(booking.status);
    if (currentIndex == -1) return statuses;

    // Return statuses up to current + 1 (if exists)
    return statuses.sublist(0, (currentIndex + 2).clamp(0, statuses.length));
  }

  bool _isStatusPast(BookingStatus status) {
    final statuses = [
      BookingStatus.pending,
      BookingStatus.confirmed,
      BookingStatus.driverAssigned,
      BookingStatus.driverEnRoute,
      BookingStatus.driverArrived,
      BookingStatus.inProgress,
      BookingStatus.completed,
    ];

    final statusIndex = statuses.indexOf(status);
    final currentIndex = statuses.indexOf(booking.status);

    if (statusIndex == -1 || currentIndex == -1) return false;

    return statusIndex < currentIndex;
  }
}

class _TimelineItem extends StatelessWidget {
  final BookingStatus status;
  final bool isLast;
  final bool isCurrent;
  final bool isPast;
  final bool isFuture;

  const _TimelineItem({
    required this.status,
    required this.isLast,
    required this.isCurrent,
    required this.isPast,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent || isPast
        ? BookingStatusHelper.getStatusColor(status)
        : Colors.grey[400]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            // Circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrent || isPast ? color : Colors.white,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPast
                    ? Icons.check
                    : isCurrent
                        ? BookingStatusHelper.getStatusIcon(status)
                        : BookingStatusHelper.getStatusIcon(status),
                size: 16,
                color: isCurrent || isPast ? Colors.white : Colors.grey[400],
              ),
            ),
            // Line
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isPast ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BookingStatusHelper._getStatusDisplayName(status),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    color: isCurrent || isPast ? color : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BookingStatusHelper.getStatusDescription(status),
                  style: TextStyle(
                    fontSize: 13,
                    color: isCurrent || isPast
                        ? SwiftLyftTheme.mediumGray
                        : Colors.grey[500],
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Extension to make the helper method accessible
extension _StatusNameExtension on BookingStatusHelper {
  static String _getStatusDisplayName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.driverAssigned:
        return 'Driver Assigned';
      case BookingStatus.driverEnRoute:
        return 'En Route';
      case BookingStatus.driverArrived:
        return 'Driver Arrived';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

