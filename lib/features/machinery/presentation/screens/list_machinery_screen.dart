import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/machinery_controller.dart';
import '../../domain/models/machinery_model.dart';

class ListMachineryScreen extends ConsumerStatefulWidget {
  const ListMachineryScreen({super.key});

  @override
  ConsumerState<ListMachineryScreen> createState() => _ListMachineryScreenState();
}

class _ListMachineryScreenState extends ConsumerState<ListMachineryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleHiController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _hpController = TextEditingController(text: '45');
  final _yearController = TextEditingController(text: '2022');
  final _hourlyRateController = TextEditingController(text: '500');
  final _dailyRateController = TextEditingController(text: '3000');
  final _depositController = TextEditingController(text: '1500');
  final _villageController = TextEditingController();
  final _districtController = TextEditingController(text: 'सीहोर');

  String _selectedType = 'tractor';
  static const _uuid = Uuid();

  final List<Map<String, String>> _types = [
    {'id': 'tractor', 'label': 'ट्रैक्टर (Tractor)'},
    {'id': 'rotavator', 'label': 'रोटावेटर (Rotavator)'},
    {'id': 'harvester', 'label': 'हार्वेस्टर (Harvester)'},
    {'id': 'drone_sprayer', 'label': 'ड्रोन स्प्रेयर (Drone)'},
    {'id': 'seed_drill', 'label': 'सीड ड्रिल (Seed Drill)'},
    {'id': 'thresher', 'label': 'थ्रेशर (Thresher)'},
  ];

  @override
  void dispose() {
    _titleHiController.dispose();
    _titleEnController.dispose();
    _hpController.dispose();
    _yearController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _depositController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authControllerProvider).userProfile;
    final ownerId = user?.id ?? 'demo_owner_id';

    final machine = MachineryModel(
      id: _uuid.v4(),
      ownerId: ownerId,
      ownerName: user?.fullName ?? 'सत्यापित किसान',
      ownerPhone: user?.phoneNumber ?? '9876543210',
      titleHi: _titleHiController.text.trim(),
      titleEn: _titleEnController.text.trim().isNotEmpty
          ? _titleEnController.text.trim()
          : _titleHiController.text.trim(),
      machineryType: _selectedType,
      modelYear: int.tryParse(_yearController.text) ?? 2022,
      hp: int.tryParse(_hpController.text) ?? 45,
      hourlyRate: double.tryParse(_hourlyRateController.text) ?? 500.0,
      dailyRate: double.tryParse(_dailyRateController.text) ?? 3000.0,
      securityDeposit: double.tryParse(_depositController.text) ?? 1500.0,
      images: [
        'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600',
      ],
      villageOrCity: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : 'श्यामपुर',
      district: _districtController.text.trim().isNotEmpty ? _districtController.text.trim() : 'सीहोर',
      state: 'मध्य प्रदेश',
    );

    final success = await ref.read(machineryControllerProvider.notifier).listNewMachinery(machine);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('आपका कृषि यंत्र सफलतापूर्वक किराए के लिए सूचीबद्ध हो गया!'),
          backgroundColor: AppColors.primary600,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(machineryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: const Text('यंत्र किराए पर दें', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('यंत्र की जानकारी', style: AppTypography.headlineSmall.copyWith(fontSize: 17.0)),
                    const SizedBox(height: 16.0),

                    // Machinery Type Dropdown
                    const Text('यंत्र का प्रकार', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                    const SizedBox(height: 6.0),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                      items: _types.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['label']!))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14.0),

                    // Title Hindi
                    AppTextField(
                      label: 'यंत्र का नाम (हिंदी में)',
                      hint: 'उदा. स्वराज 855 FE 52 HP',
                      controller: _titleHiController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'कृपया नाम दर्ज करें' : null,
                    ),
                    const SizedBox(height: 14.0),

                    // Title English
                    AppTextField(
                      label: 'नाम (अंग्रेजी में)',
                      hint: 'e.g. Swaraj 855 FE 52HP',
                      controller: _titleEnController,
                    ),
                    const SizedBox(height: 14.0),

                    // HP & Year Row
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'हॉर्सपावर (HP)',
                            hint: '45',
                            keyboardType: TextInputType.number,
                            controller: _hpController,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AppTextField(
                            label: 'मॉडल वर्ष',
                            hint: '2023',
                            keyboardType: TextInputType.number,
                            controller: _yearController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Rates & Deposit Card
              AppCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('किराया दर व जमानत (Pricing)', style: AppTypography.headlineSmall.copyWith(fontSize: 17.0)),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'प्रति दिन दर (₹/दिन)',
                            hint: '3000',
                            keyboardType: TextInputType.number,
                            controller: _dailyRateController,
                            validator: (val) => val == null || val.isEmpty ? 'दैनिक दर भरें' : null,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AppTextField(
                            label: 'प्रति घंटा दर (₹/घंटा)',
                            hint: '500',
                            keyboardType: TextInputType.number,
                            controller: _hourlyRateController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    AppTextField(
                      label: 'जमानत राशि (Security Deposit ₹)',
                      hint: '1500',
                      keyboardType: TextInputType.number,
                      controller: _depositController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Location Card
              AppCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('यंत्र की लोकेशन', style: AppTypography.headlineSmall.copyWith(fontSize: 17.0)),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: 'गाँव या कस्बा',
                      hint: 'उदा. श्यामपुर',
                      controller: _villageController,
                    ),
                    const SizedBox(height: 14.0),
                    AppTextField(
                      label: 'जिला',
                      hint: 'सीहोर',
                      controller: _districtController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Submit Button
              AppButton(
                label: 'यंत्र प्रकाशित करें',
                isLoading: state.isLoading,
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22.0),
              ),
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}

