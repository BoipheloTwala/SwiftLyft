import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../utils/quote_status_helper.dart';
import '../providers/app_state.dart';
import '../models/quote.dart';

class QuoteHistoryScreen extends StatefulWidget {
  const QuoteHistoryScreen({super.key});

  @override
  State<QuoteHistoryScreen> createState() => _QuoteHistoryScreenState();
}

class _QuoteHistoryScreenState extends State<QuoteHistoryScreen> {
  List<Quote> _quotes = [];
  bool _isLoading = true;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  String? _selectedStatus; // 'pending', 'accepted', 'expired'
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _quotes.clear();
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final quotes = await appState.getQuoteHistory(
        page: _currentPage,
        limit: _pageSize,
        status: _selectedStatus,
      );

      setState(() {
        if (_currentPage == 1) {
          _quotes = quotes;
        } else {
          _quotes.addAll(quotes);
        }
        _hasMore = quotes.length == _pageSize;
        _isLoading = false;
      });

      if (refresh) {
        _currentPage = 2; // Next page after initial load
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load quotes: $e';
        _isLoading = false;
      });
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

  Future<void> _applyFilters() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _quotes.clear();
      _isLoading = true;
      _error = null;
    });
    await _loadQuotes(refresh: true);
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
    });
    await _applyFilters();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Quotes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status filter
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                  DropdownMenuItem(value: 'expired', child: Text('Expired')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),

              const SizedBox(height: 16),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Start Date'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'End Date'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.quoteHistory,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Quote History',
        subtitle: 'View your quote requests',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter quotes',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadQuotes(refresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _quotes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildQuoteList(),
    );
  }

  Widget _buildErrorState() {
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
            'Unable to load quotes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadQuotes(refresh: true),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteList() {
    if (_quotes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadQuotes(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _quotes.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _quotes.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildQuoteCard(_quotes[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description,
            size: 64,
            color: SwiftLyftTheme.mediumGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'No quotes found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus != null || _startDate != null || _endDate != null
                ? 'Try adjusting your filters'
                : 'Your quote requests will appear here',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: SwiftLyftTheme.mediumGray,
            ),
          ),
          if (_selectedStatus != null || _startDate != null || _endDate != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    final isExpired = quote.isExpired;
    final canAccept = quote.status == 'pending' && !isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.quoteDetails,
          arguments: {'quoteId': quote.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with ID and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quote #${quote.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(quote.status, isExpired),
                ],
              ),

              const SizedBox(height: 8),

              // Trip details
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: SwiftLyftTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${quote.pickupLocation['address']} → ${quote.dropoffLocation['address']}',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date and time
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: SwiftLyftTheme.secondaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(quote.scheduledDate)} at ${_formatTime(quote.scheduledDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Price
              Row(
                children: [
                  const Icon(
                    Icons.attach_money,
                    size: 16,
                    color: SwiftLyftTheme.successGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'R${quote.adjustedPricing['total'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.successGreen,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Expires: ${_formatDate(quote.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.red : SwiftLyftTheme.mediumGray,
                    ),
                  ),
                ],
              ),

              // Action buttons
              if (canAccept) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.quoteDetails,
                          arguments: {'quoteId': quote.id},
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SwiftLyftTheme.successGreen,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Accept Quote'),
                      ),
                    ),
                  ],
                ),
              ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }
}
