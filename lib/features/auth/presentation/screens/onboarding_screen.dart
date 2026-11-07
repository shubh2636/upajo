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
import '../controllers/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController(text: 'मध्य प्रदेश');
  final _pinCodeController = TextEditingController();

  // Farmer specific
  final _farmNameController = TextEditingController();
  final _acresController = TextEditingController(text: '2.5');

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _farmNameController.dispose();
    _acresController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authControllerProvider);
    final isFarmer = authState.selectedRole == 'farmer';

    final success = await ref.read(authControllerProvider.notifier).completeOnboarding(
          fullName: _nameController.text.trim(),
          villageOrCity: _villageController.text.trim(),
          district: _districtController.text.trim(),
          stateName: _stateController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
          farmName: isFarmer ? _farmNameController.text.trim() : null,
          totalAcres: isFarmer ? (double.tryParse(_acresController.text.trim()) ?? 0.0) : 0.0,
        );

    if (mounted) {
      if (success) {
        if (isFarmer) {
          context.go(RouteNames.farmerDashboard);
        } else {
          context.go(RouteNames.consumerHome);
        }
      } else {
        final err = ref.read(authControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err ?? 'common.error'.tr()),
            backgroundColor: AppColors.clay500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isFarmer = authState.selectedRole == 'farmer';

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('auth.complete_profile'.tr()),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20.0),
                  borderRadius: 20.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'बुनियादी जानकारी (Basic Details)',
                        style: AppTypography.headlineSmall,
                      ),
                      const SizedBox(height: 16.0),

                      AppTextField(
                        controller: _nameController,
                        label: 'auth.full_name'.tr(),
                        hintText: 'उदा. रामेश्वर पाटीदार',
                        prefixIcon: const Icon(Icons.person_rounded, color: AppColors.soil500),
                        validator: (val) {
                          if (val == null || val.trim().length < 2) {
                            return 'कृपया पूरा नाम लिखें';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14.0),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _villageController,
                              label: 'auth.village_city'.tr(),
                              hintText: 'उदा. आष्टा',
                              validator: (val) => val == null || val.trim().isEmpty ? 'गाँव लिखें' : null,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: AppTextField(
                              controller: _districtController,
                              label: 'auth.district'.tr(),
                              hintText: 'उदा. सीहोर',
                              validator: (val) => val == null || val.trim().isEmpty ? 'जिला लिखें' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _stateController,
                              label: 'auth.state'.tr(),
                              hintText: 'राज्य',
                              validator: (val) => val == null || val.trim().isEmpty ? 'राज्य लिखें' : null,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: AppTextField(
                              controller: _pinCodeController,
                              label: 'auth.pincode'.tr(),
                              hintText: '466116',
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().length != 6) {
                                  return '6 अंकों का पिन कोड';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isFarmer) ...[
                  const SizedBox(height: 18.0),
                  AppCard(
                    padding: const EdgeInsets.all(20.0),
                    borderRadius: 20.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'खेत की जानकारी (Farm Details)',
                          style: AppTypography.headlineSmall,
                        ),
                        const SizedBox(height: 16.0),

                        AppTextField(
                          controller: _farmNameController,
                          label: 'खेत / फ़ार्म का नाम',
                          hintText: 'उदा. पाटीदार जैविक फ़ार्म',
                        ),
                        const SizedBox(height: 14.0),

                        AppTextField(
                          controller: _acresController,
                          label: 'कुल जमीन (एकड़ में)',
                          hintText: 'उदा. 5',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28.0),

                AppButton(
                  label: 'auth.complete_profile'.tr(),
                  onPressed: _onSubmit,
                  isLoading: authState.isLoading,
                  icon: const Icon(Icons.check_rounded, size: 22.0),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

