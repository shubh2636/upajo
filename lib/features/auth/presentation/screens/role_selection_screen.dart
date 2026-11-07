import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/auth_controller.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final selectedRole = authState.selectedRole;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'auth.select_role_title'.tr(),
                style: AppTypography.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'अपनी आवश्यकता के अनुसार उपयुक्त विकल्प चुनें',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32.0),

              // Farmer Option Card
              AppCard(
                borderRadius: 20.0,
                borderColor: selectedRole == 'farmer'
                    ? AppColors.primary500
                    : AppColors.soil200,
                backgroundColor: selectedRole == 'farmer'
                    ? AppColors.primary50
                    : Colors.white,
                padding: const EdgeInsets.all(20.0),
                onTap: () {
                  ref.read(authControllerProvider.notifier).setSelectedRole('farmer');
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52.0,
                          height: 52.0,
                          decoration: BoxDecoration(
                            color: selectedRole == 'farmer'
                                ? AppColors.primary500
                                : AppColors.primary100,
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          child: Icon(
                            Icons.agriculture_rounded,
                            size: 32.0,
                            color: selectedRole == 'farmer'
                                ? Colors.white
                                : AppColors.primary600,
                          ),
                        ),
                        Radio<String>(
                          value: 'farmer',
                          groupValue: selectedRole,
                          activeColor: AppColors.primary500,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(authControllerProvider.notifier).setSelectedRole(val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'auth.farmer_role'.tr(),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.soil900,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      'auth.farmer_desc'.tr(),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.soil700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Consumer Option Card
              AppCard(
                borderRadius: 20.0,
                borderColor: selectedRole == 'consumer'
                    ? AppColors.primary500
                    : AppColors.soil200,
                backgroundColor: selectedRole == 'consumer'
                    ? AppColors.primary50
                    : Colors.white,
                padding: const EdgeInsets.all(20.0),
                onTap: () {
                  ref.read(authControllerProvider.notifier).setSelectedRole('consumer');
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52.0,
                          height: 52.0,
                          decoration: BoxDecoration(
                            color: selectedRole == 'consumer'
                                ? AppColors.primary500
                                : AppColors.wheat100,
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          child: Icon(
                            Icons.shopping_basket_rounded,
                            size: 32.0,
                            color: selectedRole == 'consumer'
                                ? Colors.white
                                : AppColors.wheat700,
                          ),
                        ),
                        Radio<String>(
                          value: 'consumer',
                          groupValue: selectedRole,
                          activeColor: AppColors.primary500,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(authControllerProvider.notifier).setSelectedRole(val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'auth.consumer_role'.tr(),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.soil900,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      'auth.consumer_desc'.tr(),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.soil700,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              AppButton(
                label: 'common.continue'.tr(),
                onPressed: () {
                  context.push(RouteNames.onboarding);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 22.0),
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }
}

