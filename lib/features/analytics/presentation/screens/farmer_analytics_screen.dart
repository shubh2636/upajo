import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/farmer_analytics_controller.dart';
import '../../domain/models/farmer_analytics_model.dart';
import '../../data/services/invoice_pdf_generator.dart';

class FarmerAnalyticsScreen extends ConsumerStatefulWidget {
  const FarmerAnalyticsScreen({super.key});

  @override
  ConsumerState<FarmerAnalyticsScreen> createState() => _FarmerAnalyticsScreenState();
}

class _FarmerAnalyticsScreenState extends ConsumerState<FarmerAnalyticsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).userProfile;
      if (user != null) {
        ref.read(farmerAnalyticsControllerProvider.notifier).loadAnalytics(user.id);
      }
    });
  }

  Future<void> _downloadSampleInvoice(FarmerAnalyticsModel analytics) async {
    final user = ref.read(authControllerProvider).userProfile;

    await InvoicePdfGenerator.printOrShareInvoice(
      invoiceNumber: 'UPAJ-INV-${DateTime.now().year}-0842',
      farmerName: user?.fullName ?? 'Baldev Singh Patel',
      farmerVillage: 'Gram Shyampur',
      farmerDistrict: 'Sehore (M.P.)',
      farmerPhone: user?.phoneNumber ?? '9876543210',
      buyerName: analytics.topBuyers.isNotEmpty ? analytics.topBuyers.first.buyerName : 'Amit Sharma',
      buyerAddress: 'House 42, E-7 Arera Colony, Bhopal',
      buyerPhone: '9425012345',
      cropName: 'Sharbati Wheat C-306',
      variety: 'Sujata Grade-A',
      packSizeKg: 50,
      quantityPacks: 50,
      pricePerKg: 34.50,
      deliveryFee: 0.0,
      paymentMode: 'Bank Transfer / UPI',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerAnalyticsControllerProvider);
    final analytics = state.analytics;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('analytics.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'analytics.download_invoice'.tr(),
            onPressed: analytics != null ? () => _downloadSampleInvoice(analytics) : null,
          ),
        ],
      ),
      body: state.isLoading && analytics == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
          : analytics == null
              ? Center(child: Text('analytics.no_data'.tr()))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. KPI Bento Cards Row
                      _buildKpiGrid(analytics),

                      const SizedBox(height: 18.0),

                      // 2. 6-Month Revenue Bar Chart (fl_chart)
                      _buildRevenueBarChart(analytics.monthlyTrends),

                      const SizedBox(height: 18.0),

                      // 3. Earnings By Crop Card
                      _buildCropDistributionCard(analytics.earningsByCrop),

                      const SizedBox(height: 18.0),

                      // 4. Top Buyers Leaderboard
                      _buildTopBuyersCard(analytics.topBuyers),

                      const SizedBox(height: 24.0),

                      // 5. PDF Invoicing CTA Button
                      AppButton(
                        label: 'analytics.download_gst_invoice_btn'.tr(),
                        variant: ButtonVariant.primary,
                        onPressed: () => _downloadSampleInvoice(analytics),
                        icon: const Icon(Icons.print_rounded, size: 22.0, color: Colors.white),
                      ),

                      const SizedBox(height: 32.0),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiGrid(FarmerAnalyticsModel analytics) {
    return Column(
      children: [
        // Main Revenue Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary800, AppColors.primary600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(color: Color(0x1F25603A), blurRadius: 10.0, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('analytics.net_payout'.tr(), style: const TextStyle(color: AppColors.wheat200, fontSize: 13.0, fontWeight: FontWeight.bold)),
                  const Icon(Icons.verified_rounded, color: AppColors.wheat400, size: 20.0),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                '₹${analytics.totalEarnings.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 34.0, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0),
              ),
              const SizedBox(height: 4.0),
              Text('analytics.bank_upi_direct'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12.0)),
            ],
          ),
        ),

        const SizedBox(height: 12.0),

        // Sub KPIs
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('analytics.total_sold_produce'.tr(), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                    const SizedBox(height: 4.0),
                    Text('analytics.quintals_unit'.tr(args: [analytics.totalQuintals.toString()]), style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.soil900)),
                    Text('analytics.orders_completed_count'.tr(args: [analytics.totalOrders.toString()]), style: const TextStyle(fontSize: 11.0, color: AppColors.primary700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('analytics.avg_realized_rate'.tr(), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                    const SizedBox(height: 4.0),
                    Text('₹${analytics.averageRatePerQuintal.toInt()}' + 'analytics.per_quintal_short'.tr(), style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.wheat900)),
                    Text('analytics.mandi_extra_profit'.tr(), style: const TextStyle(fontSize: 11.0, color: AppColors.success600, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueBarChart(Map<String, double> trends) {
    final months = trends.keys.toList();
    final values = trends.values.toList();
    final maxVal = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 100000.0;

    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('analytics.monthly_trends'.tr(), style: AppTypography.headlineSmall.copyWith(fontSize: 15.0)),
              Text('analytics.in_rupees'.tr(), style: const TextStyle(fontSize: 12.0, color: AppColors.soil600, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 18.0),

          SizedBox(
            height: 170.0,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(months[idx], style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, color: AppColors.soil700)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(values.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: AppColors.primary500,
                        width: 18.0,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropDistributionCard(Map<String, double> cropBreakdown) {
    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('analytics.crop_share'.tr(), style: AppTypography.headlineSmall.copyWith(fontSize: 15.0)),
          const SizedBox(height: 14.0),
          ...cropBreakdown.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold)),
                      Text('${entry.value.toInt()}%', style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: AppColors.primary700)),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                      value: entry.value / 100.0,
                      minHeight: 8.0,
                      backgroundColor: AppColors.soil200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary500),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopBuyersCard(List<BuyerStat> buyers) {
    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('analytics.top_buyers_title'.tr(), style: AppTypography.headlineSmall.copyWith(fontSize: 15.0)),
              const Icon(Icons.people_alt_rounded, color: AppColors.primary600, size: 20.0),
            ],
          ),
          const SizedBox(height: 12.0),
          ...buyers.map((b) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      Text('${b.location} • ' + 'analytics.orders_count_badge'.tr(args: [b.ordersCount.toString()]), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                    ],
                  ),
                  Text('₹${b.totalSpent.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.0, color: AppColors.soil900)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
