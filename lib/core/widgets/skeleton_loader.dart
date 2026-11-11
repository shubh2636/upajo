import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Earthy shimmer skeleton loader for content placeholders
class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
  });

  const AppSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 110.0,
    this.borderRadius = 16.0,
  }) : shape = BoxShape.rectangle;

  const AppSkeleton.text({
    super.key,
    this.width = 140.0,
    this.height = 16.0,
    this.borderRadius = 4.0,
  }) : shape = BoxShape.rectangle;

  const AppSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
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
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.soil100,
              AppColors.soil200,
              _animation.value,
            ),
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
          ),
        );
      },
    );
  }
}

