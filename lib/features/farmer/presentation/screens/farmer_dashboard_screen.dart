import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/bento_grid.dart';
import '../../../../core/widgets/language_switcher_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';
import '../../../marketplace/domain/models/order_model.dart';
import '../../../marketplace/domain/models/product_model.dart';

class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  List<OrderModel> _orders = [];
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user != null) {
      final repo = ref.read(marketplaceRepositoryProvider);
      try {
        final orders = await repo.getFarmerOrders(user.id);
        final products = await repo.getFarmerProducts(user.id);
        if (mounted) {
          setState(() {
            _orders = orders;
            _products = products;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.userProfile;

    final pendingOrders = _orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();
    final deliveredOrders = _orders.where((o) => o.status == 'delivered').toList();
    final totalEarnings = deliveredOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: AppColors.primary500),
            const SizedBox(width: 8.0),
            Text('app_name'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LanguageSwitcherButton(),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => context.push(RouteNames.farmerEarnings),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFarmerData,
        color: AppColors.primary500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Earthy Hero Card
              Container(
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary600, AppColors.primary500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary800.withOpacity(0.2),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => context.push(RouteNames.farmerKyc),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user?.kycStatus == 'verified' || user?.kycStatus == 'approved'
                                      ? '🌾 ${'farmer.kyc_status_verified'.tr()}'
                                      : user?.kycStatus == 'pending'
                                          ? '⏳ ${'farmer.kyc_status_pending'.tr()}'
                                          : '⚠️ ${'farmer.kyc_status_needed'.tr()}',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.wheat200,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 10.0, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        if (user?.verifiedByAdmin == true || user?.kycStatus == 'verified')
                          const Icon(Icons.verified_rounded, color: AppColors.wheat300, size: 22.0),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      '${'farmer.greeting'.tr()}, ${user?.fullName ?? ''}!',
                      style: AppTypography.displaySmall.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${user?.villageOrCity ?? ''}, ${user?.district ?? ''} (${user?.state ?? ''})',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary100),
                    ),
                    const SizedBox(height: 20.0),

                    // Add Product CTA
                    AppButton(
                      label: 'farmer.add_product'.tr(),
                      variant: ButtonVariant.secondary,
                      onPressed: () => context.push(RouteNames.addProduct),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22.0, color: AppColors.soil900),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // AI Crop Advisor & Weather Bento Action Card (Part 2)
              AppCard(
                padding: const EdgeInsets.all(18.0),
                backgroundColor: AppColors.primary50,
                borderColor: AppColors.primary300,
                borderWidth: 1.5,
                onTap: () => context.push(RouteNames.cropAdvisor),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(Icons.cloudy_snowing, color: Colors.white, size: 28.0),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'advisor.title'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.0, color: AppColors.soil900),
                              ),
                              const SizedBox(width: 6.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: AppColors.wheat400,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text('common.live'.tr(), style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: AppColors.soil900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'advisor.live_desc'.tr(),
                            style: const TextStyle(fontSize: 12.0, color: AppColors.soil700),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16.0, color: AppColors.primary600),
                  ],
                ),
              ),

              const SizedBox(height: 14.0),

              // AI Tools Bento Grid (Part 3)
              Row(
                children: [
                  // Camera Disease Scanner
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14.0),
                      backgroundColor: AppColors.terracotta50,
                      borderColor: AppColors.terracotta200,
                      onTap: () => context.push(RouteNames.diseaseDetection),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.terracotta500,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Icon(Icons.document_scanner_rounded, size: 20.0, color: Colors.white),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 16.0, color: AppColors.terracotta600),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'disease.title'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0, color: AppColors.soil900),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'disease.subtitle'.tr(),
                            style: const TextStyle(fontSize: 11.0, color: AppColors.soil600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),

                  // Krishi Sahayak Voice AI
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14.0),
                      backgroundColor: AppColors.wheat50,
                      borderColor: AppColors.wheat300,
                      onTap: () => context.push(RouteNames.krishiSahayak),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.wheat600,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Icon(Icons.psychology_rounded, size: 20.0, color: Colors.white),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 16.0, color: AppColors.wheat700),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'sahayak.title'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0, color: AppColors.soil900),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'sahayak.subtitle'.tr(),
                            style: const TextStyle(fontSize: 11.0, color: AppColors.soil600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14.0),

              // Farm Services Bento Grid (Part 4)
              Row(
                children: [
                  // Machinery Rentals
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14.0),
                      backgroundColor: Colors.white,
                      borderColor: AppColors.soil300,
                      onTap: () => context.push(RouteNames.machinery),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.soil800,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Icon(Icons.agriculture_rounded, size: 20.0, color: Colors.white),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 16.0, color: AppColors.soil600),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'machinery.title'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0, color: AppColors.soil900),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'machinery.browse_machines'.tr(),
                            style: const TextStyle(fontSize: 11.0, color: AppColors.soil600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),

                  // Certified Store
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14.0),
                      backgroundColor: AppColors.primary50,
                      borderColor: AppColors.primary300,
                      onTap: () => context.push(RouteNames.store),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.primary600,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Icon(Icons.spa_rounded, size: 20.0, color: Colors.white),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 16.0, color: AppColors.primary600),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'store.title'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0, color: AppColors.soil900),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'store.certified_badge'.tr(),
                            style: const TextStyle(fontSize: 11.0, color: AppColors.primary700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14.0),

              // Market Intelligence & Farmer Analytics Grid (Part 5)
              Row(
                children: [
                  // Mandi Rates
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14.0),
                      backgroundColor: AppColors.wheat50,
                      borderColor: AppColors.wheat400,
                      onTap: () => context.push(RouteNames.mandiPrices),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.wheat600,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Icon(Icons.trending_up_rounded, size: 20.0, color: Colors.white),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 16.0, color: AppColors.wheat700),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'mandi.title'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.soil900),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'mandi.history_7d'.tr(),
                            style: const TextStyle(fontSize: 11.0, color: AppColors.soil600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),

                  // Analytics & Invoicing
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14.0),
                      backgroundColor: Colors.white,
                      borderColor: AppColors.soil300,
                      onTap: () => context.push(RouteNames.farmerAnalytics),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.primary700,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Icon(Icons.bar_chart_rounded, size: 20.0, color: Colors.white),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 16.0, color: AppColors.soil600),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'analytics.title'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.soil900),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'analytics.subtitle'.tr(),
                            style: const TextStyle(fontSize: 11.0, color: AppColors.soil600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20.0),

              // Bento Stats Grid
              Text('farmer.dashboard_title'.tr(), style: AppTypography.headlineSmall),
              const SizedBox(height: 12.0),

              BentoGrid(
                crossAxisCount: 2,
                children: [
                  // Active Products Card
                  AppCard(
                    padding: const EdgeInsets.all(16.0),
                    onTap: () => context.push(RouteNames.myProducts),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('farmer.active_stock'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.0)),
                            const Icon(Icons.storefront_rounded, color: AppColors.primary500),
                          ],
                        ),
                        Text('${_products.length}', style: AppTypography.displayMedium),
                        Text('common.active'.tr(), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                      ],
                    ),
                  ),

                  // Pending Orders Card
                  AppCard(
                    padding: const EdgeInsets.all(16.0),
                    backgroundColor: AppColors.wheat50,
                    borderColor: AppColors.wheat300,
                    onTap: () => context.push(RouteNames.farmerOrders),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('farmer.pending_orders'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.0)),
                            const Icon(Icons.schedule_rounded, color: AppColors.wheat700),
                          ],
                        ),
                        Text(
                          '${pendingOrders.length}',
                          style: AppTypography.displayMedium.copyWith(color: AppColors.wheat900),
                        ),
                        Text('common.pending'.tr(), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                      ],
                    ),
                  ),

                  // Total Earnings Card
                  AppCard(
                    padding: const EdgeInsets.all(16.0),
                    backgroundColor: AppColors.primary50,
                    borderColor: AppColors.primary200,
                    onTap: () => context.push(RouteNames.farmerEarnings),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('farmer.total_earnings'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.0)),
                            const Icon(Icons.currency_rupee_rounded, color: AppColors.primary600),
                          ],
                        ),
                        Text(AppFormatters.currency(totalEarnings, locale: context.locale), style: AppTypography.headlineMedium.copyWith(color: AppColors.primary700)),
                        Text('farmer.bank_details_title'.tr(), style: const TextStyle(fontSize: 11.0, color: AppColors.primary700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Fulfilled Orders Card
                  AppCard(
                    padding: const EdgeInsets.all(16.0),
                    onTap: () => context.push(RouteNames.farmerOrders),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('analytics.completed_orders'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.0)),
                            const Icon(Icons.task_alt_rounded, color: AppColors.primary500),
                          ],
                        ),
                        Text('${deliveredOrders.length}', style: AppTypography.displayMedium),
                        Text('common.verified'.tr(), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24.0),

              // Recent Orders Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('farmer.pending_orders'.tr(), style: AppTypography.headlineSmall),
                  TextButton(
                    onPressed: () => context.push(RouteNames.farmerOrders),
                    child: Text('common.view_all'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
              else if (_orders.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, size: 40.0, color: AppColors.soil400),
                        const SizedBox(height: 8.0),
                        Text('common.empty'.tr(), style: AppTypography.bodyMedium),
                        const SizedBox(height: 4.0),
                        Text('consumer.empty_cart_desc'.tr(), style: const TextStyle(fontSize: 12.0, color: AppColors.soil500)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orders.take(3).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return AppCard(
                      padding: const EdgeInsets.all(14.0),
                      onTap: () => context.push(RouteNames.farmerOrders),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                              const SizedBox(height: 4.0),
                              Text(
                                '${order.deliveryMode == 'pickup' ? 'consumer.farmgate_pickup'.tr() : 'consumer.home_delivery'.tr()} • ${order.status}',
                                style: TextStyle(fontSize: 12.0, color: order.status == 'delivered' ? AppColors.primary600 : AppColors.wheat700, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(AppFormatters.currency(order.totalAmount, locale: context.locale), style: AppTypography.headlineSmall.copyWith(color: AppColors.primary600)),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

