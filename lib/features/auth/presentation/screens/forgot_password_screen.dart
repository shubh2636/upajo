import 'dart:async';
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
import '../../../../core/widgets/language_switcher_button.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.15;
    return strength.clamp(0.0, 1.0);
  }

  String _getPasswordStrengthLabel(double strength) {
    if (strength <= 0.25) return 'auth.password_strength_weak'.tr();
    if (strength <= 0.6) return 'auth.password_strength_fair'.tr();
    if (strength <= 0.8) return 'auth.password_strength_good'.tr();
    return 'auth.password_strength_strong'.tr();
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength <= 0.25) return AppColors.clay500;
    if (strength <= 0.6) return AppColors.wheat600;
    if (strength <= 0.8) return AppColors.primary500;
    return AppColors.primary600;
  }

  void _onSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.invalid_phone'.tr()),
          backgroundColor: AppColors.clay500,
        ),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).sendOtp(phone);
    if (!mounted) return;

    if (success) {
      setState(() => _otpSent = true);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.otp_sent_success'.tr()),
          backgroundColor: AppColors.primary600,
        ),
      );
    } else {
      final err = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'auth.otp_send_failed'.tr()),
          backgroundColor: AppColors.clay500,
        ),
      );
    }
  }

  void _onResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text;

    final success = await ref.read(authControllerProvider.notifier).resetPasswordWithOtp(
          phone: phone,
          otpToken: otp,
          newPassword: newPassword,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.password_reset_success'.tr()),
          backgroundColor: AppColors.primary600,
        ),
      );
      context.go(RouteNames.login);
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
    final strength = _calculatePasswordStrength(_newPasswordController.text);

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.soil800),
          onPressed: () => context.pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageSwitcherButton(),
          ),
        ],
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
                        Icons.lock_reset_rounded,
                        size: 38.0,
                        color: AppColors.wheat700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                Text(
                  'auth.reset_password_title'.tr(),
                  style: AppTypography.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6.0),
                Text(
                  'auth.reset_password_subtitle'.tr(),
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28.0),

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
                        enabled: !_otpSent,
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

                      if (!_otpSent) ...[
                        AppButton(
                          label: 'auth.send_verification_code'.tr(),
                          onPressed: _onSendOtp,
                          isLoading: authState.isLoading,
                          icon: const Icon(Icons.send_rounded, size: 20.0),
                        ),
                      ] else ...[
                        AppTextField(
                          controller: _otpController,
                          label: 'auth.otp_title'.tr(),
                          hintText: '• • • • • •',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().length != 6) {
                              return 'auth.invalid_otp'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        AppTextField(
                          controller: _newPasswordController,
                          label: 'auth.new_password'.tr(),
                          hintText: 'auth.new_password_hint'.tr(),
                          obscureText: _obscureNewPassword,
                          onChanged: (_) => setState(() {}),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.soil500,
                            ),
                            onPressed: () {
                              setState(() => _obscureNewPassword = !_obscureNewPassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'auth.password_min_length'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6.0),

                        if (_newPasswordController.text.isNotEmpty) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: LinearProgressIndicator(
                                    value: strength,
                                    backgroundColor: AppColors.soil200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getPasswordStrengthColor(strength),
                                    ),
                                    minHeight: 6.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                _getPasswordStrengthLabel(strength),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: _getPasswordStrengthColor(strength),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14.0),
                        ],

                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'auth.confirm_password'.tr(),
                          hintText: 'auth.confirm_password_hint'.tr(),
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.soil500,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                          validator: (value) {
                            if (value != _newPasswordController.text) {
                              return 'auth.passwords_do_not_match'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),

                        AppButton(
                          label: 'auth.update_password_button'.tr(),
                          onPressed: _onResetPassword,
                          isLoading: authState.isLoading,
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 22.0),
                        ),
                        const SizedBox(height: 16.0),

                        Center(
                          child: TextButton.icon(
                            onPressed: _resendCooldown > 0 ? null : _onSendOtp,
                            icon: const Icon(Icons.refresh_rounded, size: 18.0),
                            label: Text(
                              _resendCooldown > 0
                                  ? 'auth.resend_in_seconds'.tr(namedArgs: {'seconds': _resendCooldown.toString()})
                                  : 'auth.resend_otp'.tr(),
                            ),
                          ),
                        ),
                      ],
                    ],
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
