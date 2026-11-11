import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'brand_motifs.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String? message;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final subText = message ?? subtitle;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.0,
              height: 84.0,
              decoration: BoxDecoration(
                color: AppColors.soil100,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.soil200, width: 1.5),
              ),
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        size: 40.0,
                        color: AppColors.soil600,
                      )
                    : const SeedSproutMotif(size: 48.0),
              ),
            ),
            const SizedBox(height: 18.0),
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (subText != null) ...[
              const SizedBox(height: 8.0),
              Text(
                subText,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20.0),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 200.0,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

