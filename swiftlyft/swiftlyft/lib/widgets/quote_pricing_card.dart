import 'package:flutter/material.dart';
import '../utils/quote_pricing_helper.dart';

/// Widget to display quote pricing breakdown
class QuotePricingCard extends StatelessWidget {
  final Map<String, dynamic>? pricingData;
  final double? distance;
  final int? duration;
  final bool isLoading;
  final String? error;

  const QuotePricingCard({
    super.key,
    this.pricingData,
    this.distance,
    this.duration,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Price Estimate',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Loading state
            if (isLoading) _buildLoadingState(),
            
            // Error state
            if (error != null && !isLoading) _buildErrorState(context),
            
            // Success state with pricing
            if (pricingData != null && !isLoading && error == null)
              _buildPricingDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Calculating price...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error ?? 'Unable to calculate price',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingDetails(BuildContext context) {
    final breakdown = QuotePricingHelper.getPricingBreakdown(pricingData!);
    final total = pricingData!['total'] ?? 0.0;
    final currency = pricingData!['currency'] ?? 'ZAR';
    
    return Column(
      children: [
        // Trip details
        if (distance != null || duration != null) ...[
          _buildTripDetails(),
          const Divider(height: 24),
        ],
        
        // Price breakdown
        ...breakdown.map((item) => _buildPriceItem(
          context,
          item['label'] as String,
          item['amount'] as num,
          isSubtotal: false,
        )),
        
        const Divider(height: 24),
        
        // Total
        _buildPriceItem(
          context,
          'Total',
          total,
          isSubtotal: false,
          isTotal: true,
        ),
        
        // Valid for duration
        if (pricingData!['validFor'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Valid for ${pricingData!['validFor']}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTripDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (distance != null)
            _buildTripDetailItem(
              Icons.route,
              QuotePricingHelper.formatDistance(distance!),
              'Distance',
            ),
          if (duration != null)
            _buildTripDetailItem(
              Icons.access_time,
              QuotePricingHelper.formatDuration(duration!),
              'Duration',
            ),
        ],
      ),
    );
  }

  Widget _buildTripDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceItem(
    BuildContext context,
    String label,
    num amount, {
    bool isSubtotal = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal || isSubtotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue.shade900 : Colors.grey.shade700,
            ),
          ),
          Text(
            QuotePricingHelper.formatCurrency(amount.toDouble()),
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal || isSubtotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blue.shade900 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

