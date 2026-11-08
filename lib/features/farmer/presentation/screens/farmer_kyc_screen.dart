import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/security/screen_security.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
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

  String _soilType = 'काली मिट्टी (Black Soil)';
  File? _idDocFile;
  String? _uploadedDocUrl;
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
            _soilType = (data['soil_type'] as String?) ?? 'काली मिट्टी (Black Soil)';
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
      // 1. Upload ID document to PRIVATE bucket kyc-docs if selected
      if (_idDocFile != null) {
        final ext = _idDocFile!.path.split('.').last;
        final docPath = '${user.id}/id_document_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await SupabaseService.client.storage.from('kyc-docs').upload(docPath, _idDocFile!);
        _uploadedDocUrl = docPath;
      }

      // 2. Upsert farmer_profiles
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

      // 3. Mark profile kyc_status as pending
      await SupabaseService.client.from('profiles').update({
        'kyc_status': 'pending',
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC दस्तावेज़ सफलतापूर्वक जमा किए गए! सत्यापन प्रगति पर है।'),
            backgroundColor: AppColors.primary600,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटि: $e'),
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
        title: const Text('किसान KYC सत्यापन (KYC-Lite)', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
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
                                      ? 'KYC स्वीकृत (Verified Farmer)'
                                      : kycStatus == 'rejected'
                                          ? 'KYC अस्वीकृत (Rejected)'
                                          : 'KYC समीक्षाधीन (Pending Approval)',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.0),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  kycStatus == 'verified' || kycStatus == 'approved'
                                      ? 'आप असीमित फसलें सीधे ग्राहकों को बेच सकते हैं।'
                                      : kycStatus == 'rejected'
                                          ? 'कृपया सही पहचान पत्र व बैंक विवरण पुनः दर्ज करें।'
                                          : 'दस्तावेज़ जमा हो चुके हैं, 24 घंटे में सत्यापन हो जाएगा।',
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
                          const Text('खेत व भूमि विवरण (Farm Info)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.0)),
                          const SizedBox(height: 14.0),
                          AppTextField(
                            controller: _farmNameController,
                            label: 'खेत या फार्म का नाम (Farm Name)',
                            hintText: 'उदा. राम गोपाल फार्म',
                            validator: (v) => (v == null || v.isEmpty) ? 'खेत का नाम भरें' : null,
                          ),
                          const SizedBox(height: 12.0),
                          AppTextField(
                            controller: _acresController,
                            label: 'कुल भूमि (एकड़ में / Total Acres)',
                            hintText: 'उदा. 3.5',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => (v == null || v.isEmpty) ? 'भूमि का क्षेत्रफल भरें' : null,
                          ),
                          const SizedBox(height: 12.0),
                          DropdownButtonFormField<String>(
                            value: _soilType,
                            decoration: const InputDecoration(
                              labelText: 'मिट्टी का प्रकार (Soil Type)',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'काली मिट्टी (Black Soil)', child: Text('काली मिट्टी (Black Soil)')),
                              DropdownMenuItem(value: 'जलोढ़ मिट्टी (Alluvial)', child: Text('जलोढ़ मिट्टी (Alluvial)')),
                              DropdownMenuItem(value: 'लाल-पीली मिट्टी (Red/Yellow)', child: Text('लाल-पीली मिट्टी (Red/Yellow)')),
                              DropdownMenuItem(value: 'दोमट मिट्टी (Loamy Soil)', child: Text('दोमट मिट्टी (Loamy Soil)')),
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
                          const Text('पहचान पत्र अपलोड (Aadhaar / KCC)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.0)),
                          const SizedBox(height: 6.0),
                          const Text('दस्तावेज़ पूर्णतः सुरक्षित व निजी Supabase बकेट में संग्रहीत होगा।', style: TextStyle(fontSize: 12.0, color: AppColors.soil600)),
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
                              label: const Text('आधार कार्ड / किसान क्रेडिट कार्ड फोटो चुनें', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          if (_idDocFile != null)
                            TextButton.icon(
                              onPressed: _pickDocument,
                              icon: const Icon(Icons.change_circle_rounded, size: 18.0),
                              label: const Text('दस्तावेज़ बदलें'),
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
                          const Text('भुगतान खाता (Payout Bank & UPI)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.0)),
                          const SizedBox(height: 14.0),
                          AppTextField(
                            controller: _holderController,
                            label: 'खाताधारक का नाम (Account Holder Name)',
                            hintText: 'बैंक पासबुक अनुसार नाम',
                            validator: (v) => (v == null || v.isEmpty) ? 'नाम भरें' : null,
                          ),
                          const SizedBox(height: 12.0),
                          AppTextField(
                            controller: _accountController,
                            label: 'बैंक खाता संख्या (Account Number)',
                            hintText: 'उदा. 919293949596',
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.isEmpty) ? 'खाता संख्या भरें' : null,
                          ),
                          const SizedBox(height: 12.0),
                          AppTextField(
                            controller: _ifscController,
                            label: 'बैंक IFSC कोड',
                            hintText: 'उदा. SBIN0001234',
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) {
                              if (v == null || v.length != 11) {
                                return 'मान्य 11 अक्षरों का IFSC भरें';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12.0),
                          AppTextField(
                            controller: _upiController,
                            label: 'UPI आईडी / VPA (वैकल्पिक)',
                            hintText: 'उदा. 9876543210@upi',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Submit Button
                    AppButton(
                      label: 'KYC विवरण जमा करें (Submit KYC)',
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
