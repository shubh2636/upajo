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
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOtpMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authControllerProvider.notifier).signInWithPassword(
          phone: phone,
          password: password,
        );

    if (!mounted) return;

    if (success) {
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
    } else {
      final err = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'अमान्य मोबाइल नंबर या पासवर्ड (Invalid Credentials)'),
          backgroundColor: AppColors.clay500,
        ),
      );
    }
  }

  void _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final success = await ref.read(authControllerProvider.notifier).sendOtp(phone);

    if (!mounted) return;

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.welcome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
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
                      color: AppColors.primary100,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary300, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 38.0,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                Text(
                  'auth.welcome_title'.tr(),
                  style: AppTypography.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6.0),
                Text(
                  _isOtpMode
                      ? 'अपने पंजीकृत मोबाइल नंबर से ओटीपी प्राप्त करें'
                      : 'अपने मोबाइल नंबर और पासवर्ड से लॉगिन करें',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24.0),

                // Bento Input Container
                AppCard(
                  padding: const EdgeInsets.all(20.0),
                  borderRadius: 20.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode Selector Pill Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.soil100,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _isOtpMode = false),
                                borderRadius: BorderRadius.circular(10.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  decoration: BoxDecoration(
                                    color: !_isOtpMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: !_isOtpMode
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'पासवर्ड (Password)',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: !_isOtpMode ? FontWeight.w700 : FontWeight.w500,
                                        color: !_isOtpMode ? AppColors.primary700 : AppColors.soil600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _isOtpMode = true),
                                borderRadius: BorderRadius.circular(10.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  decoration: BoxDecoration(
                                    color: _isOtpMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: _isOtpMode
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'ओटीपी (SMS OTP)',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: _isOtpMode ? FontWeight.w700 : FontWeight.w500,
                                        color: _isOtpMode ? AppColors.primary700 : AppColors.soil600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),

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
                      const SizedBox(height: 16.0),

                      if (!_isOtpMode) ...[
                        AppTextField(
                          controller: _passwordController,
                          label: 'पासवर्ड (Password)',
                          hintText: 'अपना पासवर्ड दर्ज करें',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.soil500,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया पासवर्ड दर्ज करें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(RouteNames.forgotPassword),
                            child: const Text(
                              'पासवर्ड भूल गए? (Forgot Password?)',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AppButton(
                          label: 'auth.login_button'.tr(),
                          onPressed: _onPasswordLogin,
                          isLoading: authState.isLoading,
                          icon: const Icon(Icons.login_rounded, size: 22.0),
                        ),
                      ] else ...[
                        AppButton(
                          label: 'auth.send_otp'.tr(),
                          onPressed: _onSendOtp,
                          isLoading: authState.isLoading,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 22.0),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24.0),

                // Register Navigation Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'नया खाता बनाना चाहते हैं?',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.soil700),
                    ),
                    TextButton(
                      onPressed: () => context.push(RouteNames.signup),
                      child: const Text(
                        'साइन अप करें (Sign Up)',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, size: 16.0, color: AppColors.primary500),
                    const SizedBox(width: 6.0),
                    Text(
                      '100% सुरक्षित सर्वर-साइड प्रमाणीकरण',
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
