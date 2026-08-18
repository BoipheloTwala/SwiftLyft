import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: WebContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 32),
            _buildMissionSection(),
            const SizedBox(height: 32),
            _buildValuesSection(),
            const SizedBox(height: 32),
            _buildContactSection(context),
          ],
        ),
      ),
    );

    return UnifiedNavigation.buildScaffold(
      context: context,
      currentRoute: AppRoutes.aboutUs,
      appBar: UnifiedAppBar.buildResponsive(
        context: context,
        title: 'About Us',
        subtitle: 'Learn more about SwiftLyft',
        showBackButton: true,
      ),
      body: content,
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 300,
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
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: SwiftLyftTheme.warmOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [SwiftLyftTheme.warmOrange, SwiftLyftTheme.warmGradientEnd],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SwiftLyftTheme.warmOrange.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_taxi,
                    size: 50,
                    color: SwiftLyftTheme.pureWhite,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SwiftLyft',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: SwiftLyftTheme.warmOrange,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Journey, Elevated',
                  style: TextStyle(
                    fontSize: 16,
                    color: SwiftLyftTheme.pureWhite,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SwiftLyftTheme.secondaryTeal, SwiftLyftTheme.warmOrange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_phone,
                  color: SwiftLyftTheme.pureWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get in Touch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'We\'d love to hear from you',
                      style: TextStyle(
                        fontSize: 14,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildValuesSection() {
    final values = [
      Value(
        title: 'Excellence',
        description: 'We strive for excellence in every aspect of our service.',
        icon: Icons.star,
      ),
      Value(
        title: 'Reliability',
        description: 'Your time is precious. We guarantee punctual, reliable service.',
        icon: Icons.schedule,
      ),
      Value(
        title: 'Luxury',
        description: 'Experience the finest in luxury transportation.',
        icon: Icons.diamond,
      ),
      Value(
        title: 'Safety',
        description: 'Your safety is our top priority with certified chauffeurs.',
        icon: Icons.security,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      color: SwiftLyftTheme.lightGray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Values',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SwiftLyftTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: values.length,
            itemBuilder: (context, index) {
              final value = values[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SwiftLyftTheme.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: SwiftLyftTheme.deepCharcoal.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      value.icon,
                      size: 40,
                      color: SwiftLyftTheme.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SwiftLyftTheme.mediumGray,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SwiftLyftTheme.primaryBlue, SwiftLyftTheme.accentPurple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag,
                  color: SwiftLyftTheme.pureWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Mission',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'To provide exceptional luxury transportation services',
                      style: TextStyle(
                        fontSize: 14,
                        color: SwiftLyftTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'At SwiftLyft, we are committed to delivering the highest standards of luxury transportation. Our mission is to provide exceptional service, unmatched comfort, and reliable transportation solutions for discerning clients who demand excellence.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

}

class TimelineEvent {
  final String year;
  final String title;
  final String description;
  final IconData icon;

  TimelineEvent({
    required this.year,
    required this.title,
    required this.description,
    required this.icon,
  });
}


class Value {
  final String title;
  final String description;
  final IconData icon;

  Value({
    required this.title,
    required this.description,
    required this.icon,
  });
} 