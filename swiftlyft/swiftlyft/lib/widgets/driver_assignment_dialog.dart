import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/driver.dart';
import '../models/booking.dart';
import '../providers/app_state.dart';
import '../utils/driver_helper.dart';
import '../utils/theme.dart';

class DriverAssignmentDialog extends StatefulWidget {
  final Booking booking;
  final List<Driver>? availableDrivers;
  final Function(Booking updatedBooking)? onDriverAssigned;

  const DriverAssignmentDialog({
    super.key,
    required this.booking,
    this.availableDrivers,
    this.onDriverAssigned,
  });

  @override
  State<DriverAssignmentDialog> createState() => _DriverAssignmentDialogState();
}

class _DriverAssignmentDialogState extends State<DriverAssignmentDialog> {
  Driver? _selectedDriver;
  List<Driver> _drivers = [];
  bool _isLoading = false;
  bool _isLoadingDrivers = true;
  String _searchQuery = '';
  String _sortBy = 'recommended'; // recommended, rating, experience

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoadingDrivers = true;
    });

    try {
      if (widget.availableDrivers != null) {
        _drivers = widget.availableDrivers!;
      } else {
        // In production, load drivers from API
        // For now, use mock data
        _drivers = _getMockDrivers();
      }

      // Filter to only available drivers
      _drivers = DriverHelper.filterAvailableDrivers(_drivers);

      // Apply default sorting
      _sortDrivers();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDrivers = false;
        });
      }
    }
  }

  void _sortDrivers() {
    setState(() {
      switch (_sortBy) {
        case 'recommended':
          _drivers = DriverHelper.getRecommendedDrivers(
            _drivers,
            widget.booking,
            limit: _drivers.length,
          );
          break;
        case 'rating':
          _drivers = DriverHelper.sortByRating(_drivers);
          break;
        case 'experience':
          _drivers.sort((a, b) => b.totalTrips.compareTo(a.totalTrips));
          break;
      }
    });
  }

  List<Driver> get _filteredDrivers {
    if (_searchQuery.isEmpty) return _drivers;

    return _drivers.where((driver) {
      final query = _searchQuery.toLowerCase();
      return driver.name.toLowerCase().contains(query) ||
             driver.phone.toLowerCase().contains(query) ||
             driver.email.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _assignDriver() async {
    if (_selectedDriver == null) {
      _showErrorMessage('Please select a driver');
      return;
    }

    // Validate assignment
    final validationError = DriverHelper.validateDriverAssignment(
      widget.booking,
      _selectedDriver!,
    );

    if (validationError != null) {
      _showErrorMessage(validationError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      final success = await appState.assignDriver(
        widget.booking.id,
        _selectedDriver!.id,
      );

      if (success && mounted) {
        // Reload booking to get updated data
        final updatedBooking = await appState.getBookingById(widget.booking.id);

        if (updatedBooking != null) {
          widget.onDriverAssigned?.call(updatedBooking);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Driver ${_selectedDriver!.name} assigned successfully',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop(updatedBooking);
        }
      } else {
        _showErrorMessage('Failed to assign driver');
      }
    } catch (e) {
      _showErrorMessage('Failed to assign driver: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: SwiftLyftTheme.errorRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            const Divider(height: 1),

            // Search and Filter
            _buildSearchAndFilter(),

            // Driver List
            Expanded(
              child: _isLoadingDrivers
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDrivers.isEmpty
                      ? _buildEmptyState()
                      : _buildDriverList(),
            ),

            const Divider(height: 1),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add,
              color: SwiftLyftTheme.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign Driver',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booking: ${widget.booking.id.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 13,
                    color: SwiftLyftTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search drivers by name, phone, or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Sort options
          Row(
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildSortChip('Recommended', 'recommended'),
                    _buildSortChip('Rating', 'rating'),
                    _buildSortChip('Experience', 'experience'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
          });
          _sortDrivers();
        }
      },
      selectedColor: SwiftLyftTheme.primaryBlue.withOpacity(0.2),
      checkmarkColor: SwiftLyftTheme.primaryBlue,
    );
  }

  Widget _buildDriverList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredDrivers.length,
      itemBuilder: (context, index) {
        final driver = _filteredDrivers[index];
        final isSelected = _selectedDriver?.id == driver.id;
        final isRecommended = index < 3 && _sortBy == 'recommended';

        return _DriverCard(
          driver: driver,
          isSelected: isSelected,
          isRecommended: isRecommended,
          recommendationScore: isRecommended
              ? DriverHelper.getRecommendationScore(driver, widget.booking)
              : null,
          onTap: () {
            setState(() {
              _selectedDriver = driver;
            });
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: SwiftLyftTheme.mediumGray,
            ),
            const SizedBox(height: 16),
            const Text(
              'No available drivers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'All drivers are currently busy or offline'
                  : 'No drivers match your search',
              style: TextStyle(
                fontSize: 14,
                color: SwiftLyftTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading || _selectedDriver == null ? null : _assignDriver,
            style: ElevatedButton.styleFrom(
              backgroundColor: SwiftLyftTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Assign Driver',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  // Mock drivers for demonstration
  List<Driver> _getMockDrivers() {
    return [
      Driver(
        id: 'driver1',
        driverId: 'DRV001',
        userId: 'user1',
        name: 'John Smith',
        phone: '+27123456789',
        email: 'john@example.com',
        rating: 4.9,
        totalTrips: 250,
        performance: {'completion': 0.98, 'rating': 4.9},
        status: DriverStatus.online,
        isOnline: true,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      ),
      Driver(
        id: 'driver2',
        driverId: 'DRV002',
        userId: 'user2',
        name: 'Sarah Johnson',
        phone: '+27123456790',
        email: 'sarah@example.com',
        rating: 4.8,
        totalTrips: 180,
        performance: {'completion': 0.96, 'rating': 4.8},
        status: DriverStatus.online,
        isOnline: true,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
        updatedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      ),
      Driver(
        id: 'driver3',
        driverId: 'DRV003',
        userId: 'user3',
        name: 'Michael Brown',
        phone: '+27123456791',
        email: 'michael@example.com',
        rating: 4.7,
        totalTrips: 150,
        performance: {'completion': 0.94, 'rating': 4.7},
        status: DriverStatus.online,
        isOnline: true,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 250)),
        updatedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      ),
    ];
  }
}

class _DriverCard extends StatelessWidget {
  final Driver driver;
  final bool isSelected;
  final bool isRecommended;
  final double? recommendationScore;
  final VoidCallback onTap;

  const _DriverCard({
    required this.driver,
    required this.isSelected,
    required this.isRecommended,
    this.recommendationScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? SwiftLyftTheme.primaryBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? SwiftLyftTheme.primaryBlue
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: SwiftLyftTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    driver.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: SwiftLyftTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.recommend,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Top ${recommendationScore?.toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          DriverHelper.getRatingBadge(
                            driver.rating,
                            totalTrips: driver.totalTrips,
                          ),
                          const SizedBox(width: 8),
                          DriverHelper.getStatusBadge(driver.status),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: SwiftLyftTheme.primaryBlue,
                    size: 28,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Driver details
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.phone,
                    driver.phone,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.email,
                    driver.email,
                  ),
                ),
              ],
            ),

            if (driver.performance != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Completion Rate: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DriverHelper.getPerformanceIndicator(driver.performance),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: SwiftLyftTheme.mediumGray),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: SwiftLyftTheme.mediumGray,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Show driver assignment dialog
Future<Booking?> showDriverAssignmentDialog({
  required BuildContext context,
  required Booking booking,
  List<Driver>? availableDrivers,
  Function(Booking updatedBooking)? onDriverAssigned,
}) {
  return showDialog<Booking>(
    context: context,
    builder: (context) => DriverAssignmentDialog(
      booking: booking,
      availableDrivers: availableDrivers,
      onDriverAssigned: onDriverAssigned,
    ),
  );
}

