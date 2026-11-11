import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
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
  final _districtController = TextEditingController(text: 'Sehore');

  String _selectedType = 'tractor';
  static const _uuid = Uuid();

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
      ownerName: user?.fullName ?? 'machinery.verified_farmer'.tr(),
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
      images: const [
        'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600',
      ],
      villageOrCity: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : 'machinery.default_village'.tr(),
      district: _districtController.text.trim().isNotEmpty ? _districtController.text.trim() : 'machinery.default_district'.tr(),
      state: 'machinery.state_mp'.tr(),
    );

    final success = await ref.read(machineryControllerProvider.notifier).listNewMachinery(machine);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('machinery.add_machine_success'.tr()),
          backgroundColor: AppColors.primary600,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(machineryControllerProvider);

    final types = [
      {'id': 'tractor', 'label': 'machinery.cat_tractor'.tr()},
      {'id': 'rotavator', 'label': 'machinery.cat_rotavator'.tr()},
      {'id': 'harvester', 'label': 'machinery.cat_harvester'.tr()},
      {'id': 'drone_sprayer', 'label': 'machinery.cat_drone'.tr()},
      {'id': 'seed_drill', 'label': 'machinery.cat_seed_drill'.tr()},
      {'id': 'thresher', 'label': 'machinery.cat_thresher'.tr()},
    ];

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('machinery.list_machine'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    Text('machinery.machine_info'.tr(), style: AppTypography.headlineSmall.copyWith(fontSize: 17.0)),
                    const SizedBox(height: 16.0),

                    // Machinery Type Dropdown
                    Text('machinery.machine_type'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                    const SizedBox(height: 6.0),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                      items: types.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['label']!))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14.0),

                    // Title Hindi
                    AppTextField(
                      label: 'machinery.machine_name_hi'.tr(),
                      hint: 'machinery.cat_tractor'.tr(),
                      controller: _titleHiController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'machinery.enter_name_error'.tr() : null,
                    ),
                    const SizedBox(height: 14.0),

                    // Title English
                    AppTextField(
                      label: 'machinery.machine_name_en'.tr(),
                      hint: 'machinery.cat_tractor'.tr(),
                      controller: _titleEnController,
                    ),
                    const SizedBox(height: 14.0),

                    // HP & Year Row
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'machinery.horsepower'.tr(),
                            hint: '45',
                            keyboardType: TextInputType.number,
                            controller: _hpController,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AppTextField(
                            label: 'machinery.model_year'.tr(),
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
                    Text('machinery.pricing_deposit'.tr(), style: AppTypography.headlineSmall.copyWith(fontSize: 17.0)),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'machinery.daily_rate'.tr(),
                            hint: '3000',
                            keyboardType: TextInputType.number,
                            controller: _dailyRateController,
                            validator: (val) => val == null || val.isEmpty ? 'machinery.enter_daily_rate_error'.tr() : null,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AppTextField(
                            label: 'machinery.hourly_rate'.tr(),
                            hint: '500',
                            keyboardType: TextInputType.number,
                            controller: _hourlyRateController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    AppTextField(
                      label: 'machinery.security_deposit'.tr(),
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
                    Text('machinery.machine_location'.tr(), style: AppTypography.headlineSmall.copyWith(fontSize: 17.0)),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: 'machinery.village_or_city'.tr(),
                      hint: 'machinery.default_village'.tr(),
                      controller: _villageController,
                    ),
                    const SizedBox(height: 14.0),
                    AppTextField(
                      label: 'machinery.district'.tr(),
                      hint: 'machinery.default_district'.tr(),
                      controller: _districtController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Submit Button
              AppButton(
                label: 'machinery.publish_machine'.tr(),
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
