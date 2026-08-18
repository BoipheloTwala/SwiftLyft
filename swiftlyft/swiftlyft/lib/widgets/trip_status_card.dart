import 'package:flutter/material.dart';
import '../models/booking.dart';

/// Card showing current trip status with timeline
class TripStatusCard extends StatelessWidget {
  final Booking booking;
  final int? eta;

  const TripStatusCard({
    super.key,
    required this.booking,
    this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (eta != null) _buildETABadge(),
              ],
            ),
            const SizedBox(height: 20),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final status = booking.status;
    IconData icon;
    Color color;

    if (status == BookingStatus.confirmed || status == BookingStatus.driverAssigned) {
      icon = Icons.person_pin_circle;
      color = Colors.blue;
    } else if (status == BookingStatus.inProgress || status == BookingStatus.driverArrived) {
      icon = Icons.directions_car;
      color = Colors.green;
    } else if (status == BookingStatus.completed) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.schedule;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildETABadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text(
            '$eta min',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final status = booking.status;
    final steps = _getTripSteps();

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted ? Colors.green : Colors.grey.shade300,
                    border: Border.all(
                      color: step.isActive 
                          ? Colors.blue 
                          : (step.isCompleted ? Colors.green : Colors.grey.shade400),
                      width: 2,
                    ),
                  ),
                  child: step.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : step.isActive
                          ? Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: step.isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontWeight: step.isActive ? FontWeight.w600 : FontWeight.normal,
                        color: step.isCompleted || step.isActive
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (step.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<TripStep> _getTripSteps() {
    final status = booking.status;
    
    return [
      TripStep(
        title: 'Booking Confirmed',
        subtitle: 'Looking for a driver',
        isCompleted: true,
        isActive: false,
      ),
      TripStep(
        title: 'Driver Assigned',
        subtitle: booking.driverId.isNotEmpty ? 'Driver on the way' : null,
        isCompleted: status != BookingStatus.confirmed,
        isActive: status == BookingStatus.driverAssigned,
      ),
      TripStep(
        title: 'Driver Arrived',
        subtitle: 'Ready for pickup',
        isCompleted: status == BookingStatus.inProgress || status == BookingStatus.completed,
        isActive: status == BookingStatus.driverArrived,
      ),
      TripStep(
        title: 'Trip in Progress',
        subtitle: 'On the way to destination',
        isCompleted: status == BookingStatus.completed,
        isActive: status == BookingStatus.inProgress,
      ),
      TripStep(
        title: 'Trip Completed',
        subtitle: 'Arrived at destination',
        isCompleted: status == BookingStatus.completed,
        isActive: false,
      ),
    ];
  }

  String _getStatusTitle() {
    final status = booking.status;
    
    switch (status) {
      case BookingStatus.confirmed:
        return 'Finding Driver';
      case BookingStatus.driverAssigned:
        return 'Driver On The Way';
      case BookingStatus.driverArrived:
        return 'Driver Has Arrived';
      case BookingStatus.inProgress:
        return 'Trip in Progress';
      case BookingStatus.completed:
        return 'Trip Completed';
      default:
        return 'Trip Status';
    }
  }

  String _getStatusDescription() {
    final status = booking.status;
    
    switch (status) {
      case BookingStatus.confirmed:
        return 'We are finding the best driver for you';
      case BookingStatus.driverAssigned:
        return 'Your driver is heading to pickup location';
      case BookingStatus.driverArrived:
        return 'Your driver is waiting at the pickup location';
      case BookingStatus.inProgress:
        return 'Enjoy your ride!';
      case BookingStatus.completed:
        return 'Thank you for riding with us';
      default:
        return status.toString().split('.').last;
    }
  }
}

class TripStep {
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isActive;

  TripStep({
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.isActive,
  });
}

