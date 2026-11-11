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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authControllerProvider.notifier).signInWithPassword(
          phone: identifier,
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
          content: Text(err ?? 'गलत मोबाइल नंबर/ईमेल या पासवर्ड (Invalid mobile number/email or password)'),
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageSwitcherButton(),
          ),
        ],
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
                  'auth.login_subtitle_password'.tr(),
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
                      AppTextField(
                        controller: _identifierController,
                        label: 'Mobile Number or Email / मोबाइल या ईमेल',
                        hintText: '9876543210 or user@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.person_pin_rounded, color: AppColors.primary600),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'कृपया मोबाइल नंबर अथवा ईमेल दर्ज करें (Enter mobile or email)';
                          }
                          final val = value.trim();
                          if (val.contains('@')) {
                            if (!val.contains('.')) {
                              return 'अमान्य ईमेल पता (Invalid email format)';
                            }
                            return null;
                          }
                          final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (cleaned.length < 10) {
                            return 'कृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें (Enter 10-digit phone)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      AppTextField(
                        controller: _passwordController,
                        label: 'auth.password'.tr(),
                        hintText: 'auth.password_hint'.tr(),
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.soil600),
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
                            return 'auth.password_required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      AppButton(
                        label: 'auth.login_button'.tr(),
                        onPressed: _onPasswordLogin,
                        isLoading: authState.isLoading,
                        icon: const Icon(Icons.login_rounded, size: 22.0),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24.0),

                // Register Navigation Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.dont_have_account'.tr(),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.soil700),
                    ),
                    TextButton(
                      onPressed: () => context.push(RouteNames.signup),
                      child: Text(
                        'auth.signup_button'.tr(),
                        style: const TextStyle(
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
                      'auth.secure_auth_note'.tr(),
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
