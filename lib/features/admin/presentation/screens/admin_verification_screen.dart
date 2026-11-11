import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../marketplace/domain/models/order_model.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';

class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends ConsumerState<AdminVerificationScreen> {
  List<Map<String, dynamic>> _pendingFarmers = [];
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final farmersRes = await SupabaseService.client
          .from('profiles')
          .select('*, farmer_profiles(*)')
          .eq('role', 'farmer')
          .order('created_at', ascending: false);

      final repo = ref.read(marketplaceRepositoryProvider);
      final orders = await repo.getAllOrdersAdmin();

      if (mounted) {
        setState(() {
          _pendingFarmers = List<Map<String, dynamic>>.from(farmersRes as List);
          _allOrders = orders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyFarmer(String farmerId, bool approve) async {
    final repo = ref.read(marketplaceRepositoryProvider);
    try {
      await repo.setFarmerKycStatus(
        farmerId: farmerId,
        status: approve ? 'verified' : 'rejected',
        verifiedByAdmin: approve,
      );
      await _loadAdminData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'admin.farmer_approved_toast'.tr() : 'admin.farmer_rejected_toast'.tr()),
            backgroundColor: approve ? AppColors.primary500 : AppColors.clay500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalGmv = _allOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.soil50,
        appBar: AppBar(
          title: Text('admin.admin_panel_title'.tr()),
          backgroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: AppColors.primary500,
            labelColor: AppColors.primary600,
            unselectedLabelColor: AppColors.soil600,
            tabs: [
              Tab(text: 'admin.tab_kyc'.tr()),
              Tab(text: 'admin.tab_orders'.tr()),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Farmer KYC Verification
                  _pendingFarmers.isEmpty
                      ? Center(child: Text('admin.no_pending_kyc'.tr()))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _pendingFarmers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                          itemBuilder: (context, index) {
                            final farmer = _pendingFarmers[index];
                            final isVerified = farmer['verified_by_admin'] as bool? ?? false;

                            return AppCard(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text((farmer['full_name'] as String?) ?? 'admin.farmer_fallback'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.0)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                        decoration: BoxDecoration(
                                          color: isVerified ? AppColors.primary100 : AppColors.wheat100,
                                          borderRadius: BorderRadius.circular(6.0),
                                        ),
                                        child: Text(
                                          isVerified ? 'admin.status_verified_badge'.tr() : 'admin.status_pending_badge'.tr(),
                                          style: TextStyle(
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.bold,
                                            color: isVerified ? AppColors.primary800 : AppColors.wheat900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6.0),
                                  Text('admin.phone_prefix'.tr(args: ['+91 ${farmer['phone'] ?? ''}']), style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600)),
                                  Text('admin.location_prefix'.tr(args: ['${farmer['village_or_city'] ?? ''}, ${farmer['district'] ?? ''} (${farmer['state'] ?? ''}) - ${farmer['pin_code'] ?? ''}']), style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),

                                  const SizedBox(height: 14.0),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _verifyFarmer((farmer['id'] as String?) ?? '', false),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.clay500,
                                            side: const BorderSide(color: AppColors.clay300),
                                          ),
                                          child: Text('admin.reject_action'.tr()),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: AppButton(
                                          height: 44.0,
                                          label: 'admin.approve_action'.tr(),
                                          onPressed: () => _verifyFarmer((farmer['id'] as String?) ?? '', true),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  // Tab 2: All Orders GMV
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: AppColors.primary50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('admin.total_gmv'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('₹${totalGmv.toStringAsFixed(0)}', style: AppTypography.headlineMedium.copyWith(color: AppColors.primary600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _allOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                          itemBuilder: (context, index) {
                            final o = _allOrders[index];
                            return AppCard(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('${o.farmerName ?? 'admin.farmer_fallback'.tr()} -> ${o.consumerName ?? 'admin.consumer_fallback'.tr()}', style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),
                                      Text('admin.status_prefix'.tr(args: [o.status]), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Text('₹${o.totalAmount.toStringAsFixed(0)}', style: AppTypography.priceMedium),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
