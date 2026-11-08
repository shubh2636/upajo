import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/security/screen_security.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
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
    if (confirmation != 'DELETE' && confirmation != 'हटाएं') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('पुष्टि के लिए बॉक्स में "DELETE" अथवा "हटाएं" टाइप करें।'),
        ),
      );
      return;
    }

    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    setState(() => _isDeleting = true);
    try {
      // Call Supabase RPC to anonymize data and delete account
      await SupabaseService.client.rpc(
        'delete_user_account',
        params: {'p_user_id': user.id},
      );

      // Log out locally and clear hardware-backed storage
      await ref.read(authControllerProvider.notifier).logout();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('खाता हटा दिया गया है'),
            content: const Text(
              'आपका खाता और व्यक्तिगत डेटा सफलतापूर्वक अनामित और हटा दिया गया है। उपजो से जुड़ने के लिए धन्यवाद।',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(RouteNames.welcome);
                },
                child: const Text('ठीक है (OK)'),
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
            content: Text('खाता हटाने में असमर्थ: ${e.toString()}'),
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
        title: const Text('खाता हटाएं (Delete Account)'),
        backgroundColor: AppColors.surface,
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
                          'महत्वपूर्ण चेतावनी (Permanent Action)',
                          style: AppTypography.titleMedium.copyWith(color: Colors.red.shade900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'यह प्रक्रिया अपरिवर्तनीय है। एक बार खाता हटा दिए जाने के बाद, आपका प्रोफ़ाइल पुनः प्राप्त नहीं किया जा सकता।',
                          style: AppTypography.bodySmall.copyWith(color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('खाता हटाने पर क्या होगा? (DPDP Act 2023)', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildBulletPoint('आपका नाम, फ़ोन नंबर और पता तत्काल हटाकर अनामित कर दिया जाएगा।'),
            _buildBulletPoint('आपके सभी अपलोड किए गए KYC पहचान दस्तावेज़ तत्काल नष्ट कर दिए जाएंगे।'),
            _buildBulletPoint('आपके बैंक और UPI विवरण हटा दिए जाएंगे।'),
            _buildBulletPoint('यदि आपकी कोई फसल सूचीबद्ध है, तो वह तुरंत रोक (Pause) दी जाएगी।'),
            _buildBulletPoint('भारतीय आयकर व जीएसटी अधिनियमों के तहत केवल वित्तीय ऑडिट रिकॉर्ड्स ही अनिवार्य अवधि तक सुरक्षित रखे जाएंगे।'),
            const SizedBox(height: 20),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.error,
              value: _understandsConsequences,
              onChanged: (val) => setState(() => _understandsConsequences = val ?? false),
              title: Text(
                'मैं समझता/समझती हूँ कि यह क्रिया स्थायी है और मेरा व्यक्तिगत डेटा मिटा दिया जाएगा।',
                style: AppTypography.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            if (_understandsConsequences) ...[
              AppTextField(
                controller: _confirmController,
                label: 'पुष्टि के लिए "DELETE" अथवा "हटाएं" लिखें',
                hintText: 'DELETE',
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'मेरा खाता स्थायी रूप से हटाएं',
                variant: ButtonVariant.danger,
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
          Text('• ', style: const TextStyle(fontSize: 18, color: AppColors.textPrimary)),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

