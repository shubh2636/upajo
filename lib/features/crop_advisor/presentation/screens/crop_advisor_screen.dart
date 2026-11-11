import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/crop_advisor_controller.dart';

class CropAdvisorScreen extends ConsumerStatefulWidget {
  const CropAdvisorScreen({super.key});

  @override
  ConsumerState<CropAdvisorScreen> createState() => _CropAdvisorScreenState();
}

class _CropAdvisorScreenState extends ConsumerState<CropAdvisorScreen> {
  final TextEditingController _landAreaController = TextEditingController(text: '2.0');

  final List<Map<String, String>> _soilOptions = [
    {'id': 'black_soil', 'key': 'advisor.soil_black'},
    {'id': 'sandy_loam', 'key': 'advisor.soil_sandy_loam'},
    {'id': 'alluvial', 'key': 'advisor.soil_alluvial'},
    {'id': 'red_soil', 'key': 'advisor.soil_red'},
    {'id': 'clay_loam', 'key': 'advisor.soil_clay_loam'},
  ];

  final List<Map<String, String>> _seasonOptions = [
    {'id': 'rabi', 'key': 'advisor.season_rabi'},
    {'id': 'kharif', 'key': 'advisor.season_kharif'},
    {'id': 'zaid', 'key': 'advisor.season_zaid'},
  ];

