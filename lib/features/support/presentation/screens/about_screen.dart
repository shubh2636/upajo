import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/brand_motifs.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppAppBar(
        title: 'support.about_title'.tr(),
        showLanguageSwitcher: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Brand Logo & Badge
            Container(
              width: 96.0,
              height: 96.0,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.soil200, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.soil800.withOpacity(0.06),
                    blurRadius: 12.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: SeedSproutMotif(size: 60.0),
              ),
            ),
            const SizedBox(height: 16.0),

            // App Name & Version
            Text(
              'app_name'.tr(),
              style: AppTypography.displaySmall.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.soil900,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Version ${AppConstants.appVersion}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.soil600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12.0),

            // Official Tagline
            Text(
              'app_tagline'.tr(),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary600,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28.0),

            // Mission Statement Card
            AppCard(
              borderRadius: 16.0,
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.primary500, size: 22.0),
                      const SizedBox(width: 8.0),
                      Text(
                        'support.mission_title'.tr(),
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.soil900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'support.mission_desc'.tr(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.soil700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Open Source & Privacy Cards
            AppCard(
              borderRadius: 16.0,
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  _buildAboutRow(
                    icon: Icons.security_rounded,
                    title: 'support.security_privacy'.tr(),
                    subtitle: 'support.security_privacy_desc'.tr(),
                  ),
                  const Divider(color: AppColors.soil200, height: 24.0),
                  _buildAboutRow(
                    icon: Icons.code_rounded,
                    title: 'support.open_source'.tr(),
                    subtitle: 'support.open_source_desc'.tr(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Copyright Footer
            Text(
              '© 2026 Upajo Technologies. All rights reserved.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.soil500, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary600, size: 24.0),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.soil900,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(color: AppColors.soil600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

