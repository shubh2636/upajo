import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';

class FarmerEarningsScreen extends ConsumerStatefulWidget {
  const FarmerEarningsScreen({super.key});

  @override
  ConsumerState<FarmerEarningsScreen> createState() => _FarmerEarningsScreenState();
}

class _FarmerEarningsScreenState extends ConsumerState<FarmerEarningsScreen> {
  final _upiController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _holderController = TextEditingController();

  bool _isSaving = false;
  double _totalSettled = 0.0;
  double _pendingSettlement = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEarningsAndBank();
  }

  Future<void> _loadEarningsAndBank() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user != null) {
      final repo = ref.read(marketplaceRepositoryProvider);
      try {
        final orders = await repo.getFarmerOrders(user.id);
        final delivered = orders.where((o) => o.status == 'delivered');
        final inProgress = orders.where((o) => o.status != 'delivered' && o.status != 'cancelled');

        final settled = delivered.fold(0.0, (sum, o) => sum + o.totalAmount);
        final pending = inProgress.fold(0.0, (sum, o) => sum + o.totalAmount);

        // Load bank profile
        final bankData = await SupabaseService.client
            .from('farmer_profiles')
            .select('*')
            .eq('farmer_id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _totalSettled = settled;
            _pendingSettlement = pending;
            if (bankData != null) {
              _upiController.text = bankData['upi_vpa'] ?? '';
              _accountController.text = bankData['bank_account_number'] ?? '';
              _ifscController.text = bankData['bank_ifsc'] ?? '';
              _holderController.text = bankData['bank_account_holder_name'] ?? user.fullName;
            }
          });
        }
      } catch (_) {}
    }
  }

  void _onSaveBank() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await SupabaseService.client.from('farmer_profiles').upsert({
        'farmer_id': user.id,
        'upi_vpa': _upiController.text.trim(),
        'bank_account_number': _accountController.text.trim(),
        'bank_ifsc': _ifscController.text.trim().toUpperCase(),
        'bank_account_holder_name': _holderController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('बैंक एवं UPI विवरण सुरक्षित सहेजा गया!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटि: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: const Text('कमाई व बैंक खाता (Earnings)'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Earnings Card
            Container(
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(22.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('कुल प्राप्त कमाई (Settled)', style: TextStyle(color: AppColors.wheat200, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6.0),
                  Text('₹${_totalSettled.toStringAsFixed(0)}', style: AppTypography.displayLarge.copyWith(color: Colors.white)),
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8.0)),
                    child: const Text('0% कमीशन — पूरा पैसा किसान के खाते में', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Pending Settlement Card
            AppCard(
              padding: const EdgeInsets.all(16.0),
              backgroundColor: AppColors.wheat50,
              borderColor: AppColors.wheat300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('प्रगतिरत ऑर्डर मूल्य (Pending)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                      const SizedBox(height: 2.0),
                      const Text('डिलीवरी पूरी होते ही खाते में जमा होगा', style: TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                    ],
                  ),
                  Text('₹${_pendingSettlement.toStringAsFixed(0)}', style: AppTypography.headlineMedium.copyWith(color: AppColors.wheat900)),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            // Bank Details Form
            Text('farmer.bank_details_title'.tr(), style: AppTypography.headlineSmall),
            const SizedBox(height: 12.0),

            AppCard(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  AppTextField(
                    controller: _upiController,
                    label: 'farmer.upi_id'.tr(),
                    hintText: 'उदा. 9876543210@upi',
                    prefixIcon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary500),
                  ),
                  const SizedBox(height: 14.0),

                  AppTextField(
                    controller: _holderController,
                    label: 'खाता धारक का नाम (Bank Holder)',
                    hintText: 'पासबुक के अनुसार नाम',
                  ),
                  const SizedBox(height: 14.0),

                  AppTextField(
                    controller: _accountController,
                    label: 'farmer.bank_acc'.tr(),
                    hintText: 'बैंक खाता संख्या',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14.0),

                  AppTextField(
                    controller: _ifscController,
                    label: 'farmer.ifsc_code'.tr(),
                    hintText: 'उदा. SBIN0001234',
                  ),
                  const SizedBox(height: 22.0),

                  AppButton(
                    label: 'farmer.save_bank'.tr(),
                    onPressed: _onSaveBank,
                    isLoading: _isSaving,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 22.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
