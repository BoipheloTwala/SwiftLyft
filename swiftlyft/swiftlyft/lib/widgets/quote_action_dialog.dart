import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../utils/quote_status_helper.dart';
import '../utils/quote_pricing_helper.dart';

/// Dialog for accepting or rejecting a quote
class QuoteActionDialog extends StatefulWidget {
  final Quote quote;
  final Function(String action, String? notes) onAction;

  const QuoteActionDialog({
    super.key,
    required this.quote,
    required this.onAction,
  });

  @override
  State<QuoteActionDialog> createState() => _QuoteActionDialogState();
}

class _QuoteActionDialogState extends State<QuoteActionDialog> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String _selectedAction = 'accept'; // 'accept' or 'cancel'

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_selectedAction == 'accept' ? 'Accept Quote' : 'Cancel Quote'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote Summary
            _buildQuoteSummary(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Action Selector
            _buildActionSelector(),
            const SizedBox(height: 16),
            
            // Notes field
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _selectedAction == 'accept' 
                    ? 'Additional Notes (Optional)' 
                    : 'Cancellation Reason (Optional)',
                hintText: _selectedAction == 'accept'
                    ? 'Any special requirements...'
                    : 'Why are you cancelling?',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Warning/Info message
            _buildInfoMessage(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAction == 'accept' 
                ? Colors.green 
                : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_selectedAction == 'accept' ? 'Accept Quote' : 'Cancel Quote'),
        ),
      ],
    );
  }

  Widget _buildQuoteSummary() {
    final adjusted = widget.quote.adjustedPricing;
    final total = adjusted['total'];
    final totalStr = total != null 
        ? QuotePricingHelper.formatCurrency(total.toDouble())
        : 'N/A';
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quote Total:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                totalStr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vehicle: ${widget.quote.vehicleType}',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            'Service: ${widget.quote.serviceType}',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            'Passengers: ${widget.quote.passengerCount}',
            style: const TextStyle(fontSize: 13),
          ),
          if (widget.quote.validUntil != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  QuoteStatusHelper.getTimeRemaining(widget.quote.validUntil),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Action:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                value: 'accept',
                groupValue: _selectedAction,
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value!;
                  });
                },
                title: const Text('Accept'),
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                value: 'cancel',
                groupValue: _selectedAction,
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value!;
                  });
                },
                title: const Text('Cancel'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoMessage() {
    if (_selectedAction == 'accept') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Accepting this quote will notify SwiftLyft to proceed with your booking.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'This action cannot be undone. The quote will be cancelled.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = _notesController.text.trim();
      await widget.onAction(
        _selectedAction,
        notes.isEmpty ? null : notes,
      );
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

