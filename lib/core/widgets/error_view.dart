import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: BoxDecoration(
                color: AppColors.clay50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.clay200, width: 1.5),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36.0,
                color: AppColors.clay500,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'common.error'.tr(),
              style: AppTypography.headlineMedium.copyWith(color: AppColors.clay600),
              textAlign: TextAlign.center,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8.0),
              Text(
                errorMessage!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20.0),
              AppButton(
                label: 'common.retry'.tr(),
                onPressed: onRetry,
                variant: ButtonVariant.outline,
                width: 180.0,
                icon: const Icon(Icons.refresh_rounded, size: 20.0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

