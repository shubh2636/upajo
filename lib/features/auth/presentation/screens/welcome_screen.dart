import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/language_switcher_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32.0),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Language Switcher Bar
                      const Align(
                        alignment: Alignment.topRight,
                        child: LanguageSwitcherButton(),
                      ),

                      const Spacer(),

                      // Brand Icon & Hero Title
                      Column(
                        children: [
                          Container(
                            width: 88.0,
                            height: 88.0,
                            decoration: BoxDecoration(
                              color: AppColors.primary100,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary300, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 50.0,
                              color: AppColors.primary600,
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Text(
                            'app_name'.tr(),
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.primary800,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'auth.welcome_tagline'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.soil800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'auth.welcome_companion'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.soil600,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),
                      const SizedBox(height: 24.0),

                      // Action Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppButton(
                            label: 'auth.signup_button'.tr(),
                            variant: ButtonVariant.primary,
                            icon: const Icon(Icons.person_add_outlined, size: 22.0),
                            onPressed: () => context.push(RouteNames.signup),
                          ),
                          const SizedBox(height: 14.0),
                          AppButton(
                            label: 'auth.login_button'.tr(),
                            variant: ButtonVariant.outline,
                            icon: const Icon(Icons.login_rounded, size: 22.0),
                            onPressed: () => context.push(RouteNames.login),
                          ),
                          const SizedBox(height: 14.0),
                          Text(
                            'auth.terms_agreement'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(fontSize: 11.0, color: AppColors.soil500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
