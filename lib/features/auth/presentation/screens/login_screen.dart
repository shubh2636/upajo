import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final success = await ref.read(authControllerProvider.notifier).sendOtp(phone);

    if (mounted) {
      if (success) {
        context.push(RouteNames.verifyOtp);
      } else {
        final err = ref.read(authControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err ?? 'auth.invalid_phone'.tr()),
            backgroundColor: AppColors.clay500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.soil800),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon Header
                Center(
                  child: Container(
                    width: 72.0,
                    height: 72.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary300, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.phone_android_rounded,
                        size: 38.0,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                Text(
                  'auth.welcome_title'.tr(),
                  style: AppTypography.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6.0),
                Text(
                  'auth.welcome_subtitle'.tr(),
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36.0),

                // Bento Input Container
                AppCard(
                  padding: const EdgeInsets.all(20.0),
                  borderRadius: 20.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _phoneController,
                        label: 'auth.phone_label'.tr(),
                        hintText: 'auth.phone_hint'.tr(),
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🇮🇳 +91',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.0,
                                  color: AppColors.soil800,
                                ),
                              ),
                              SizedBox(width: 8.0),
                              VerticalDivider(
                                color: AppColors.soil300,
                                thickness: 1.5,
                                indent: 14,
                                endIndent: 14,
                              ),
                            ],
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length != 10) {
                            return 'auth.invalid_phone'.tr();
                          }
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                            return 'auth.invalid_phone'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      AppButton(
                        label: 'auth.send_otp'.tr(),
                        onPressed: _onSendOtp,
                        isLoading: authState.isLoading,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 22.0),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security_rounded, size: 16.0, color: AppColors.primary500),
                    const SizedBox(width: 6.0),
                    Text(
                      '100% सुरक्षित एवं आधिकारिक भारतीय OTP सेवा',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.soil600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
