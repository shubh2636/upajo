import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'farmer'; // 'farmer' or 'consumer'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
    if (score <= 1) return 'कमजोर (Weak)';
    if (score <= 3) return 'मध्यम (Fair)';
    return 'मजबूत (Strong)';
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signUpWithPassword(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      // Send SMS OTP for initial phone verification
      await controller.sendOtp(_phoneController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('पंजीकरण सफल! कृपया फोन सत्यापन हेतु एसएमएस ओटीपी दर्ज करें।'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push(RouteNames.verifyOtp);
      }
    } else {
      final error = ref.read(authControllerProvider).errorMessage ?? 'पंजीकरण विफल रहा';
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
        title: const Text('खाता बनाएं (Sign Up)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  'उपजो में आपका स्वागत है!',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'सीधे उपज बेचने या खरीदने के लिए पंजीकरण करें',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Role Selector (Farmer vs Customer)
                Text(
                  'आप किस रूप में जुड़ना चाहते हैं? (Select Role)',
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
                                'किसान (Farmer)',
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
                                'ग्राहक (Customer)',
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
                  label: 'पूरा नाम (Full Name)',
                  hintText: 'उदा. रामेश्वर पाटीदार',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'कृपया अपना पूरा नाम दर्ज करें';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Field
                AppTextField(
                  label: 'मोबाइल नंबर (Phone Number)',
                  hintText: '9876543210',
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
                      return 'कृपया 10 अंकों का वैध भारतीय मोबाइल नंबर दर्ज करें';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                AppTextField(
                  label: 'पासवर्ड (Password, min 8 chars)',
                  hintText: 'न्यूनतम 8 अक्षर',
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
                      return 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';
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
                  label: 'पासवर्ड की पुष्टि करें (Confirm Password)',
                  hintText: 'पासवर्ड पुनः दर्ज करें',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'पासवर्ड मेल नहीं खाते हैं (Passwords do not match)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                AppButton(
                  text: 'ओटीपी प्राप्त करें व आगे बढ़ें (Register)',
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
                      'पहले से खाता है? ',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: () => context.pushReplacement(RouteNames.login),
                      child: Text(
                        'लॉग इन करें (Log In)',
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

