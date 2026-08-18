import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../utils/quote_status_helper.dart';

/// Panel for managing selected quotes with bulk actions
class QuoteManagementPanel extends StatelessWidget {
  final List<Quote> selectedQuotes;
  final VoidCallback onCancelSelection;
  final Function(List<Quote>) onBulkCancel;
  final Function(List<Quote>) onBulkExport;

  const QuoteManagementPanel({
    super.key,
    required this.selectedQuotes,
    required this.onCancelSelection,
    required this.onBulkCancel,
    required this.onBulkExport,
  });

  @override
  Widget build(BuildContext context) {
    final cancellableCount = selectedQuotes.where((q) =>
      QuoteStatusHelper.canCancel(q.status)).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          top: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Row(
        children: [
          // Selection count
          Expanded(
            child: Text(
              '${selectedQuotes.length} quote${selectedQuotes.length != 1 ? 's' : ''} selected',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          
          // Actions
          if (cancellableCount > 0)
            TextButton.icon(
              onPressed: () => _confirmBulkCancel(context),
              icon: const Icon(Icons.cancel, size: 20),
              label: Text('Cancel ($cancellableCount)'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
              ),
            ),
          
          const SizedBox(width: 8),
          
          TextButton.icon(
            onPressed: () => onBulkExport(selectedQuotes),
            icon: const Icon(Icons.file_download, size: 20),
            label: const Text('Export'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade700,
            ),
          ),
          
          const SizedBox(width: 8),
          
          IconButton(
            onPressed: onCancelSelection,
            icon: const Icon(Icons.close),
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBulkCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Quotes'),
        content: Text(
          'Are you sure you want to cancel ${selectedQuotes.where((q) => QuoteStatusHelper.canCancel(q.status)).length} quote(s)?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      onBulkCancel(selectedQuotes.where((q) =>
        QuoteStatusHelper.canCancel(q.status)).toList());
    }
  }
}

/// Summary statistics card for quote history
class QuoteSummaryCard extends StatelessWidget {
  final int totalQuotes;
  final int pendingQuotes;
  final int acceptedQuotes;
  final int expiredQuotes;
  final double totalValue;
  final Function(String? status) onStatusTap;

  const QuoteSummaryCard({
    super.key,
    required this.totalQuotes,
    required this.pendingQuotes,
    required this.acceptedQuotes,
    required this.expiredQuotes,
    required this.totalValue,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quote Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    totalQuotes.toString(),
                    Colors.blue,
                    Icons.receipt_long,
                    () => onStatusTap(null),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    pendingQuotes.toString(),
                    Colors.orange,
                    Icons.hourglass_empty,
                    () => onStatusTap('pending'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Accepted',
                    acceptedQuotes.toString(),
                    Colors.green,
                    Icons.check_circle,
                    () => onStatusTap('accepted'),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Expired',
                    expiredQuotes.toString(),
                    Colors.grey,
                    Icons.event_busy,
                    () => onStatusTap('expired'),
                  ),
                ),
              ],
            ),
            if (totalValue > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Value:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'R${totalValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
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
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

