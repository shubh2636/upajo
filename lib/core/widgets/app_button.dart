import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum ButtonVariant { primary, secondary, outline, danger, terracotta }

class AppButton extends StatelessWidget {
  final String? label;
  final String? text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppTheme.minTouchTargetLarge,
  }) : assert(label != null || text != null, 'Either label or text must be provided');

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppColors.primary500;
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppColors.wheat500;
        foregroundColor = AppColors.soil900;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.white;
        foregroundColor = AppColors.soil800;
        borderSide = const BorderSide(color: AppColors.soil200, width: 2.0);
        break;
      case ButtonVariant.danger:
      case ButtonVariant.terracotta:
        backgroundColor = AppColors.clay500;
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.5),
          disabledForegroundColor: foregroundColor.withOpacity(0.7),
          elevation: variant == ButtonVariant.outline ? 0 : 1.5,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.0,
                height: 24.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8.0),
                  ],
                  Text(
                    label ?? text ?? '',
                    style: AppTypography.buttonLarge.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

