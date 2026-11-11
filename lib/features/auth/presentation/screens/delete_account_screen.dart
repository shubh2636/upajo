import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/security/screen_security.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/language_switcher_button.dart';
import '../controllers/auth_controller.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;
  bool _understandsConsequences = false;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enableSecureScreen();
  }

  @override
  void dispose() {
    ScreenSecurity.disableSecureScreen();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    final confirmation = _confirmController.text.trim().toUpperCase();
    if (confirmation != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('auth.delete_confirm_label'.tr()),
        ),
      );
      return;
    }

    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    setState(() => _isDeleting = true);
    try {
      // Call Supabase RPC to anonymize data and delete account
      await SupabaseService.client.rpc<void>(
        'delete_user_account',
        params: {'p_user_id': user.id},
      );

      // Log out locally and clear hardware-backed storage
      await ref.read(authControllerProvider.notifier).signOut();

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text('auth.delete_success_title'.tr()),
            content: Text('auth.delete_success_desc'.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(RouteNames.welcome);
                },
                child: Text('common.done'.tr()),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            content: Text('common.error'.tr()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('auth.delete_account_title'.tr()),
        backgroundColor: AppColors.soil50,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageSwitcherButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'auth.delete_account_warning_title'.tr(),
                          style: AppTypography.titleMedium.copyWith(color: Colors.red.shade900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'auth.delete_account_warning_desc'.tr(),
                          style: AppTypography.bodySmall.copyWith(color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('auth.delete_account_consequences_title'.tr(), style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildBulletPoint('auth.delete_point_1'.tr()),
            _buildBulletPoint('auth.delete_point_2'.tr()),
            _buildBulletPoint('auth.delete_point_3'.tr()),
            _buildBulletPoint('auth.delete_point_4'.tr()),
            const SizedBox(height: 20),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.error,
              value: _understandsConsequences,
              onChanged: (val) => setState(() => _understandsConsequences = val ?? false),
              title: Text(
                'auth.delete_consent'.tr(),
                style: AppTypography.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            if (_understandsConsequences) ...[
              AppTextField(
                controller: _confirmController,
                label: 'auth.delete_confirm_label'.tr(),
                hintText: 'DELETE',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'auth.delete_button'.tr(),
                variant: ButtonVariant.primary,
                isLoading: _isDeleting,
                onPressed: _handleDeleteAccount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18, color: AppColors.soil800)),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
