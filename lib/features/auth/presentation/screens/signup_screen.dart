import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/language_switcher_button.dart';
import '../controllers/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'farmer'; // 'farmer' or 'consumer'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password strength calculation
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength; // 0 to 5
  }

  Color _getStrengthColor(int score) {
    if (score <= 1) return AppColors.error;
    if (score <= 3) return Colors.orange;
    return AppColors.success;
  }

  String _getStrengthLabel(int score) {
    if (score == 0) return '';
    if (score <= 1) return 'auth.password_strength_weak'.tr();
    if (score <= 3) return 'auth.password_strength_fair'.tr();
    return 'auth.password_strength_strong'.tr();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signUpWithPassword(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final profile = ref.read(authControllerProvider).userProfile;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.signup_success'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        if (profile == null ||
            ((profile.villageOrCity?.isEmpty ?? true) && (profile.district?.isEmpty ?? true))) {
          context.go(RouteNames.onboarding);
        } else if (profile.isFarmer) {
          context.go(RouteNames.farmerDashboard);
        } else {
          context.go(RouteNames.consumerHome);
        }
      }
    } else {
      final error = ref.read(authControllerProvider).errorMessage ?? 'auth.signup_failed'.tr();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final passwordScore = _calculatePasswordStrength(_passwordController.text);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('auth.signup_title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageSwitcherButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'auth.signup_welcome'.tr(),
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'auth.signup_subtitle'.tr(),
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                // Notice: Phone is not SMS verified
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primaryDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Phone number is registered with password auth. Phone is NOT SMS-verified. Password reset by SMS is unavailable until an SMS gateway is configured.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Role Selector (Farmer vs Customer)
                Text(
                  'auth.select_role_prompt'.tr(),
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'farmer'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'farmer'
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'farmer' ? AppColors.primary : AppColors.outline,
                              width: _selectedRole == 'farmer' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.agriculture,
                                color: _selectedRole == 'farmer' ? AppColors.primary : AppColors.onSurfaceVariant,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'auth.role_farmer'.tr(),
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == 'farmer' ? AppColors.primary : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'consumer'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'consumer'
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'consumer' ? AppColors.primary : AppColors.outline,
                              width: _selectedRole == 'consumer' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_basket,
                                color: _selectedRole == 'consumer' ? AppColors.primary : AppColors.onSurfaceVariant,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'auth.role_consumer'.tr(),
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == 'consumer' ? AppColors.primary : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name Field
                AppTextField(
                  label: 'auth.full_name'.tr(),
                  hintText: 'auth.full_name_hint'.tr(),
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'auth.full_name_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Field
                AppTextField(
                  label: 'auth.phone_label'.tr(),
                  hintText: 'auth.phone_hint'.tr(),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    width: 60,
                    child: Text(
                      '+91',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  validator: (val) {
                    final cleaned = (val ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (cleaned.length != 10 || !RegExp(r'^[6-9]').hasMatch(cleaned)) {
                      return 'auth.invalid_phone'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field (OPTIONAL)
                AppTextField(
                  label: 'Email (Optional / ऐच्छिक)',
                  hintText: 'kisan@example.com (optional)',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'कृपया वैध ईमेल दर्ज करें (Enter valid email or leave blank)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                AppTextField(
                  label: 'auth.password_label'.tr(),
                  hintText: 'auth.password_hint'.tr(),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  onChanged: (val) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.length < 8) {
                      return 'auth.password_min_length'.tr();
                    }
                    return null;
                  },
                ),

                // Password Strength Meter
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: passwordScore / 5.0,
                            backgroundColor: AppColors.outline.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(passwordScore)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getStrengthLabel(passwordScore),
                        style: AppTypography.labelSmall.copyWith(
                          color: _getStrengthColor(passwordScore),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Confirm Password Field
                AppTextField(
                  label: 'auth.confirm_password'.tr(),
                  hintText: 'auth.confirm_password_hint'.tr(),
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'auth.passwords_do_not_match'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                AppButton(
                  label: 'auth.signup_submit'.tr(),
                  variant: ButtonVariant.primary,
                  isLoading: authState.isLoading,
                  onPressed: _handleSignUp,
                ),
                const SizedBox(height: 16),

                // Switch to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.already_have_account'.tr(),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () => context.pushReplacement(RouteNames.login),
                      child: Text(
                        'auth.login_button'.tr(),
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
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
