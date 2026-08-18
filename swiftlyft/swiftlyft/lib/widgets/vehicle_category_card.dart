import 'package:flutter/material.dart';
import '../utils/theme.dart';

class VehicleCategoryCard extends StatefulWidget {
  final String name;
  final String description;
  final IconData icon;
  final int vehicleCount;
  final Color color;
  final VoidCallback onTap;

  const VehicleCategoryCard({
    super.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.vehicleCount,
    required this.color,
    required this.onTap,
  });

  @override
  State<VehicleCategoryCard> createState() => _VehicleCategoryCardState();
}

class _VehicleCategoryCardState extends State<VehicleCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _tiltAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _tiltAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                                      colors: [
                    widget.color,
                    widget.color.withValues(alpha: 0.8),
                  ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: SwiftLyftTheme.pureWhite,
                          size: 24,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Category name
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: SwiftLyftTheme.pureWhite,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Description
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.8),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Vehicle count and view button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.vehicleCount} vehicles',
                              style: TextStyle(
                                fontSize: 11,
                                color: SwiftLyftTheme.pureWhite.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
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
                            child: const Text(
                              'View',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: SwiftLyftTheme.pureWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ),
            ),
          );
        },
      ),
    );
  }
} 