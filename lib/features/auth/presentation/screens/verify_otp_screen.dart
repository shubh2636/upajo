import 'dart:async';
import 'package:flutter/foundation.dart';
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
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
      }
    });
  }

  void _onVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _otpController.text.trim();
    final result = await ref.read(authControllerProvider.notifier).verifyOtp(token);

    if (!mounted) return;

    if (result == true) {
      final profile = ref.read(authControllerProvider).userProfile;
      if (profile == null ||
          ((profile.villageOrCity?.isEmpty ?? true) && (profile.district?.isEmpty ?? true))) {
        context.go(RouteNames.onboarding);
      } else if (profile.isFarmer) {
        context.go(RouteNames.farmerDashboard);
      } else if (profile.isAdmin) {
        context.go(RouteNames.admin);
      } else {
        context.go(RouteNames.consumerHome);
      }
    } else if (result == null) {
      // New user without role selected
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

  void _onResendOtp() async {
    final phone = ref.read(authControllerProvider).pendingPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('मोबाइल नंबर उपलब्ध नहीं है, कृपया दोबारा लॉगिन करें'),
          backgroundColor: AppColors.clay500,
        ),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).sendOtp(phone);
    if (!mounted) return;

    if (success) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('नया ओटीपी सफलतापूर्वक भेजा गया (OTP Resent)'),
          backgroundColor: AppColors.primary600,
        ),
      );
    } else {
      final err = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'ओटीपी पुनः भेजने में त्रुटि हुई'),
          backgroundColor: AppColors.clay500,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final phone = authState.pendingPhone ?? '';

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
                  phone.isNotEmpty
                      ? '${'auth.otp_subtitle'.tr()} +91 $phone'
                      : 'auth.otp_subtitle'.tr(),
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24.0),

                // Non-production test banner (strictly disabled in release mode)
                if (kDebugMode && AuthRepositoryImpl.allowDemoAuth) ...[
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
                          'डेवलपमेंट टेस्ट कोड: 123456 (Debug Only)',
                          style: TextStyle(
                            fontSize: 12.0,
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
                        label: '6 अंकों का ओटीपी (6-Digit OTP)',
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
                    onPressed: _cooldownSeconds > 0 ? null : _onResendOtp,
                    icon: const Icon(Icons.refresh_rounded, size: 20.0, color: AppColors.primary500),
                    label: Text(
                      _cooldownSeconds > 0
                          ? 'पुनः ओटीपी भेजें (${_cooldownSeconds}s)'
                          : 'auth.resend_otp'.tr(),
                      style: AppTypography.buttonMedium.copyWith(
                        color: _cooldownSeconds > 0 ? AppColors.soil400 : AppColors.primary500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security_rounded, size: 16.0, color: AppColors.primary500),
                    const SizedBox(width: 6.0),
                    Text(
                      'अधिकतम 5 प्रयास • 15 मिनट सुरक्षा लॉक',
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
