import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final VoidCallback? onTap;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.2,
    this.borderRadius = 16.0,
    this.onTap,
    this.elevation = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? AppColors.soil200,
      width: borderWidth,
    );

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.soil800.withOpacity(0.04),
                  blurRadius: 8.0,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: child,
    );

    Widget effectiveCard = card;
    if (onTap != null) {
      effectiveCard = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: effectiveCard,
      );
    }

    return effectiveCard;
  }
}

