import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_preferences_state.dart';
import '../widgets/unified_navigation.dart';

/// Screen for managing notification preferences
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationPreferencesState>(
      builder: (context, prefsState, child) {
        if (prefsState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return UnifiedNavigation.buildScaffold(
          context: context,
          currentRoute: '/notification-settings',
          appBar: UnifiedAppBar.buildResponsive(
            context: context,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            showBackButton: true,
          ),
          body: ListView(
            children: [
              // Master toggle
              _buildMasterToggle(prefsState),
              
              const Divider(height: 1),
              
              // Trip notifications section
              _buildSectionHeader('Trip Notifications'),
              _buildNotificationTile(
                title: 'Driver Assigned',
                subtitle: 'When a driver is assigned to your trip',
                icon: Icons.person_pin_circle,
                value: prefsState.driverAssignedNotifications,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setDriverAssignedNotifications(value)
                    : null,
              ),
              _buildNotificationTile(
                title: 'Driver Arrived',
                subtitle: 'When your driver arrives at pickup location',
                icon: Icons.location_on,
                value: prefsState.driverArrivedNotifications,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setDriverArrivedNotifications(value)
                    : null,
              ),
              _buildNotificationTile(
                title: 'Trip Started',
                subtitle: 'When your trip begins',
                icon: Icons.directions_car,
                value: prefsState.tripStartedNotifications,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setTripStartedNotifications(value)
                    : null,
              ),
              _buildNotificationTile(
                title: 'Trip Completed',
                subtitle: 'When you arrive at your destination',
                icon: Icons.check_circle,
                value: prefsState.tripCompletedNotifications,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setTripCompletedNotifications(value)
                    : null,
              ),
              _buildNotificationTile(
                title: 'ETA Alerts',
                subtitle: 'Real-time arrival time updates',
                icon: Icons.access_time,
                value: prefsState.etaAlertsNotifications,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setEtaAlertsNotifications(value)
                    : null,
              ),
              
              const Divider(height: 1),
              
              // Other notifications section
              _buildSectionHeader('Other Notifications'),
              _buildNotificationTile(
                title: 'Payment Updates',
                subtitle: 'Payment confirmations and receipts',
                icon: Icons.payment,
                value: prefsState.paymentNotifications,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setPaymentNotifications(value)
                    : null,
              ),
              _buildNotificationTile(
                title: 'Promotions & Offers',
                subtitle: 'Special deals and discounts',
                icon: Icons.local_offer,
                value: prefsState.promotionalNotifications,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setPromotionalNotifications(value)
                    : null,
              ),
              
              const Divider(height: 1),
              
              // Notification settings section
              _buildSectionHeader('Notification Settings'),
              _buildNotificationTile(
                title: 'Sound',
                subtitle: 'Play sound for notifications',
                icon: Icons.volume_up,
                value: prefsState.soundEnabled,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setSoundEnabled(value)
                    : null,
              ),
              _buildNotificationTile(
                title: 'Vibration',
                subtitle: 'Vibrate for notifications',
                icon: Icons.vibration,
                value: prefsState.vibrationEnabled,
                onChanged: prefsState.notificationsEnabled
                    ? (value) => prefsState.setVibrationEnabled(value)
                    : null,
              ),
              
              const Divider(height: 1),
              
              // Quick actions
              _buildSectionHeader('Quick Actions'),
              _buildActionTile(
                title: 'Enable All Trip Notifications',
                icon: Icons.notifications_active,
                onTap: () => prefsState.enableAllTripNotifications(),
              ),
              _buildActionTile(
                title: 'Disable All Trip Notifications',
                icon: Icons.notifications_off,
                onTap: () => prefsState.disableAllTripNotifications(),
              ),
              _buildActionTile(
                title: 'Reset to Defaults',
                icon: Icons.restore,
                onTap: () => _showResetDialog(context, prefsState),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMasterToggle(NotificationPreferencesState prefsState) {
    return Container(
      color: prefsState.notificationsEnabled
          ? Colors.green.shade50
          : Colors.grey.shade50,
      child: SwitchListTile(
        title: Text(
          'Enable Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: prefsState.notificationsEnabled
                ? Colors.green.shade900
                : Colors.grey.shade700,
          ),
        ),
        subtitle: Text(
          prefsState.notificationsEnabled
              ? 'Notifications are enabled'
              : 'Notifications are disabled',
          style: TextStyle(
            color: prefsState.notificationsEnabled
                ? Colors.green.shade700
                : Colors.grey.shade600,
          ),
        ),
        value: prefsState.notificationsEnabled,
        onChanged: (value) => prefsState.setNotificationsEnabled(value),
        secondary: Icon(
          prefsState.notificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: prefsState.notificationsEnabled
              ? Colors.green.shade700
              : Colors.grey.shade600,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required void Function(bool)? onChanged,
  }) {
    final isEnabled = onChanged != null;
    
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isEnabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      secondary: Icon(
        icon,
        color: isEnabled
            ? (value ? Colors.blue.shade600 : Colors.grey.shade400)
            : Colors.grey.shade300,
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade600),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showResetDialog(BuildContext context, NotificationPreferencesState prefsState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all notification preferences to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              prefsState.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification preferences reset to defaults'),
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

