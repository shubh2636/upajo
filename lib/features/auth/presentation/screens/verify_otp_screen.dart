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
import '../../data/repositories/auth_repository_impl.dart';
import '../controllers/auth_controller.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _otpController.text.trim();
    final result = await ref.read(authControllerProvider.notifier).verifyOtp(token);

    if (!mounted) return;

    if (result == true) {
      // Existing user profile found
      final profile = ref.read(authControllerProvider).userProfile;
      if (profile?.isFarmer == true) {
        context.go(RouteNames.farmerDashboard);
      } else if (profile?.isAdmin == true) {
        context.go(RouteNames.admin);
      } else {
        context.go(RouteNames.consumerHome);
      }
    } else if (result == null) {
      // New user -> Role Selection
      context.go(RouteNames.roleSelect);
    } else {
      final err = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'auth.invalid_otp'.tr()),
          backgroundColor: AppColors.clay500,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final phone = authState.pendingPhone ?? '9876543210';

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
                Center(
                  child: Container(
                    width: 72.0,
                    height: 72.0,
                    decoration: BoxDecoration(
                      color: AppColors.wheat100,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.wheat300, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_clock_rounded,
                        size: 38.0,
                        color: AppColors.wheat700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                Text(
                  'auth.otp_title'.tr(),
                  style: AppTypography.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6.0),
                Text(
                  '${'auth.otp_subtitle'.tr()} +91 $phone',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24.0),

                // Development test badge (omitted in production builds)
                if (AuthRepositoryImpl.allowDemoAuth) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.primary200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'डेमो टेस्ट कोड (Demo Code): 123456',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _otpController.text = '123456';
                          },
                          child: const Text('स्वतः भरें', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],

                AppCard(
                  padding: const EdgeInsets.all(20.0),
                  borderRadius: 20.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _otpController,
                        hintText: '• • • • • •',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().length != 6) {
                            return 'auth.invalid_otp'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      AppButton(
                        label: 'auth.verify_otp'.tr(),
                        onPressed: _onVerify,
                        isLoading: authState.isLoading,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 22.0),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).sendOtp(phone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('नया ओटीपी भेजा गया (OTP Resent)')),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20.0, color: AppColors.primary500),
                    label: Text(
                      'auth.resend_otp'.tr(),
                      style: AppTypography.buttonMedium.copyWith(
                        color: AppColors.primary500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

