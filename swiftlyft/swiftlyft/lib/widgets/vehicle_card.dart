import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/app_state.dart';

class VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onViewDetails;
  final VoidCallback onRequestQuote;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onViewDetails,
    required this.onRequestQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isFavorited = appState.isVehicleFavorited(vehicle['id']);
        
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SwiftLyftTheme.gradientStart,
                  SwiftLyftTheme.gradientEnd,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.1),
                  ),
                  child: Stack(
                    children: [
                      // Placeholder for vehicle image
                      Center(
                        child: Icon(
                          Icons.directions_car,
                          size: 80,
                          color: SwiftLyftTheme.warmOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      
                      // Badges
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Row(
                          children: vehicle['badges'].map<Widget>((badge) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getBadgeColor(badge),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: SwiftLyftTheme.pureWhite,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      // Price
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'R${_getDisplayPrice().toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: SwiftLyftTheme.deepCharcoal,
                            ),
                          ),
                        ),
                      ),
                      
                      // Favorite button
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () {
                              appState.toggleVehicleFavorite(vehicle['id']);
                            },
                            icon: Icon(
                              isFavorited ? Icons.favorite : Icons.favorite_border,
                              color: isFavorited ? Colors.red : SwiftLyftTheme.mediumGray,
                              size: 20,
                            ),
                            tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            
                // Content section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle name and category
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: SwiftLyftTheme.pureWhite,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle['category'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.airline_seat_recline_normal,
                                  color: SwiftLyftTheme.pureWhite,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${vehicle['seatingCapacity']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: SwiftLyftTheme.pureWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        vehicle['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Features
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: vehicle['features'].take(3).map<Widget>((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 10,
                                color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.8),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onViewDetails,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: SwiftLyftTheme.pureWhite),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  color: SwiftLyftTheme.pureWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: onRequestQuote,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SwiftLyftTheme.pureWhite,
                                foregroundColor: SwiftLyftTheme.deepCharcoal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Request Quote',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'Top Choice':
        return SwiftLyftTheme.warmOrange;
      case 'Popular':
        return SwiftLyftTheme.successGreen;
      case 'Premium':
        return SwiftLyftTheme.accentPurple;
      case 'New':
        return SwiftLyftTheme.primaryBlue;
      default:
        return SwiftLyftTheme.mediumGray;
    }
  }

  /// Get display price with luxury service adjustment
  /// This applies a multiplier to make prices more realistic for a premium chauffeur service
  double _getDisplayPrice() {
    final basePrice = (vehicle['basePrice'] ?? 0.0).toDouble();
    final category = (vehicle['category'] ?? 'sedan').toString().toLowerCase();
    
    if (basePrice <= 0) {
      // If no base price, return category-based pricing
      final categoryPrices = {
        'sedan': 600.0,
        'suv': 950.0,
        'luxury': 1800.0,
        'van': 1200.0,
        'truck': 1400.0,
        'hybrid': 700.0,
      };
      return categoryPrices[category] ?? 600.0;
    }
    
    // Apply luxury service multiplier (3.5x - 5.0x based on category)
    final multipliers = {
      'sedan': 3.5,
      'suv': 4.0,
      'luxury': 5.0,
      'van': 4.5,
      'truck': 4.5,
      'hybrid': 4.0,
    };
    
    final multiplier = multipliers[category] ?? 4.0;
    return (basePrice * multiplier).roundToDouble();
  }
} 