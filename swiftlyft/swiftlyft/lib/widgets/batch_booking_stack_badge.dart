import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/batch_booking_stack_provider.dart';
import '../utils/theme.dart';

/// Floating badge widget showing batch booking stack count for corporate users
class BatchBookingStackBadge extends StatelessWidget {
  final VoidCallback onTap;

  const BatchBookingStackBadge({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BatchBookingStackProvider>(
      builder: (context, stackProvider, child) {
        if (stackProvider.isEmpty) {
          return const SizedBox.shrink();
        }
        return Positioned(
          bottom: 16,
          right: 16,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SwiftLyftTheme.primaryBlue,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: SwiftLyftTheme.deepCharcoal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.layers,
                    color: SwiftLyftTheme.pureWhite,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                      'Fleet (${stackProvider.count})',
                    style: const TextStyle(
                      color: SwiftLyftTheme.pureWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

