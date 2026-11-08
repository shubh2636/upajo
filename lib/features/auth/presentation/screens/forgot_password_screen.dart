import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
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
    if (strength <= 0.25) return 'कमजोर (Weak)';
    if (strength <= 0.6) return 'मध्यम (Fair)';
    if (strength <= 0.8) return 'अच्छा (Good)';
    return 'बेहद सुरक्षित (Strong)';
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
        const SnackBar(
          content: Text('कृपया मान्य 10 अंकों का मोबाइल नंबर दर्ज करें (Invalid Phone Number)'),
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
        const SnackBar(
          content: Text('ओटीपी आपके मोबाइल पर भेज दिया गया है (OTP Sent)'),
          backgroundColor: AppColors.primary600,
        ),
      );
    } else {
      final err = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'ओटीपी भेजने में असमर्थ, कृपया पुनः प्रयास करें'),
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
        const SnackBar(
          content: Text('पासवर्ड सफलतापूर्वक बदल गया! कृपया लॉगिन करें। (Password Reset Success)'),
          backgroundColor: AppColors.primary600,
        ),
      );
      context.go(RouteNames.login);
    } else {
      final err = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'पासवर्ड रीसेट करने में विफल (Password Reset Failed)'),
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

                const Text(
                  'पासवर्ड रीसेट (Reset Password)',
                  style: AppTypography.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'अपना पंजीकृत मोबाइल नंबर दर्ज करें और ओटीपी सत्यापित करें',
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
                        label: 'मोबाइल नंबर (Mobile Number)',
                        hintText: '10 अंकों का मोबाइल नंबर',
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
                            return 'कृपया 10 अंकों का फोन नंबर भरें';
                          }
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                            return 'मान्य भारतीय मोबाइल नंबर भरें';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      if (!_otpSent) ...[
                        AppButton(
                          label: 'ओटीपी भेजें (Send OTP)',
                          onPressed: _onSendOtp,
                          isLoading: authState.isLoading,
                          icon: const Icon(Icons.send_rounded, size: 20.0),
                        ),
                      ] else ...[
                        AppTextField(
                          controller: _otpController,
                          label: 'ओटीपी दर्ज करें (Enter 6-Digit OTP)',
                          hintText: '• • • • • •',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().length != 6) {
                              return 'मान्य 6 अंकों का ओटीपी दर्ज करें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        AppTextField(
                          controller: _newPasswordController,
                          label: 'नया पासवर्ड (New Password)',
                          hintText: 'न्यूनतम 8 अक्षर',
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
                              return 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';
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
                          label: 'पासवर्ड की पुष्टि करें (Confirm Password)',
                          hintText: 'नया पासवर्ड पुनः दर्ज करें',
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
                              return 'पासवर्ड मेल नहीं खा रहे हैं';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),

                        AppButton(
                          label: 'पासवर्ड रीसेट करें (Confirm Reset)',
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
                                  ? 'पुनः ओटीपी भेजें (${_resendCooldown}s)'
                                  : 'पुनः ओटीपी भेजें (Resend OTP)',
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

