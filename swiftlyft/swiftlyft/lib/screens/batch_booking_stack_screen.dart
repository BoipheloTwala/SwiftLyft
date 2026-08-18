import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/batch_booking_stack_provider.dart';
import '../providers/app_state.dart';
import '../models/batch_booking_stack_item.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';

/// Screen for managing batch booking stack for corporate users
/// Allows adding vehicles to stack and creating batch bookings from them
class BatchBookingStackScreen extends StatelessWidget {
  const BatchBookingStackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BatchBookingStackProvider, AppState>(
      builder: (context, stackProvider, appState, child) {
        // Check if user has corporate account
        if (appState.corporateInfo == null) {
          return UnifiedNavigation.buildScaffold(
            context: context,
            currentRoute: AppRoutes.batchBookingStack,
            appBar: UnifiedAppBar.buildResponsive(
              context: context,
              title: 'Fleet Selection',
              subtitle: 'Corporate users only',
              showBackButton: true,
            ),
            body: _buildNoCorporateAccount(context),
          );
        }

        return UnifiedNavigation.buildScaffold(
          context: context,
          currentRoute: AppRoutes.batchBookingStack,
          appBar: UnifiedAppBar.buildResponsive(
            context: context,
            title: 'Fleet Selection',
            subtitle: 'Select vehicles for corporate booking',
            showBackButton: true,
            actions: [
              if (!stackProvider.isEmpty)
                TextButton.icon(
                  onPressed: () => _showClearDialog(context, stackProvider),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: SwiftLyftTheme.errorRed,
                  ),
                ),
            ],
          ),
          body: stackProvider.isEmpty
              ? _buildEmptyState(context)
              : _buildStackList(context, stackProvider, appState),
        );
      },
    );
  }

  Widget _buildNoCorporateAccount(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 80,
              color: SwiftLyftTheme.mediumGray.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Corporate Account Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SwiftLyftTheme.deepCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Fleet selection is available for corporate accounts only.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: SwiftLyftTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_outlined,
            size: 80,
            color: SwiftLyftTheme.mediumGray.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your fleet selection is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add vehicles from the vehicle listing to create batch bookings.',
            style: TextStyle(
              fontSize: 14,
              color: SwiftLyftTheme.mediumGray.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.vehicleListing);
            },
            icon: const Icon(Icons.search),
            label: const Text('Browse Vehicles'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackList(
    BuildContext context,
    BatchBookingStackProvider stackProvider,
    AppState appState,
  ) {
    return Column(
      children: [
        // Stack summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                SwiftLyftTheme.accentPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Text(
                  '${stackProvider.count}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SwiftLyftTheme.primaryBlue,
                  ),
                ),
                const Text(
                  'Vehicles Selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: SwiftLyftTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stack items list (LIFO - last added appears first)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stackProvider.count,
            itemBuilder: (context, index) {
              // Reverse order to show most recent first
              final reversedIndex = stackProvider.count - 1 - index;
              final item = stackProvider.stack[reversedIndex];
              return _buildStackItem(context, item, stackProvider, reversedIndex);
            },
          ),
        ),

        // Create batch booking button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SwiftLyftTheme.pureWhite,
            boxShadow: [
              BoxShadow(
                color: SwiftLyftTheme.deepCharcoal.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _createBatchBooking(context, stackProvider, appState),
                  icon: const Icon(Icons.add_business),
                  label: Text('Create Corporate Booking (${stackProvider.count} vehicles)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: SwiftLyftTheme.accentPurple,
                    foregroundColor: SwiftLyftTheme.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStackItem(
    BuildContext context,
    BatchBookingStackItem item,
    BatchBookingStackProvider stackProvider,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Stack position indicator (LIFO - top of stack)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: index == stackProvider.count - 1
                    ? SwiftLyftTheme.primaryBlue.withOpacity(0.2)
                    : SwiftLyftTheme.lightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: index == stackProvider.count - 1
                        ? SwiftLyftTheme.primaryBlue
                        : SwiftLyftTheme.mediumGray,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Vehicle icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car,
                color: SwiftLyftTheme.primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Vehicle details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.vehicleName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.vehicleCategory,
                    style: TextStyle(
                      fontSize: 14,
                      color: SwiftLyftTheme.mediumGray,
                    ),
                  ),
                  if (item.city != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.city!,
                      style: TextStyle(
                        fontSize: 12,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Price and actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R${item.displayPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SwiftLyftTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => stackProvider.removeFromStack(item.vehicleId),
                  icon: const Icon(Icons.delete_outline),
                  color: SwiftLyftTheme.errorRed,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, BatchBookingStackProvider stackProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Fleet Selection'),
        content: Text(
          'Are you sure you want to remove all ${stackProvider.count} vehicles from your fleet selection?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              stackProvider.clearStack();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: SwiftLyftTheme.errorRed,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _createBatchBooking(
    BuildContext context,
    BatchBookingStackProvider stackProvider,
    AppState appState,
  ) {
    // Navigate to bulk bookings screen with stack items
    // The screen will detect the 'fromStack' flag and open the dialog automatically
    Navigator.pushNamed(
      context,
      AppRoutes.bulkBookings,
      arguments: {
        'fromStack': true,
      },
    );
  }
}

