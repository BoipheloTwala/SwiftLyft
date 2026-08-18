import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.height = 20,
    this.width = double.infinity,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                SwiftLyftTheme.lightGray,
                SwiftLyftTheme.mediumGray.withValues(alpha: 0.3),
                SwiftLyftTheme.lightGray,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

class VehicleCardSkeleton extends StatelessWidget {
  const VehicleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(height: 200, borderRadius: 16),
            SizedBox(height: 16),
            SkeletonLoader(height: 20, width: 150),
            SizedBox(height: 8),
            SkeletonLoader(height: 16, width: 100),
            SizedBox(height: 12),
            SkeletonLoader(height: 14, width: double.infinity),
            SizedBox(height: 8),
            SkeletonLoader(height: 14, width: 200),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: SkeletonLoader(height: 40)),
                SizedBox(width: 12),
                Expanded(child: SkeletonLoader(height: 40)),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 