import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_location_state.dart';
import '../widgets/location_tracking_control.dart';
import '../widgets/unified_navigation.dart';

/// Screen for driver location control and visualization
class DriverLocationScreen extends StatefulWidget {
  const DriverLocationScreen({super.key});

  @override
  State<DriverLocationScreen> createState() => _DriverLocationScreenState();
}

class _DriverLocationScreenState extends State<DriverLocationScreen> {
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: '/driver-location',
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Location Tracking',
        subtitle: 'Manage your location sharing',
        showBackButton: true,
      ),
      body: Consumer<DriverLocationState>(
        builder: (context, locationState, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Location info card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            locationState.currentLocation != null
                                ? Icons.location_on
                                : Icons.location_off,
                            size: 32,
                            color: locationState.currentLocation != null
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locationState.currentLocation != null
                                      ? 'Location Active'
                                      : 'No Location',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  locationState.currentLocation != null
                                      ? 'Tracking your location'
                                      : 'Start tracking to see your location',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (locationState.currentLocation != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildLocationDetail(
                          'Latitude',
                          locationState.currentLocation!.latLng.latitude.toStringAsFixed(6),
                        ),
                        const SizedBox(height: 8),
                        _buildLocationDetail(
                          'Longitude',
                          locationState.currentLocation!.latLng.longitude.toStringAsFixed(6),
                        ),
                      ],
                    ],
                  ),
                ),

                // Location tracking control
                const LocationTrackingControl(
                  showStatistics: true,
                ),

                // Additional options
                _buildOptions(locationState),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(DriverLocationState locationState) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Location Settings'),
            subtitle: const Text('Manage location permissions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showSettingsDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Location History'),
            subtitle: const Text('View your location updates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showHistoryDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Statistics'),
            subtitle: const Text('Clear update counters'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showResetDialog(locationState);
            },
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location tracking settings:'),
            SizedBox(height: 12),
            Text('• Updates every 10 meters'),
            Text('• High accuracy GPS'),
            Text('• Automatic throttling'),
            SizedBox(height: 12),
            Text(
              'To change permissions, go to your device settings.',
              style: TextStyle(fontSize: 13),
            ),
          ],
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

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location History'),
        content: const Text(
          'Location history tracking is coming soon. '
          'You\'ll be able to view all your past location updates here.',
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

  void _showResetDialog(DriverLocationState locationState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Statistics'),
        content: const Text(
          'Are you sure you want to reset all location update statistics?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              locationState.resetStatistics();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statistics reset successfully'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

