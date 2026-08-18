import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';

class SpecialOffersScreen extends StatelessWidget {
  const SpecialOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: WebContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildOffersGrid(context),
            const SizedBox(height: 24),
            _buildPromotionalContent(context),
          ],
        ),
      ),
    );

    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.specialOffers,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'Special Offers',
        subtitle: 'Exclusive deals for you',
        showBackButton: true,
      ),
      body: content,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Promotions',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, app, _) {
            if (app.isLoadingLoyalty) {
              return const LinearProgressIndicator(minHeight: 6);
            }
            final l = app.loyaltyInfo;
            if (l == null) return const SizedBox.shrink();
            final discountPct = (l.tierDiscount * 100).toStringAsFixed(0);
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: SwiftLyftTheme.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l.loyaltyTier} Member • ${l.loyaltyPoints} pts',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: l.tierProgress.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: SwiftLyftTheme.lightGray,
                            valueColor: const AlwaysStoppedAnimation(SwiftLyftTheme.primaryBlue),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Up to $discountPct% loyalty discount on eligible offers',
                          style: const TextStyle(fontSize: 12, color: SwiftLyftTheme.mediumGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPromotionalContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SwiftLyftTheme.primaryBlue, SwiftLyftTheme.accentPurple],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Limited Time Offers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SwiftLyftTheme.pureWhite,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Don\'t miss out on these exclusive deals. Book now and save on your luxury transportation.',
            style: TextStyle(
              fontSize: 16,
              color: SwiftLyftTheme.pureWhite,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.vehicleListing);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SwiftLyftTheme.pureWhite,
              foregroundColor: SwiftLyftTheme.primaryBlue,
            ),
            child: const Text('View All Vehicles'),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersGrid(BuildContext context) {
    final offers = [
      _Offer('Weekend Special', '20% off on weekends', SwiftLyftTheme.successGreen),
      _Offer('Airport Transfer', '15% off airport rides', SwiftLyftTheme.accentPurple),
      _Offer('First Ride', '10% off your first ride', SwiftLyftTheme.warmOrange),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: SwiftLyftTheme.isDesktop(context) ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.8,
      ),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [offer.color, offer.color.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  if (constraints.maxWidth > 200) ...[
                    Icon(Icons.local_offer, color: SwiftLyftTheme.pureWhite, size: constraints.maxWidth > 300 ? 24 : 20),
                    SizedBox(width: constraints.maxWidth > 300 ? 12 : 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            offer.title,
                            style: TextStyle(
                              fontSize: constraints.maxWidth > 300 ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: SwiftLyftTheme.pureWhite,
                            ),
                            maxLines: constraints.maxWidth > 200 ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            offer.description,
                            style: TextStyle(
                              fontSize: constraints.maxWidth > 300 ? 14 : 12,
                              color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.8),
                            ),
                            maxLines: constraints.maxWidth > 200 ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (constraints.maxWidth > 250) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth > 300 ? 12 : 8,
                        vertical: constraints.maxWidth > 300 ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Claim',
                        style: TextStyle(
                          fontSize: constraints.maxWidth > 300 ? 12 : 10,
                          fontWeight: FontWeight.w600,
                          color: SwiftLyftTheme.pureWhite,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }


}

class _Offer {
  final String title;
  final String description;
  final Color color;
  _Offer(this.title, this.description, this.color);
} 