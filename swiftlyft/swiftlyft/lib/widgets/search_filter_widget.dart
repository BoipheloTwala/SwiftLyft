import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SearchFilterWidget extends StatefulWidget {
  final String? initialQuery;
  final List<String> filterOptions;
  final String? selectedFilter;
  final Function(String) onSearchChanged;
  final Function(String) onFilterChanged;
  final VoidCallback? onVoiceSearch;

  const SearchFilterWidget({
    super.key,
    this.initialQuery,
    required this.filterOptions,
    this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    this.onVoiceSearch,
  });

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  late TextEditingController _searchController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: SwiftLyftTheme.pureWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search vehicles, locations...',
              prefixIcon: const Icon(
                Icons.search,
                color: SwiftLyftTheme.mediumGray,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onVoiceSearch != null)
                    IconButton(
                      icon: const Icon(
                        Icons.mic,
                        color: SwiftLyftTheme.primaryBlue,
                      ),
                      onPressed: widget.onVoiceSearch,
                    ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: SwiftLyftTheme.mediumGray,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: SwiftLyftTheme.pureWhite,
            ),
          ),
        ),
        
        // Filter options (expandable)
        if (_isExpanded) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SwiftLyftTheme.deepCharcoal,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.filterOptions.map((filter) {
                    final isSelected = widget.selectedFilter == filter;
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        widget.onFilterChanged(filter);
                      },
                      backgroundColor: SwiftLyftTheme.lightGray,
                      selectedColor: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                      checkmarkColor: SwiftLyftTheme.primaryBlue,
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? SwiftLyftTheme.primaryBlue 
                            : SwiftLyftTheme.deepCharcoal,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class AdvancedFilterSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const AdvancedFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late Map<String, dynamic> _filters;
  late RangeValues _priceRange;
  late RangeValues _seatingRange;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
    _priceRange = RangeValues(
      _filters['minPrice']?.toDouble() ?? 0,
      _filters['maxPrice']?.toDouble() ?? 2000,
    );
    _seatingRange = RangeValues(
      _filters['minSeating']?.toDouble() ?? 1,
      _filters['maxSeating']?.toDouble() ?? 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters.clear();
                    _priceRange = const RangeValues(0, 2000);
                    _seatingRange = const RangeValues(1, 10);
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Price range
          const Text(
            'Price Range (R)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 2000,
            divisions: 20,
            labels: RangeLabels(
              'R${_priceRange.start.round()}',
              'R${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Seating capacity
          const Text(
            'Seating Capacity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          RangeSlider(
            values: _seatingRange,
            min: 1,
            max: 10,
            divisions: 9,
            labels: RangeLabels(
              '${_seatingRange.start.round()}',
              '${_seatingRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _seatingRange = values;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Vehicle features
          const Text(
            'Features',
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
              'Wi-Fi',
              'Climate Control',
              'Leather Interior',
              'Premium Audio',
              'Massage Seats',
            ].map((feature) {
              final isSelected = _filters['features']?.contains(feature) ?? false;
              return FilterChip(
                label: Text(feature),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (_filters['features'] == null) {
                      _filters['features'] = <String>[];
                    }
                    if (selected) {
                      _filters['features'].add(feature);
                    } else {
                      _filters['features'].remove(feature);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 30),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _filters['minPrice'] = _priceRange.start.round();
                _filters['maxPrice'] = _priceRange.end.round();
                _filters['minSeating'] = _seatingRange.start.round();
                _filters['maxSeating'] = _seatingRange.end.round();
                widget.onFiltersApplied(_filters);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
} 