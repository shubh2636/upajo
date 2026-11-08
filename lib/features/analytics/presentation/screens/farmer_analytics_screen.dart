import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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
      final farmerId = user?.id ?? 'demo_farmer_id';
      ref.read(farmerAnalyticsControllerProvider.notifier).loadAnalytics(farmerId);
    });
  }

  void _downloadSampleInvoice(FarmerAnalyticsModel analytics) {
    final user = ref.read(authControllerProvider).userProfile;

    InvoicePdfGenerator.printOrShareInvoice(
      invoiceNumber: 'UPJ-INV-2026-0812',
      farmerName: user?.fullName ?? 'बलदेव सिंह पटेल',
      farmerVillage: 'ग्राम श्यामपुर',
      farmerDistrict: 'सीहोर (म.प्र.)',
      farmerPhone: user?.phoneNumber ?? '9425098765',
      buyerName: analytics.topBuyers.isNotEmpty ? analytics.topBuyers.first.buyerName : 'अमित शर्मा',
      buyerAddress: 'मकान नं 42, ई-7 अरेरा कॉलोनी, भोपाल',
      buyerPhone: '9826011223',
      cropName: 'शरबती गेहूं (C-306)',
      variety: 'सुजाता ग्रेड-ए',
      packSizeKg: 50,
      quantityPacks: 2,
      pricePerKg: 35.0,
      deliveryFee: 150.0,
      paymentMode: 'UPI (Razorpay Verified)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerAnalyticsControllerProvider);
    final analytics = state.analytics;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: const Text('बिक्री विश्लेषण व इनवॉइस', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'इनवॉइस डाउनलोड करें',
            onPressed: analytics != null ? () => _downloadSampleInvoice(analytics) : null,
          ),
        ],
      ),
      body: state.isLoading && analytics == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
          : analytics == null
              ? const Center(child: Text('आंकड़े उपलब्ध नहीं हैं'))
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
                        label: 'जीएसटी-मुक्त बिक्री इनवॉइस (PDF) डाउनलोड करें',
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('कुल शुद्ध किसान भुगतान (Net Payout)', style: TextStyle(color: AppColors.wheat200, fontSize: 13.0, fontWeight: FontWeight.bold)),
                  Icon(Icons.verified_rounded, color: AppColors.wheat400, size: 20.0),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                '₹${analytics.totalEarnings.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 34.0, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0),
              ),
              const SizedBox(height: 4.0),
              const Text('सीधे आपके बैंक व UPI खाते में जमा', style: TextStyle(color: Colors.white70, fontSize: 12.0)),
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
                    const Text('कुल बिकी उपज', style: TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                    const SizedBox(height: 4.0),
                    Text('${analytics.totalQuintals} क्विंटल', style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.soil900)),
                    Text('${analytics.totalOrders} ऑर्डर पूरे हुए', style: const TextStyle(fontSize: 11.0, color: AppColors.primary700)),
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
                    const Text('औसत प्राप्त भाव', style: TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                    const SizedBox(height: 4.0),
                    Text('₹${analytics.averageRatePerQuintal.toInt()}/क्विं', style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.wheat900)),
                    const Text('मंडी से 25% अधिक लाभ', style: TextStyle(fontSize: 11.0, color: AppColors.success600, fontWeight: FontWeight.bold)),
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
              Text('मासिक बिक्री रुझान (Monthly Trends)', style: AppTypography.headlineSmall.copyWith(fontSize: 15.0)),
              const Text('₹ में', style: TextStyle(fontSize: 12.0, color: AppColors.soil600, fontWeight: FontWeight.bold)),
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
          Text('फसलों के अनुसार कमाई (Crop Share)', style: AppTypography.headlineSmall.copyWith(fontSize: 15.0)),
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
              Text('शीर्ष निष्ठावान खरीदार (Top Buyers)', style: AppTypography.headlineSmall.copyWith(fontSize: 15.0)),
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
                      Text('${b.location} • ${b.ordersCount} बार ऑर्डर किया', style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
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

