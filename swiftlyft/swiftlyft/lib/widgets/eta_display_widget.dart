import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/eta_state.dart';
import '../services/eta_calculation_service.dart';

/// Full ETA display card with detailed information
class ETADisplayCard extends StatelessWidget {
  final bool showDetails;
  final bool showProgress;

  const ETADisplayCard({
    super.key,
    this.showDetails = true,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ETAState>(
      builder: (context, etaState, child) {
        if (etaState.currentETA == null) {
          return _buildNoETACard();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildETAHeader(etaState),
                if (showProgress && etaState.getProgressPercentage() != null) ...[
                  const SizedBox(height: 16),
                  _buildProgressBar(etaState),
                ],
                if (showDetails) ...[
                  const Divider(height: 24),
                  _buildETADetails(etaState),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoETACard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Text(
              'ETA calculating...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildETAHeader(ETAState etaState) {
    final eta = etaState.currentETA!;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.schedule,
            color: Colors.blue.shade700,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eta.formattedETA,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Estimated arrival: ${_formatArrivalTime(eta.arrivalTime)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        _buildConfidenceBadge(eta.confidence),
      ],
    );
  }

  Widget _buildConfidenceBadge(ETAConfidence confidence) {
    Color color;
    switch (confidence.level) {
      case 'high':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${confidence.percentage}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ETAState etaState) {
    final progress = etaState.getProgressPercentage()! / 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trip Progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress < 0.5 ? Colors.blue : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildETADetails(ETAState etaState) {
    final eta = etaState.currentETA!;
    
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.route,
          label: 'Distance',
          value: '${eta.distance.toStringAsFixed(1)} km',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          icon: Icons.speed,
          label: 'Avg Speed',
          value: '${eta.averageSpeed.toStringAsFixed(0)} km/h',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          icon: Icons.traffic,
          label: 'Traffic',
          value: _formatTraffic(eta.trafficCondition),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          icon: Icons.access_time_filled,
          label: 'Range',
          value: eta.formattedRange,
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatArrivalTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  String _formatTraffic(String condition) {
    switch (condition) {
      case 'none':
        return 'Clear';
      case 'light':
        return 'Light';
      case 'moderate':
        return 'Moderate';
      case 'heavy':
        return 'Heavy';
      case 'severe':
        return 'Severe';
      default:
        return 'Unknown';
    }
  }
}

/// Compact ETA badge
class ETABadge extends StatelessWidget {
  final bool showIcon;

  const ETABadge({
    super.key,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ETAState>(
      builder: (context, etaState, child) {
        if (etaState.currentETA == null) {
          return const SizedBox.shrink();
        }

        final eta = etaState.currentETA!;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
              ],
              Text(
                eta.formattedETA,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Arrival time countdown
class ArrivalCountdown extends StatefulWidget {
  const ArrivalCountdown({super.key});

  @override
  State<ArrivalCountdown> createState() => _ArrivalCountdownState();
}

class _ArrivalCountdownState extends State<ArrivalCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ETAState>(
      builder: (context, etaState, child) {
        final timeUntil = etaState.getTimeUntilArrival();
        
        if (timeUntil == null) {
          return const SizedBox.shrink();
        }

        final minutes = timeUntil.inMinutes;
        final seconds = timeUntil.inSeconds % 60;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getCountdownColor(minutes),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.alarm,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$minutes:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'until arrival',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getCountdownColor(int minutes) {
    if (minutes <= 2) {
      return Colors.red;
    } else if (minutes <= 5) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}

/// ETA status indicator
class ETAStatusIndicator extends StatelessWidget {
  const ETAStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ETAState>(
      builder: (context, etaState, child) {
        if (!etaState.hasValidETA) {
          return _buildIndicator(
            icon: Icons.schedule,
            label: 'Calculating...',
            color: Colors.grey,
          );
        }

        final isClose = etaState.isCloseToDestination();
        if (isClose) {
          return _buildIndicator(
            icon: Icons.location_on,
            label: 'Arriving',
            color: Colors.green,
          );
        }

        final eta = etaState.currentETA!;
        if (eta.etaMinutes <= 2) {
          return _buildIndicator(
            icon: Icons.access_time_filled,
            label: 'Almost there',
            color: Colors.orange,
          );
        }

        return _buildIndicator(
          icon: Icons.directions_car,
          label: 'On the way',
          color: Colors.blue,
        );
      },
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

