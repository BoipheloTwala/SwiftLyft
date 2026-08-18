import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/quote_filter_sheet.dart';
import '../widgets/quote_management_panel.dart';
import '../utils/quote_status_helper.dart';
import '../utils/quote_pricing_helper.dart';
import '../providers/app_state.dart';
import '../models/quote.dart';

/// Enhanced quote management screen with filtering, search, and bulk actions
class QuoteManagementScreen extends StatefulWidget {
  const QuoteManagementScreen({super.key});

  @override
  State<QuoteManagementScreen> createState() => _QuoteManagementScreenState();
}

class _QuoteManagementScreenState extends State<QuoteManagementScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Quote> _allQuotes = [];
  List<Quote> _filteredQuotes = [];
  List<Quote> _selectedQuotes = [];
  
  bool _isLoading = true;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  // Filters
  String? _statusFilter;
  String _sortBy = 'date';
  bool _showExpiredOnly = false;
  String _searchQuery = '';

  // Selection mode
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _allQuotes.clear();
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final quotes = await appState.getQuoteHistory(
        page: _currentPage,
        limit: _pageSize,
        status: _statusFilter,
      );

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _allQuotes = quotes;
          } else {
            _allQuotes.addAll(quotes);
          }
          _hasMore = quotes.length == _pageSize;
          _isLoading = false;
          _applyFiltersAndSort();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load quotes: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoading) {
      _currentPage++;
      _loadQuotes();
    }
  }

  void _applyFiltersAndSort() {
    List<Quote> filtered = List.from(_allQuotes);

    // Apply expired filter
    if (_showExpiredOnly) {
      filtered = filtered.where((q) => q.isExpired).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((q) {
        return q.vehicleType.toLowerCase().contains(query) ||
               q.serviceType.toLowerCase().contains(query) ||
               q.id.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'price_desc':
          final aTotal = (a.adjustedPricing['total'] ?? 0).toDouble();
          final bTotal = (b.adjustedPricing['total'] ?? 0).toDouble();
          return bTotal.compareTo(aTotal);
        case 'price_asc':
          final aTotal = (a.adjustedPricing['total'] ?? 0).toDouble();
          final bTotal = (b.adjustedPricing['total'] ?? 0).toDouble();
          return aTotal.compareTo(bTotal);
        case 'expiry':
          if (a.validUntil == null) return 1;
          if (b.validUntil == null) return -1;
          return a.validUntil!.compareTo(b.validUntil!);
        case 'date':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    setState(() {
      _filteredQuotes = filtered;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => QuoteFilterSheet(
        initialStatus: _statusFilter,
        initialSortBy: _sortBy,
        initialShowExpiredOnly: _showExpiredOnly,
        onApply: (status, sortBy, showExpiredOnly) {
          setState(() {
            _statusFilter = status;
            _sortBy = sortBy;
            _showExpiredOnly = showExpiredOnly;
          });
          _loadQuotes(refresh: true);
        },
      ),
    );
  }

  void _toggleQuoteSelection(Quote quote) {
    setState(() {
      if (_selectedQuotes.contains(quote)) {
        _selectedQuotes.remove(quote);
        if (_selectedQuotes.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedQuotes.add(quote);
        _isSelectionMode = true;
      }
    });
  }

  void _startSelectionMode(Quote quote) {
    setState(() {
      _isSelectionMode = true;
      _selectedQuotes = [quote];
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedQuotes.clear();
    });
  }

  Future<void> _bulkCancelQuotes(List<Quote> quotes) async {
    final appState = Provider.of<AppState>(context, listen: false);
    int successCount = 0;
    
    for (final quote in quotes) {
      try {
        final success = await appState.cancelQuote(quote.id, reason: 'Bulk cancellation');
        if (success) successCount++;
      } catch (e) {
        debugPrint('Failed to cancel quote ${quote.id}: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cancelled $successCount of ${quotes.length} quotes'),
          backgroundColor: successCount == quotes.length ? Colors.green : Colors.orange,
        ),
      );

      _cancelSelection();
      _loadQuotes(refresh: true);
    }
  }

  Future<void> _bulkExportQuotes(List<Quote> quotes) async {
    // In a real implementation, this would export to CSV or PDF
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exporting ${quotes.length} quotes...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _navigateToQuoteDetails(Quote quote) {
    Navigator.pushNamed(
      context,
      AppRoutes.quoteDetails,
      arguments: {'quoteId': quote.id},
    ).then((_) => _loadQuotes(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _statusFilter != null || 
                             _showExpiredOnly || 
                             _sortBy != 'date';

    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.quoteHistory,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Quote Management',
        subtitle: _isSelectionMode 
            ? '${_selectedQuotes.length} selected'
            : 'View and manage your quotes',
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchBar(hasActiveFilters),
          
          // Summary Card
          if (!_isLoading && _allQuotes.isNotEmpty && !_isSelectionMode)
            _buildSummaryCard(),
          
          // Quote List
          Expanded(
            child: _buildQuoteList(),
          ),
          
          // Selection Panel
          if (_isSelectionMode)
            QuoteManagementPanel(
              selectedQuotes: _selectedQuotes,
              onCancelSelection: _cancelSelection,
              onBulkCancel: _bulkCancelQuotes,
              onBulkExport: _bulkExportQuotes,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool hasActiveFilters) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quotes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFiltersAndSort();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFiltersAndSort();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Badge(
            isLabelVisible: hasActiveFilters,
            label: const Text('•'),
            child: IconButton(
              onPressed: _showFilterSheet,
              icon: const Icon(Icons.filter_list),
              style: IconButton.styleFrom(
                backgroundColor: hasActiveFilters ? Colors.blue.shade50 : null,
                foregroundColor: hasActiveFilters ? Colors.blue : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalQuotes = _allQuotes.length;
    final pendingQuotes = _allQuotes.where((q) => q.status.toLowerCase() == 'pending').length;
    final acceptedQuotes = _allQuotes.where((q) => q.status.toLowerCase() == 'accepted').length;
    final expiredQuotes = _allQuotes.where((q) => q.isExpired).length;
    final totalValue = _allQuotes.fold<double>(0, (sum, q) {
      final adjusted = q.adjustedPricing;
      final total = adjusted['total'];
      return sum + (total != null ? total.toDouble() : 0);
    });

    return QuoteSummaryCard(
      totalQuotes: totalQuotes,
      pendingQuotes: pendingQuotes,
      acceptedQuotes: acceptedQuotes,
      expiredQuotes: expiredQuotes,
      totalValue: totalValue,
      onStatusTap: (status) {
        setState(() {
          _statusFilter = status;
        });
        _loadQuotes(refresh: true);
      },
    );
  }

  Widget _buildQuoteList() {
    if (_isLoading && _allQuotes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadQuotes(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredQuotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No quotes found matching "$_searchQuery"'
                  : 'No quotes found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (_searchQuery.isNotEmpty || hasActiveFilters()) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _statusFilter = null;
                    _showExpiredOnly = false;
                    _sortBy = 'date';
                  });
                  _loadQuotes(refresh: true);
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadQuotes(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredQuotes.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredQuotes.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final quote = _filteredQuotes[index];
          final isSelected = _selectedQuotes.contains(quote);

          return _buildQuoteCard(quote, isSelected);
        },
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote, bool isSelected) {
    final adjusted = quote.adjustedPricing;
    final total = adjusted['total'];
    final totalStr = total != null 
        ? QuotePricingHelper.formatCurrency(total.toDouble())
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: Colors.blue.shade300, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleQuoteSelection(quote);
          } else {
            _navigateToQuoteDetails(quote);
          }
        },
        onLongPress: () => _startSelectionMode(quote),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleQuoteSelection(quote),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              quote.vehicleType.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                quote.serviceType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quote #${quote.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(quote.status, quote.isExpired),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(quote.createdAt),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (quote.validUntil != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Valid Until',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd').format(quote.validUntil!),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: quote.isExpired ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Estimated',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        totalStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isExpired) {
    final displayStatus = isExpired ? 'expired' : status;
    final color = QuoteStatusHelper.getStatusColor(displayStatus);
    final icon = QuoteStatusHelper.getStatusIcon(displayStatus);
    final text = QuoteStatusHelper.getStatusDisplayName(displayStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool hasActiveFilters() {
    return _statusFilter != null || _showExpiredOnly || _sortBy != 'date';
  }
}

