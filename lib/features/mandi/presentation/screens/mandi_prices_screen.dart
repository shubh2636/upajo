import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/mandi_controller.dart';
import '../../domain/models/mandi_price_model.dart';

class MandiPricesScreen extends ConsumerStatefulWidget {
  const MandiPricesScreen({super.key});

  @override
  ConsumerState<MandiPricesScreen> createState() => _MandiPricesScreenState();
}

class _MandiPricesScreenState extends ConsumerState<MandiPricesScreen> {
  final List<Map<String, String>> _cropFilters = [
    {'id': 'all', 'label': 'सभी फसलें'},
    {'id': 'गेहूं', 'label': 'गेहूं (Wheat)'},
    {'id': 'चना', 'label': 'चना (Chickpea)'},
    {'id': 'सोयाबीन', 'label': 'सोयाबीन (Soybean)'},
    {'id': 'सरसों', 'label': 'सरसों (Mustard)'},
    {'id': 'धान', 'label': 'धान (Paddy)'},
    {'id': 'प्याज', 'label': 'प्याज (Onion)'},
  ];

  void _showPriceAlertDialog(MandiPriceModel item, String farmerId) {
    final targetController = TextEditingController(text: '${(item.modalPrice + 100).toInt()}');
    String condition = 'above';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppColors.primary600, size: 24.0),
                          const SizedBox(width: 8.0),
                          Text('भाव अलर्ट सेट करें', style: AppTypography.headlineSmall.copyWith(fontSize: 18.0)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '${item.cropNameHi} (${item.mandiName})',
                    style: const TextStyle(fontSize: 13.0, color: AppColors.soil600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),

                  // Condition chips
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('भाव इससे ऊपर जाए'),
                        selected: condition == 'above',
                        selectedColor: AppColors.primary500,
                        labelStyle: TextStyle(color: condition == 'above' ? Colors.white : AppColors.soil800, fontWeight: FontWeight.bold),
                        onSelected: (_) => setModalState(() => condition = 'above'),
                      ),
                      const SizedBox(width: 8.0),
                      ChoiceChip(
                        label: const Text('भाव इससे नीचे जाए'),
                        selected: condition == 'below',
                        selectedColor: AppColors.primary500,
                        labelStyle: TextStyle(color: condition == 'below' ? Colors.white : AppColors.soil800, fontWeight: FontWeight.bold),
                        onSelected: (_) => setModalState(() => condition = 'below'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'लक्ष्य भाव (₹ प्रति क्विंटल)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  AppButton(
                    label: 'अलर्ट सुरक्षित करें',
                    onPressed: () {
                      final val = double.tryParse(targetController.text) ?? item.modalPrice;
                      ref.read(mandiControllerProvider.notifier).createPriceAlert(
                        farmerId: farmerId,
                        cropName: item.cropNameHi,
                        targetPrice: val,
                        condition: condition,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.cropNameHi} का भाव ₹${val.toInt()} पहुंचने पर आपको अलर्ट मिलेगा!'),
                          backgroundColor: AppColors.primary600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mandiControllerProvider);
    final controller = ref.read(mandiControllerProvider.notifier);
    final user = ref.watch(authControllerProvider).userProfile;
    final farmerId = user?.id ?? 'demo_farmer_id';

    final selectedForChart = state.selectedMandiForChart;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: const Text('लाइव मंडी भाव (Agmarknet)', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'भाव ताज़ा करें',
            onPressed: () => controller.loadPrices(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadPrices(),
        color: AppColors.primary500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Agmarknet Guarantee Ribbon
              _buildPulseBanner(),

              const SizedBox(height: 16.0),

              // 2. Crop Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _cropFilters.map((c) {
                    final isSelected = state.selectedCrop == c['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(c['label']!),
                        selected: isSelected,
                        onSelected: (_) => controller.selectCrop(c['id']!),
                        selectedColor: AppColors.primary500,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.soil800,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        side: BorderSide(color: isSelected ? AppColors.primary500 : AppColors.soil300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16.0),

              // 3. Interactive Historical Price Chart (fl_chart)
              if (selectedForChart != null && selectedForChart.historicalTrend.isNotEmpty)
                _buildPriceTrendChart(selectedForChart),

              const SizedBox(height: 16.0),

              // 4. Mandi Rates List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('प्रमुख मंडियों के दैनिक भाव', style: AppTypography.headlineSmall.copyWith(fontSize: 17.0)),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: const TextStyle(fontSize: 12.0, color: AppColors.soil600, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary500),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.mandiList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                  itemBuilder: (context, index) {
                    final item = state.mandiList[index];
                    return _buildMandiCard(item, controller, farmerId);
                  },
                ),

              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseBanner() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22.0),
          ),
          const SizedBox(width: 12.0),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'आज का मंडी रुझान: चना व गेहूं में मजबूती',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.soil900),
                ),
                SizedBox(height: 2.0),
                Text(
                  'सरकारी पोर्टल (Agmarknet) से सीधे सत्यापित लाइव मॉडल भाव प्रति क्विंटल।',
                  style: TextStyle(fontSize: 11.5, color: AppColors.soil700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTrendChart(MandiPriceModel item) {
    final trend = item.historicalTrend;
    final minY = (trend.reduce((a, b) => a < b ? a : b) * 0.95).floorToDouble();
    final maxY = (trend.reduce((a, b) => a > b ? a : b) * 1.05).ceilToDouble();

    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.cropNameHi} - 7 दिवसीय भाव ट्रेंड',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.soil900),
                  ),
                  Text(
                    item.mandiName,
                    style: const TextStyle(fontSize: 12.0, color: AppColors.soil600),
                  ),
                ],
              ),
              Text(
                '₹${item.modalPrice.toInt()}/क्विंटल',
                style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w900, color: AppColors.primary700),
              ),
            ],
          ),
          const SizedBox(height: 18.0),

          // fl_chart LineChart
          SizedBox(
            height: 160.0,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(trend.length, (i) => FlSpot(i.toDouble(), trend[i])),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary600,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary500.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandiCard(MandiPriceModel item, MandiController controller, String farmerId) {
    final isPositive = item.change24h >= 0;

    return AppCard(
      padding: const EdgeInsets.all(14.0),
      onTap: () => controller.selectMandiForChart(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.cropNameHi,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: AppColors.soil900),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      item.mandiName,
                      style: const TextStyle(fontSize: 12.0, color: AppColors.soil600),
                    ),
                  ],
                ),
              ),

              // Modal Price & Change Chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${item.modalPrice.toInt()}',
                    style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w900, color: AppColors.soil900),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: isPositive ? const Color(0x1F4CAF50) : const Color(0x1FF44336),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      '${isPositive ? "+" : ""}₹${item.change24h.toInt()}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success600 : AppColors.error600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Range & Arrivals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'दायरा: ₹${item.minPrice.toInt()} - ₹${item.maxPrice.toInt()}/क्विंटल',
                style: const TextStyle(fontSize: 12.0, color: AppColors.soil700, fontWeight: FontWeight.w600),
              ),
              Text(
                'आवक: ${item.arrivalsTonnes.toInt()} टन',
                style: const TextStyle(fontSize: 11.5, color: AppColors.soil600),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Price Alert Trigger Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add_alert_rounded, size: 16.0),
              label: const Text('भाव अलर्ट सेट करें', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
              onPressed: () => _showPriceAlertDialog(item, farmerId),
            ),
          ),
        ],
      ),
    );
  }
}