  final List<Map<String, String>> _waterOptions = [
    {'id': 'tube_well', 'key': 'advisor.water_tube_well'},
    {'id': 'canal', 'key': 'advisor.water_canal'},
    {'id': 'rainfed', 'key': 'advisor.water_rainfed'},
    {'id': 'drip_sprinkler', 'key': 'advisor.water_drip_sprinkler'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cropAdvisorControllerProvider.notifier).fetchWeather(lat: 23.2032, lon: 77.0844);
    });
  }

  @override
  void dispose() {
    _landAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cropAdvisorControllerProvider);
    final controller = ref.read(cropAdvisorControllerProvider.notifier);
    final user = ref.watch(authControllerProvider).userProfile;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('advisor.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'common.refresh'.tr(),
            onPressed: () => controller.fetchWeather(lat: 23.2032, lon: 77.0844),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'advisor.crop_calendar'.tr(),
            onPressed: () => context.push(RouteNames.cropCalendar),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Live Weather & Agricultural Advisory Bento Card
            _buildWeatherBanner(state),

            const SizedBox(height: 20.0),

            // 2. Crop Input Bento Form Card
            _buildInputFormCard(state, controller),

            const SizedBox(height: 20.0),

            // Error display if any
            if (state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: AppColors.error50,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.error300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error600),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.error700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Recommendation Result Card
            if (state.recommendation != null)
              _buildRecommendationCard(state, controller, user?.id),

            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherBanner(CropAdvisorState state) {
    if (state.isWeatherLoading) {
      return AppCard(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary500),
            ),
            const SizedBox(width: 12.0),
            Text('common.loading'.tr(), style: AppTypography.bodyMedium),
          ],
        ),
      );
    }

    final weather = state.weatherData;
    if (weather == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary800, AppColors.primary700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F25603A),
            blurRadius: 10.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloudy_snowing, color: AppColors.wheat400, size: 28.0),
                  const SizedBox(width: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'advisor.field_weather'.tr(),
                        style: const TextStyle(color: AppColors.wheat200, fontSize: 12.0, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${state.district}, ${state.stateName}',
                        style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: const BoxDecoration(
                        color: AppColors.success500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text('common.live'.tr(), style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Temp & Condition
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${weather.currentTemp.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                weather.conditionHi,
                style: const TextStyle(color: AppColors.wheat300, fontSize: 16.0, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Humidity & Wind Metrics
          Row(
            children: [
              _metricChip(Icons.water_drop_outlined, 'advisor.humidity_chip'.tr(namedArgs: {'val': '${weather.currentHumidity}'})),
              const SizedBox(width: 10.0),
              _metricChip(Icons.air_rounded, 'advisor.wind_speed_chip'.tr(namedArgs: {'speed': weather.windSpeedKmH.toStringAsFixed(1)})),
            ],
          ),
          const SizedBox(height: 14.0),

          // Spray Safety Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: weather.shouldSprayPesticide
                  ? const Color(0x334CAF50)
                  : const Color(0x33F44336),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: weather.shouldSprayPesticide
                    ? AppColors.success400
                    : AppColors.error400,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  weather.shouldSprayPesticide
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: weather.shouldSprayPesticide
                      ? AppColors.success400
                      : AppColors.error300,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    weather.shouldSprayPesticide
                        ? 'advisor.spray_favorable'.tr()
                        : 'advisor.spray_unfavorable'.tr(),
                    style: TextStyle(
                      color: weather.shouldSprayPesticide
                          ? Colors.white
                          : AppColors.wheat100,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alerts list if any
          if (weather.alerts.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            ...weather.alerts.map((alert) => Container(
                  margin: const EdgeInsets.only(top: 6.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.wheat400, size: 18.0),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          '${alert.titleHi}: ${alert.recommendationHi}',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 15.0),
          const SizedBox(width: 5.0),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInputFormCard(CropAdvisorState state, CropAdvisorController controller) {
    return AppCard(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.primary500, size: 22.0),
              const SizedBox(width: 8.0),
              Text(
                'advisor.enter_farm_details'.tr(),
                style: AppTypography.headlineSmall.copyWith(fontSize: 17.0),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'advisor.farm_details_subtitle'.tr(),
            style: const TextStyle(fontSize: 12.0, color: AppColors.soil600),
          ),
          const SizedBox(height: 18.0),

          // 1. Soil Type Selector
          _fieldLabel('advisor.soil_type_step'.tr()),
          const SizedBox(height: 6.0),
          DropdownButtonFormField<String>(
            value: state.selectedSoilType,
            decoration: _inputDecoration(Icons.terrain_rounded),
            isExpanded: true,
            items: _soilOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt['id'],
                child: Text(opt['key']!.tr(), style: const TextStyle(fontSize: 14.0)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.setSoilType(val);
            },
          ),
          const SizedBox(height: 16.0),

          // 2. Season Selector
          _fieldLabel('advisor.season_step'.tr()),
          const SizedBox(height: 6.0),
          DropdownButtonFormField<String>(
            value: state.selectedSeason,
            decoration: _inputDecoration(Icons.wb_sunny_rounded),
            isExpanded: true,
            items: _seasonOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt['id'],
                child: Text(opt['key']!.tr(), style: const TextStyle(fontSize: 14.0)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.setSeason(val);
            },
          ),
          const SizedBox(height: 16.0),

          // 3. Irrigation Source Selector
          _fieldLabel('advisor.water_step'.tr()),
          const SizedBox(height: 6.0),
          DropdownButtonFormField<String>(
            value: state.selectedWaterSource,
            decoration: _inputDecoration(Icons.water_rounded),
            isExpanded: true,
            items: _waterOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt['id'],
                child: Text(opt['key']!.tr(), style: const TextStyle(fontSize: 14.0)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.setWaterSource(val);
            },
          ),
          const SizedBox(height: 16.0),

          // 4. Land Area
          _fieldLabel('advisor.land_area_step'.tr()),
          const SizedBox(height: 6.0),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 30.0, color: AppColors.primary600),
                onPressed: () {
                  final cur = double.tryParse(_landAreaController.text) ?? 2.0;
                  if (cur > 0.5) {
                    final updated = (cur - 0.5);
                    _landAreaController.text = updated.toStringAsFixed(1);
                    controller.setLandArea(updated);
                  }
                },
              ),
              Expanded(
                child: TextFormField(
                  controller: _landAreaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  decoration: _inputDecoration(Icons.straighten_rounded),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) controller.setLandArea(parsed);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 30.0, color: AppColors.primary600),
                onPressed: () {
                  final cur = double.tryParse(_landAreaController.text) ?? 2.0;
                  final updated = (cur + 0.5);
                  _landAreaController.text = updated.toStringAsFixed(1);
                  controller.setLandArea(updated);
                },
              ),
            ],
          ),
          const SizedBox(height: 22.0),

          // Large Accessible Submit Button
          AppButton(
            label: 'advisor.get_recommendation'.tr(),
            isLoading: state.isLoading,
            onPressed: () => controller.getRecommendation(),
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22.0),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    CropAdvisorState state,
    CropAdvisorController controller,
    String? farmerId,
  ) {
    final rec = state.recommendation!;

    return AppCard(
      borderColor: AppColors.primary400,
      borderWidth: 1.5,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.primary300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.primary600, size: 16.0),
                    const SizedBox(width: 4.0),
                    Text(
                      'advisor.model_estimate'.tr(namedArgs: {'percent': '${(rec.confidenceScore * 100).toInt()}'}),
                      style: const TextStyle(color: AppColors.primary700, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.psychology_rounded, color: AppColors.wheat600, size: 26.0),
            ],
          ),
          const SizedBox(height: 12.0),

          // Crop Name
          Text(
            rec.nameHi,
            style: AppTypography.displayMedium.copyWith(color: AppColors.soil900, fontSize: 24.0),
          ),
          const SizedBox(height: 4.0),
          Text(
            '${'advisor.recommended_variety'.tr()} ${rec.variety} (${rec.scientificName})',
            style: const TextStyle(fontSize: 13.5, color: AppColors.soil700, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14.0),

          // Yield Metrics Bento Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.wheat50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.wheat300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('advisor.per_acre_yield'.tr(), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                      const SizedBox(height: 4.0),
                      Text(
                        '${rec.expectedYieldMinQuintal.toInt()} - ${rec.expectedYieldMaxQuintal.toInt()} ${'common.quintal'.tr()}',
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: AppColors.wheat900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.primary300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('advisor.total_yield_for_area'.tr(namedArgs: {'acres': '${state.landAreaAcres}'}), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                      const SizedBox(height: 4.0),
                      Text(
                        '~${rec.totalExpectedYieldQuintal} ${'common.quintal'.tr()}',
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: AppColors.primary700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Agronomic Reason / Summary
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.soil100,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.wheat700, size: 20.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    rec.summaryHi,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.soil800, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18.0),

          // Action Buttons: Save Plan & View Calendar
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: state.isPlanSaved ? 'advisor.plan_saved'.tr() : 'advisor.save_plan'.tr(),
                  variant: state.isPlanSaved ? ButtonVariant.outline : ButtonVariant.secondary,
                  onPressed: state.isPlanSaved
                      ? null
                      : () async {
                          final fId = farmerId ?? 'demo_farmer_id';
                          await controller.saveCurrentPlan(
                            farmerId: fId,
                            sowingDate: DateTime.now().add(const Duration(days: 7)),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('advisor.plan_saved_toast'.tr()),
                                backgroundColor: AppColors.primary600,
                              ),
                            );
                          }
                        },
                  icon: Icon(
                    state.isPlanSaved ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
                    size: 20.0,
                    color: AppColors.soil900,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: AppButton(
                  label: 'advisor.view_calendar'.tr(),
                  variant: ButtonVariant.primary,
                  onPressed: () => context.push(RouteNames.cropCalendar),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20.0, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.soil800),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.soil600, size: 20.0),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.soil300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.soil300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.primary500, width: 2.0),
      ),
    );
  }
}

