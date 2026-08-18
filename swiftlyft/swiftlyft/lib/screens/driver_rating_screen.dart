import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../providers/app_state.dart';
import '../models/driver.dart';
import '../models/booking.dart';

class DriverRatingScreen extends StatefulWidget {
  final String bookingId;
  final String driverId;

  const DriverRatingScreen({
    super.key,
    required this.bookingId,
    required this.driverId,
  });

  @override
  State<DriverRatingScreen> createState() => _DriverRatingScreenState();
}

class _DriverRatingScreenState extends State<DriverRatingScreen> {
  Driver? _driver;
  Booking? _booking;
  bool _isLoading = true;
  String? _error;
  double _rating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  // Rating criteria
  final Map<String, bool> _criteria = {
    'Professionalism': false,
    'Punctuality': false,
    'Vehicle Condition': false,
    'Driving Skills': false,
    'Communication': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Load booking and driver data
      final booking = await appState.getBookingById(widget.bookingId);
      if (booking != null) {
        setState(() {
          _booking = booking;
        });

        // Load driver details
        final driver = await appState.getDriverById(widget.driverId);
        setState(() {
          _driver = driver;
        });
      } else {
        setState(() {
          _error = 'Booking not found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.rateDriver(
        widget.driverId,
        bookingId: widget.bookingId,
        rating: _rating,
        review: _reviewController.text.isNotEmpty ? _reviewController.text : null,
        criteria: _criteria.map((key, value) => MapEntry(key, value ? 1.0 : 0.0)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: SwiftLyftTheme.successGreen,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.driverRating,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Rate Your Driver',
        subtitle: 'Help us improve our service',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildRatingForm(),
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
            'Unable to load rating form',
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
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingForm() {
    if (_driver == null || _booking == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver info card
          _buildDriverInfoCard(),

          const SizedBox(height: 24),

          // Overall rating
          _buildOverallRating(),

          const SizedBox(height: 24),

          // Rating criteria
          _buildRatingCriteria(),

          const SizedBox(height: 24),

          // Review text field
          _buildReviewField(),

          const SizedBox(height: 32),

          // Submit button
          _buildSubmitButton(),

          const SizedBox(height: 16),

          // Skip button
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Row(
        children: [
          // Driver avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
            backgroundImage: _driver!.photoUrl != null
                ? NetworkImage(_driver!.photoUrl!)
                : null,
            child: _driver!.photoUrl == null
                ? const Icon(
                    Icons.person,
                    color: SwiftLyftTheme.primaryBlue,
                    size: 30,
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Driver details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driver!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: SwiftLyftTheme.warmOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_driver!.rating.toStringAsFixed(1)} (${_driver!.totalRatings} ratings)',
                      style: const TextStyle(
                        color: SwiftLyftTheme.mediumGray,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _booking!.vehicleName,
                  style: const TextStyle(
                    color: SwiftLyftTheme.mediumGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Trip completed badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SwiftLyftTheme.successGreen.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Trip Completed',
              style: TextStyle(
                color: SwiftLyftTheme.successGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Rating',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: SwiftLyftTheme.warmOrange,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _rating == 0.0
                  ? 'Tap to rate'
                  : _rating == 1.0
                      ? 'Poor'
                      : _rating == 2.0
                          ? 'Fair'
                          : _rating == 3.0
                              ? 'Good'
                              : _rating == 4.0
                                  ? 'Very Good'
                                  : 'Excellent',
              style: const TextStyle(
                color: SwiftLyftTheme.mediumGray,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCriteria() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What stood out?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._criteria.entries.map((entry) {
            return CheckboxListTile(
              title: Text(entry.key),
              value: entry.value,
              onChanged: (value) {
                setState(() {
                  _criteria[entry.key] = value ?? false;
                });
              },
              activeColor: SwiftLyftTheme.primaryBlue,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewField() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Comments (Optional)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience with this driver...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: SwiftLyftTheme.lightGray.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRating,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: SwiftLyftTheme.successGreen,
          disabledBackgroundColor: SwiftLyftTheme.mediumGray,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Submit Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
