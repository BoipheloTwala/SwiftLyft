import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../models/vehicle.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  Vehicle? _vehicle;
  bool _isFavorite = false;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  void _loadVehicleData() {
    setState(() {
      _isLoading = true;
    });

    _vehicle = Vehicle(
      id: widget.vehicleId,
      vehicleId: widget.vehicleId,
      name: widget.vehicleName,
      category: 'Luxury Sedan',
      imageUrl: 'assets/images/mercedes_s_class.jpg',
      description: 'Experience ultimate luxury with our premium Mercedes S-Class. This sophisticated sedan combines cutting-edge technology with unparalleled comfort, featuring plush leather seats, advanced climate control, and a state-of-the-art entertainment system. Perfect for business travel, special occasions, or simply indulging in the finest transportation experience.',
      imageGallery: ['assets/images/mercedes_s_class.jpg'],
      seatingCapacity: 4,
      passengerCapacity: 4,
      features: [
        'Leather Interior',
        'Wi-Fi Hotspot',
        'Climate Control',
        'Premium Audio System',
        'Massage Seats',
        'Ambient Lighting',
        'USB Charging',
        'Privacy Tint',
        'GPS Navigation',
        'Bluetooth Connectivity',
      ],
      basePrice: 1200.0,
      city: 'Johannesburg',
      badges: ['Top Choice', 'Certified Chauffeurs'],
      specifications: {
        'Engine': '3.0L V6',
        'Transmission': '9-Speed Automatic',
        'Fuel Type': 'Petrol',
        'Year': '2023',
        'Mileage': 'Low',
        'Color': 'Obsidian Black',
      },
      status: 'active',
      availability: true,
      rating: 4.9,
      totalTrips: 1250,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    // Show loading state while vehicle data is being loaded
    if (_isLoading || _vehicle == null) {
      return UnifiedNavigation.buildScaffold(
        context: context,
        currentRoute: AppRoutes.vehicleDetails,
        appBar: UnifiedAppBar.buildResponsive(
          context: context,
          title: widget.vehicleName,
          subtitle: 'Vehicle Details',
          showBackButton: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageGallery(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: WebContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  _buildVehicleHeader(),
                const SizedBox(height: 24),
                  _buildVehicleInfo(),
                const SizedBox(height: 24),
                _buildFeatures(),
                const SizedBox(height: 24),
                _buildSpecifications(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
              ],
            ),
          ),
        ),
      ],
      ),
    );

    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.vehicleDetails,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: widget.vehicleName,
        subtitle: 'Vehicle Details',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
              ],
      ),
      body: content,
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
        // PageView for images
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: _vehicle!.imageGallery.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SwiftLyftTheme.gradientStart,
                    SwiftLyftTheme.gradientEnd,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.directions_car,
                  size: 120,
                  color: SwiftLyftTheme.warmOrange.withValues(alpha: 0.3),
                ),
              ),
            );
          },
        ),
        
        // Image indicators
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _vehicle!.imageGallery.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? SwiftLyftTheme.primaryBlue
                      : SwiftLyftTheme.pureWhite.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildVehicleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vehicle!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.deepCharcoal,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _vehicle!.category,
              style: const TextStyle(
                fontSize: 16,
                color: SwiftLyftTheme.mediumGray,
              ),
            ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SwiftLyftTheme.primaryBlue, SwiftLyftTheme.accentPurple],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'R${_vehicle!.displayPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SwiftLyftTheme.pureWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    return Row(
      children: _vehicle!.badges.map((badge) {
        return Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _getBadgeColor(badge),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getBadgeIcon(badge),
                color: SwiftLyftTheme.pureWhite,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                badge,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.pureWhite,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatures() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
      ),
      itemCount: _vehicle!.features.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SwiftLyftTheme.pureWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getFeatureIcon(_vehicle!.features[index]),
                color: SwiftLyftTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _vehicle!.features[index],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecifications() {
    return Container(
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _vehicle!.specifications.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: SwiftLyftTheme.lightGray,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 14,
                  color: SwiftLyftTheme.mediumGray,
                ),
              ),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.quoteRequest,
                arguments: {
                  'vehicleId': _vehicle!.id,
                  'vehicleName': _vehicle!.name,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Request Quote',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Instant booking functionality
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'Top Choice':
        return SwiftLyftTheme.warmOrange;
      case 'Certified Chauffeurs':
        return SwiftLyftTheme.primaryBlue;
      default:
        return SwiftLyftTheme.mediumGray;
    }
  }

  IconData _getBadgeIcon(String badge) {
    switch (badge) {
      case 'Top Choice':
        return Icons.star;
      case 'Certified Chauffeurs':
        return Icons.verified_user;
      default:
        return Icons.check_circle;
    }
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'leather interior':
        return Icons.airline_seat_recline_normal;
      case 'wi-fi hotspot':
        return Icons.wifi;
      case 'climate control':
        return Icons.ac_unit;
      case 'premium audio system':
        return Icons.speaker;
      case 'massage seats':
        return Icons.spa;
      case 'ambient lighting':
        return Icons.lightbulb;
      case 'usb charging':
        return Icons.usb;
      case 'privacy tint':
        return Icons.visibility_off;
      case 'gps navigation':
        return Icons.navigation;
      case 'bluetooth connectivity':
        return Icons.bluetooth;
      default:
        return Icons.check;
    }
  }
} 