import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../providers/app_state.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications after the first build
    Future.microtask(() => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.markAllNotificationsAsRead();
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final notifications = appState.allNotifications;
        final unreadCount = appState.unreadNotificationCount;
        final isLoading = appState.isLoadingNotifications;
        final error = appState.notificationsError;

        return UnifiedNavigation.buildScaffold(
          context: context,
          currentRoute: AppRoutes.notifications,
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Notifications'),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SwiftLyftTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: SwiftLyftTheme.pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: SwiftLyftTheme.pureWhite,
            foregroundColor: SwiftLyftTheme.deepCharcoal,
            elevation: SwiftLyftTheme.isWeb ? 2 : 0,
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? _buildErrorState(error, appState)
                  : notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(notifications),
        );
      },
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
              itemBuilder: (context, index) {
        return _buildNotificationCard(context, notifications[index]);
              },
    );
  }

  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: SwiftLyftTheme.lightGray,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 60,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll notify you about bookings, offers, and updates',
            style: TextStyle(
              fontSize: 16,
              color: SwiftLyftTheme.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final isRead = notification.isRead;
    final type = notification.type;
    final timestamp = notification.createdAt;
    final timeAgo = _getTimeAgo(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? SwiftLyftTheme.pureWhite : SwiftLyftTheme.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? SwiftLyftTheme.lightGray : SwiftLyftTheme.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
                  decoration: BoxDecoration(
            color: _getNotificationColor(type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
            _getNotificationIcon(type),
            color: _getNotificationColor(type),
                    size: 24,
                  ),
                ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
            color: SwiftLyftTheme.deepCharcoal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 14,
                color: SwiftLyftTheme.mediumGray,
                height: 1.4,
              ),
            ),
                      const SizedBox(height: 8),
                      Text(
              timeAgo,
                        style: const TextStyle(
                fontSize: 12,
                color: SwiftLyftTheme.mediumGray,
                fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: SwiftLyftTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
          onTap: () async {
            // Mark as read and show details
            if (!isRead) {
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.markNotificationAsRead(notification.id);
            }
            _showNotificationDetails(context, notification);
          },
      ),
    );
  }

  Widget _buildErrorState(String error, AppState appState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: SwiftLyftTheme.mediumGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await appState.loadNotifications();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return SwiftLyftTheme.primaryBlue;
      case 'payment':
        return SwiftLyftTheme.successGreen;
      case 'promotion':
        return SwiftLyftTheme.warmOrange;
      case 'driver':
        return SwiftLyftTheme.secondaryTeal;
      case 'alert':
        return Colors.red;
      default:
        return SwiftLyftTheme.mediumGray;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.directions_car_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'driver':
        return Icons.person_rounded;
      case 'alert':
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }


  void _showNotificationDetails(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (notification.data['actionUrl'] != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle action (navigate to specific screen, etc.)
              },
              child: const Text('View Details'),
          ),
        ],
      ),
    );
  } 