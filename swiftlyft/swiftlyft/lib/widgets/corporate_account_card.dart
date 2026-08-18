import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/corporate.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';

/// Widget to display corporate account information
class CorporateAccountCard extends StatelessWidget {
  const CorporateAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoadingCorporate) {
          return const _LoadingCard();
        }

        // Try to get corporate info from API first
        CorporateInfo? corporate = appState.corporateInfo;
        
        // Fallback: if API hasn't loaded yet, construct from User object
        if (corporate == null && appState.currentUser?.corporateAccount != null) {
          corporate = CorporateInfo(
            corporateAccount: appState.currentUser!.corporateAccount!,
            bulkBookings: appState.currentUser!.bulkBookings,
          );
        }

        if (corporate == null) {
          return const SizedBox.shrink(); // Don't show anything if no corporate account
        }

        return _CorporateInfoCard(corporateInfo: corporate);
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: const Row(
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading corporate account...'),
        ],
      ),
    );
  }
}

class _CorporateInfoCard extends StatelessWidget {
  final CorporateInfo corporateInfo;

  const _CorporateInfoCard({required this.corporateInfo});

  @override
  Widget build(BuildContext context) {
    final account = corporateInfo.corporateAccount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.business,
                color: SwiftLyftTheme.warmOrange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.companyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusChip(status: account.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Account Details
          _InfoRow(
            icon: Icons.email,
            label: 'Company Email',
            value: account.companyEmail,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person,
            label: 'Contact Person',
            value: account.contactPerson,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.phone,
            label: 'Contact Phone',
            value: account.contactPhone,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Discount
          if (account.discountPercentage > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SwiftLyftTheme.warmOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.discount,
                    color: SwiftLyftTheme.warmOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Corporate Discount: ${account.discountPercentage}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.warmOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Manage Bulk Bookings Button
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.bulkBookings);
              },
              icon: const Icon(Icons.business_center, size: 20),
              label: const Text('Manage Bulk Bookings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SwiftLyftTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'active':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        displayText = 'Active';
        break;
      case 'suspended':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        displayText = 'Suspended';
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        displayText = 'Pending';
        break;
      default:
        backgroundColor = SwiftLyftTheme.lightGray;
        textColor = SwiftLyftTheme.mediumGray;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: SwiftLyftTheme.mediumGray,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: SwiftLyftTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

