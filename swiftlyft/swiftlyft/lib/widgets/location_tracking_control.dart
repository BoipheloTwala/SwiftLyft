import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_location_state.dart';
import '../utils/theme.dart';

/// Widget for controlling driver location tracking
class LocationTrackingControl extends StatefulWidget {
  final bool showStatistics;
  final bool showMap;

  const LocationTrackingControl({
    super.key,
    this.showStatistics = true,
    this.showMap = false,
  });

  @override
  State<LocationTrackingControl> createState() => _LocationTrackingControlState();
}

class _LocationTrackingControlState extends State<LocationTrackingControl> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DriverLocationState>(
      builder: (context, locationState, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(locationState),
                const SizedBox(height: 16),
                _buildStatusIndicator(locationState),
                const SizedBox(height: 16),
                _buildControls(locationState),
                if (locationState.error != null) ...[
                  const SizedBox(height: 12),
                  _buildError(locationState.error!),
                ],
                if (widget.showStatistics) ...[
                  const Divider(height: 24),
                  _buildStatistics(locationState),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(DriverLocationState locationState) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: locationState.isTracking
                ? Colors.green.shade50
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.my_location,
            color: locationState.isTracking
                ? Colors.green.shade700
                : Colors.grey.shade600,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                locationState.isTracking ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 14,
                  color: locationState.isTracking
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (locationState.isTracking)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(DriverLocationState locationState) {
    final location = locationState.currentLocation;
    
    if (location == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No location available',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Current Location',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.gps_fixed,
                  label: 'Lat',
                  value: location.latLng.latitude.toStringAsFixed(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.gps_fixed,
                  label: 'Lng',
                  value: location.latLng.longitude.toStringAsFixed(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.speed,
                  label: 'Speed',
                  value: location.speed != null
                      ? '${(location.speed! * 3.6).toStringAsFixed(0)} km/h'
                      : 'N/A',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.center_focus_strong,
                  label: 'Accuracy',
                  value: '${location.accuracy.toStringAsFixed(0)}m',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade600),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(DriverLocationState locationState) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: locationState.isTracking
                ? () => locationState.stopTracking()
                : () => locationState.startTracking(),
            icon: Icon(
              locationState.isTracking ? Icons.stop : Icons.play_arrow,
            ),
            label: Text(
              locationState.isTracking ? 'Stop Tracking' : 'Start Tracking',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: locationState.isTracking
                  ? Colors.red
                  : SwiftLyftTheme.successGreen,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            await locationState.getCurrentLocation();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location refreshed'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(DriverLocationState locationState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.upload,
                label: 'Updates Sent',
                value: locationState.updatesSent.toString(),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.error_outline,
                label: 'Failed',
                value: locationState.updatesFailed.toString(),
                color: Colors.red,
              ),
            ),
          ],
        ),
        if (locationState.lastUpdateTime != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last update: ${_formatTime(locationState.lastUpdateTime!)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}

/// Compact location tracking toggle
class LocationTrackingToggle extends StatelessWidget {
  const LocationTrackingToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverLocationState>(
      builder: (context, locationState, child) {
        return SwitchListTile(
          title: const Text('Location Tracking'),
          subtitle: Text(
            locationState.isTracking
                ? 'Sharing your location'
                : 'Not sharing location',
          ),
          value: locationState.isTracking,
          onChanged: (value) {
            if (value) {
              locationState.startTracking();
            } else {
              locationState.stopTracking();
            }
          },
          secondary: Icon(
            Icons.my_location,
            color: locationState.isTracking ? Colors.green : Colors.grey,
          ),
        );
      },
    );
  }
}

