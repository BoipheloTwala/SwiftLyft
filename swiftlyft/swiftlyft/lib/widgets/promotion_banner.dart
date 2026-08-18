import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/theme.dart';

class PromotionBanner extends StatefulWidget {
  const PromotionBanner({super.key});

  @override
  State<PromotionBanner> createState() => _PromotionBannerState();
}

class _PromotionBannerState extends State<PromotionBanner>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;
  Timer? _promotionTimer;

  final List<Promotion> _promotions = [
    Promotion(
      title: '10% off your first ride!',
      description: 'New customers only',
      icon: Icons.local_offer,
      endTime: DateTime.now().add(const Duration(days: 7)),
      color: SwiftLyftTheme.warmOrange,
    ),
    Promotion(
      title: 'Weekend Special',
      description: '20% off all weekend bookings',
      icon: Icons.weekend,
      endTime: DateTime.now().add(const Duration(days: 3)),
      color: SwiftLyftTheme.successGreen,
    ),
    Promotion(
      title: 'Airport Transfer',
      description: '15% off airport rides',
      icon: Icons.flight,
      endTime: DateTime.now().add(const Duration(days: 14)),
      color: SwiftLyftTheme.accentPurple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _startPromotionCycle();
  }

  @override
  void dispose() {
    _promotionTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPromotionCycle() {
    _promotionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentIndex = (_currentIndex + 1) % _promotions.length;
            });
            _animationController.forward();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 400;
    final isVeryNarrow = screenWidth < 300;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            minHeight: isVeryNarrow ? 100 : (isNarrow ? 110 : 120),
            maxHeight: 140,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _promotions[_currentIndex].color,
                _promotions[_currentIndex].color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(SwiftLyftTheme.isWeb ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: _promotions[_currentIndex].color.withValues(alpha: 0.2),
                blurRadius: SwiftLyftTheme.isWeb ? 20 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.all(isVeryNarrow ? 12 : (isNarrow ? 16 : 20)),
              child: _buildContent(constraints, isNarrow, isVeryNarrow),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BoxConstraints constraints, bool isNarrow, bool isVeryNarrow) {
    if (isVeryNarrow || constraints.maxWidth < 200) {
      // Very compact layout for extremely narrow spaces
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _promotions[_currentIndex].icon,
            color: SwiftLyftTheme.pureWhite,
            size: 24,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              _promotions[_currentIndex].title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: SwiftLyftTheme.pureWhite,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Claim',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: SwiftLyftTheme.pureWhite,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Icon
        if (!isNarrow) ...[
          Container(
            width: isNarrow ? 40 : 60,
            height: isNarrow ? 40 : 60,
            decoration: BoxDecoration(
              color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _promotions[_currentIndex].icon,
              color: SwiftLyftTheme.pureWhite,
              size: isNarrow ? 20 : 30,
            ),
          ),
          SizedBox(width: isNarrow ? 12 : 16),
        ],
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _promotions[_currentIndex].title,
                  style: TextStyle(
                    fontSize: isNarrow ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: SwiftLyftTheme.pureWhite,
                  ),
                  maxLines: isNarrow ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  _promotions[_currentIndex].description,
                  style: TextStyle(
                    fontSize: isNarrow ? 12 : 14,
                    color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isNarrow) ...[
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    'Expires in ${_getTimeRemaining(_promotions[_currentIndex].endTime)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Action button
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 8 : 12,
            vertical: isNarrow ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Claim',
            style: TextStyle(
              fontSize: isNarrow ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: SwiftLyftTheme.pureWhite,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeRemaining(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}

class Promotion {
  final String title;
  final String description;
  final IconData icon;
  final DateTime endTime;
  final Color color;

  Promotion({
    required this.title,
    required this.description,
    required this.icon,
    required this.endTime,
    required this.color,
  });
} 