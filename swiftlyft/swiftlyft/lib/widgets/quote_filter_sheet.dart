import 'package:flutter/material.dart';
import '../utils/quote_status_helper.dart';

/// Bottom sheet for filtering quotes
class QuoteFilterSheet extends StatefulWidget {
  final String? initialStatus;
  final String? initialSortBy;
  final bool initialShowExpiredOnly;
  final Function(String? status, String sortBy, bool showExpiredOnly) onApply;

  const QuoteFilterSheet({
    super.key,
    this.initialStatus,
    this.initialSortBy = 'date',
    this.initialShowExpiredOnly = false,
    required this.onApply,
  });

  @override
  State<QuoteFilterSheet> createState() => _QuoteFilterSheetState();
}

class _QuoteFilterSheetState extends State<QuoteFilterSheet> {
  String? _selectedStatus;
  String _sortBy = 'date';
  bool _showExpiredOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _sortBy = widget.initialSortBy ?? 'date';
    _showExpiredOnly = widget.initialShowExpiredOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Status Filter
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('All', null),
              ...QuoteStatusHelper.getValidStatuses().map((status) =>
                _buildStatusChip(
                  QuoteStatusHelper.getStatusDisplayName(status),
                  status,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sort By
          const Text(
            'Sort By',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip('Most Recent', 'date'),
              _buildSortChip('Price: High to Low', 'price_desc'),
              _buildSortChip('Price: Low to High', 'price_asc'),
              _buildSortChip('Expiring Soon', 'expiry'),
            ],
          ),
          const SizedBox(height: 24),
          
          // Additional Filters
          const Text(
            'Additional Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Show Expired Only'),
            value: _showExpiredOnly,
            onChanged: (value) {
              setState(() {
                _showExpiredOnly = value;
              });
            },
            dense: true,
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _sortBy = 'date';
                      _showExpiredOnly = false;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedStatus, _sortBy, _showExpiredOnly);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String? value) {
    final isSelected = _selectedStatus == value;
    final color = value != null 
        ? QuoteStatusHelper.getStatusColor(value)
        : Colors.grey;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : null;
        });
      },
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
          });
        }
      },
      selectedColor: Colors.blue.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

