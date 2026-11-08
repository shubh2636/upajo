import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isHindi = context.locale.languageCode == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Language Switcher Bar
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () {
                    final newLocale = isHindi ? const Locale('en') : const Locale('hi');
                    context.setLocale(newLocale);
                  },
                  icon: const Icon(Icons.language, color: AppColors.primary, size: 20),
                  label: Text(
                    isHindi ? 'English' : 'हिंदी',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),

              // Brand Icon & Hero Title
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'उपजो (Upajo)',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'सीधे खेत से घर तक — 100% शुद्ध एवं पारदर्शी',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Direct Farmer-to-Consumer Marketplace & AI Farming Companion',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    text: 'नया खाता बनाएं (Sign Up)',
                    variant: ButtonVariant.primary,
                    icon: Icons.person_add_outlined,
                    onPressed: () => context.push(RouteNames.signup),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'लॉग इन करें (Log In)',
                    variant: ButtonVariant.outline,
                    icon: Icons.login,
                    onPressed: () => context.push(RouteNames.login),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'आगे बढ़कर आप हमारी गोपनीयता नीति और सेवा शर्तों से सहमत होते हैं।',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

