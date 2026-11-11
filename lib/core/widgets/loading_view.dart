import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_motifs.dart';

class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({
    super.key,
    this.message,
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
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 64.0,
                  height: 64.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
                  ),
                ),
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: const BoxDecoration(
                    color: AppColors.soil100,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SeedSproutMotif(size: 28.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18.0),
            Text(
              message ?? 'common.loading'.tr(),
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.soil700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


