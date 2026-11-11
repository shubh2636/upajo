import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/security/screen_security.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/language_switcher_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class FarmerKycScreen extends ConsumerStatefulWidget {
  const FarmerKycScreen({super.key});

  @override
  ConsumerState<FarmerKycScreen> createState() => _FarmerKycScreenState();
}

class _FarmerKycScreenState extends ConsumerState<FarmerKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameController = TextEditingController();
  final _acresController = TextEditingController();
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  String _soilType = 'black_soil';
  File? _idDocFile;
  bool _isLoading = true;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enableSecureScreen();
    _loadKycData();
  }

  @override
  void dispose() {
    ScreenSecurity.disableSecureScreen();
    _farmNameController.dispose();
    _acresController.dispose();
    _holderController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _loadKycData() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user != null) {
      try {
        final data = await SupabaseService.client
            .from('farmer_profiles')
            .select('*')
            .eq('farmer_id', user.id)
            .maybeSingle();

        if (mounted && data != null) {
          setState(() {
            _farmNameController.text = (data['farm_name'] as String?) ?? '';
            _acresController.text = (data['total_acres'] != null) ? data['total_acres'].toString() : '2.5';
            _soilType = (data['soil_type'] as String?) ?? 'black_soil';
            _holderController.text = (data['bank_account_holder_name'] as String?) ?? user.fullName;
            _accountController.text = (data['bank_account_number'] as String?) ?? '';
            _ifscController.text = (data['bank_ifsc'] as String?) ?? '';
            _upiController.text = (data['upi_vpa'] as String?) ?? '';
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDocument() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _idDocFile = File(picked.path);
      });
    }
  }

  void _onSubmitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      if (_idDocFile != null) {
        final ext = _idDocFile!.path.split('.').last;
        final docPath = '${user.id}/id_document_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await SupabaseService.client.storage.from('kyc-docs').upload(docPath, _idDocFile!);
      }

      await SupabaseService.client.from('farmer_profiles').upsert({
        'farmer_id': user.id,
        'farm_name': _farmNameController.text.trim(),
        'total_acres': double.tryParse(_acresController.text.trim()) ?? 0.0,
        'soil_type': _soilType,
        'bank_account_holder_name': _holderController.text.trim(),
        'bank_account_number': _accountController.text.trim(),
        'bank_ifsc': _ifscController.text.trim().toUpperCase(),
        'upi_vpa': _upiController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await SupabaseService.client.from('profiles').update({
        'kyc_status': 'pending',
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('farmer.kyc_submitted_success'.tr()),
            backgroundColor: AppColors.primary600,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.error'.tr()),
            backgroundColor: AppColors.clay500,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).userProfile;
    final kycStatus = user?.kycStatus ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('farmer.kyc_title'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageSwitcherButton(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Badge Banner
                    AppCard(
                      padding: const EdgeInsets.all(16.0),
                      backgroundColor: kycStatus == 'verified' || kycStatus == 'approved'
                          ? AppColors.primary50
                          : kycStatus == 'rejected'
                              ? AppColors.clay50
                              : AppColors.wheat100,
                      borderColor: kycStatus == 'verified' || kycStatus == 'approved'
                          ? AppColors.primary400
                          : kycStatus == 'rejected'
                              ? AppColors.clay400
                              : AppColors.wheat400,
                      child: Row(
                        children: [
                          Icon(
                            kycStatus == 'verified' || kycStatus == 'approved'
                                ? Icons.verified_user_rounded
                                : kycStatus == 'rejected'
                                    ? Icons.error_outline_rounded
                                    : Icons.hourglass_top_rounded,
                            size: 32.0,
                            color: kycStatus == 'verified' || kycStatus == 'approved'
                                ? AppColors.primary600
                                : kycStatus == 'rejected'
                                    ? AppColors.clay500
                                    : AppColors.wheat700,
                          ),
                          const SizedBox(width: 14.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kycStatus == 'verified' || kycStatus == 'approved'
                                      ? 'farmer.kyc_status_verified'.tr()
                                      : kycStatus == 'rejected'
                                          ? 'common.rejected'.tr()
                                          : 'farmer.kyc_status_pending'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.0),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'farmer.kyc_subtitle'.tr(),
                                  style: const TextStyle(fontSize: 12.0, color: AppColors.soil700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // Farm & Land Details
                    AppCard(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('auth.farm_details'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.0)),
                          const SizedBox(height: 14.0),
                          AppTextField(
                            controller: _farmNameController,
                            label: 'auth.farm_name'.tr(),
                            hintText: 'auth.farm_name_hint'.tr(),
                            validator: (v) => (v == null || v.isEmpty) ? 'auth.required_field'.tr() : null,
                          ),
                          const SizedBox(height: 12.0),
                          AppTextField(
                            controller: _acresController,
                            label: 'auth.total_acres'.tr(),
                            hintText: 'auth.total_acres_hint'.tr(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => (v == null || v.isEmpty) ? 'auth.required_field'.tr() : null,
                          ),
                          const SizedBox(height: 12.0),
                          DropdownButtonFormField<String>(
                            value: _soilType,
                            decoration: InputDecoration(
                              labelText: 'farmer.soil_type'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(value: 'black_soil', child: Text('farmer.soil_black'.tr())),
                              DropdownMenuItem(value: 'alluvial', child: Text('farmer.soil_alluvial'.tr())),
                              DropdownMenuItem(value: 'sandy_loam', child: Text('farmer.soil_sandy_loam'.tr())),
                              DropdownMenuItem(value: 'red_soil', child: Text('farmer.soil_red'.tr())),
                              DropdownMenuItem(value: 'clay_loam', child: Text('farmer.soil_clay_loam'.tr())),
                            ],
                            onChanged: (v) => setState(() => _soilType = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // Identity Document Upload (Private Bucket)
                    AppCard(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('farmer.upload_id_doc'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.0)),
                          const SizedBox(height: 6.0),
                          Text('auth.secure_auth_note'.tr(), style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),
                          const SizedBox(height: 14.0),
                          if (_idDocFile != null)
                            Container(
                              height: 140.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                image: DecorationImage(image: FileImage(_idDocFile!), fit: BoxFit.cover),
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _pickDocument,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                                side: const BorderSide(color: AppColors.primary400, width: 1.5),
                              ),
                              icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary600),
                              label: Text('farmer.choose_file'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          if (_idDocFile != null)
                            TextButton.icon(
                              onPressed: _pickDocument,
                              icon: const Icon(Icons.change_circle_rounded, size: 18.0),
                              label: Text('farmer.choose_file'.tr()),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // Bank Account & UPI Details
                    AppCard(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('farmer.bank_details_title'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.0)),
                          const SizedBox(height: 14.0),
                          AppTextField(
                            controller: _holderController,
                            label: 'farmer.account_holder_name'.tr(),
                            hintText: 'auth.full_name_hint'.tr(),
                            validator: (v) => (v == null || v.isEmpty) ? 'auth.required_field'.tr() : null,
                          ),
                          const SizedBox(height: 12.0),
                          AppTextField(
                            controller: _accountController,
                            label: 'farmer.bank_acc'.tr(),
                            hintText: '919293949596',
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.isEmpty) ? 'auth.required_field'.tr() : null,
                          ),
                          const SizedBox(height: 12.0),
                          AppTextField(
                            controller: _ifscController,
                            label: 'farmer.ifsc_code'.tr(),
                            hintText: 'SBIN0001234',
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) {
                              if (v == null || v.length != 11) {
                                return 'errors.required_field'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12.0),
                          AppTextField(
                            controller: _upiController,
                            label: 'farmer.upi_id'.tr(),
                            hintText: '9876543210@upi',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Submit Button
                    AppButton(
                      label: 'common.submit'.tr(),
                      onPressed: _onSubmitKyc,
                      isLoading: _isSaving,
                      icon: const Icon(Icons.check_circle_rounded, size: 22.0),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
    );
  }
}
