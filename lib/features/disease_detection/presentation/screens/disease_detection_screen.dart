import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/disease_detection_controller.dart';
import '../../domain/models/disease_scan_result.dart';

class DiseaseDetectionScreen extends ConsumerStatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  ConsumerState<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends ConsumerState<DiseaseDetectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).userProfile;
      if (user != null) {
        ref.read(diseaseDetectionControllerProvider.notifier).loadScanHistory(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _callKisanHelpline() async {
    final uri = Uri.parse('tel:18001801551');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diseaseDetectionControllerProvider);
    final controller = ref.read(diseaseDetectionControllerProvider.notifier);
    final user = ref.watch(authControllerProvider).userProfile;
    final farmerId = user?.id ?? 'demo_farmer_id';

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('disease.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.soil900,
          unselectedLabelColor: AppColors.soil600,
          indicatorColor: AppColors.primary500,
          indicatorWeight: 3.0,
          tabs: [
            Tab(icon: const Icon(Icons.camera_alt_outlined), text: 'disease.tab_new'.tr()),
            Tab(icon: const Icon(Icons.history_rounded), text: 'disease.tab_history'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Scan & Result
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Guidance Banner
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.primary200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: AppColors.primary600, size: 24.0),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          'disease.guidance'.tr(),
                          style: AppTypography.bodySmall.copyWith(color: AppColors.soil800, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18.0),

                // Image Picker / Preview Card
                _buildImageCaptureArea(state, controller, farmerId),

                const SizedBox(height: 20.0),

                // Loading State
                if (state.isAnalyzing)
                  _buildAnalyzingIndicator(),

                // Error State
                if (state.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(top: 12.0),
                    decoration: BoxDecoration(
                      color: AppColors.error50,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.error300),
                    ),
                    child: Text(state.errorMessage!, style: const TextStyle(color: AppColors.error700)),
                  ),

                // Scan Result Card
                if (state.scanResult != null && !state.isAnalyzing)
                  _buildResultCard(state.scanResult!, controller),

                const SizedBox(height: 24.0),

                // Kisan Helpline Escalation Card
                _buildKvkHelplineCard(),

                const SizedBox(height: 32.0),
              ],
            ),
          ),

          // TAB 2: Scan History
          _buildHistoryList(state.scanHistory),
        ],
      ),
    );
  }

  Widget _buildImageCaptureArea(
    DiseaseDetectionState state,
    DiseaseDetectionController controller,
    String farmerId,
  ) {
    if (state.selectedImage != null) {
      return AppCard(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.file(
                state.selectedImage!,
                height: 220.0,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'disease.retake_camera'.tr(),
                    variant: ButtonVariant.secondary,
                    onPressed: () => controller.pickAndAnalyzeImage(
                      source: ImageSource.camera,
                      farmerId: farmerId,
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 20.0, color: AppColors.soil900),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: AppButton(
                    label: 'disease.retake_gallery'.tr(),
                    variant: ButtonVariant.outline,
                    onPressed: () => controller.pickAndAnalyzeImage(
                      source: ImageSource.gallery,
                      farmerId: farmerId,
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 20.0, color: AppColors.soil900),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_rounded, size: 54.0, color: AppColors.primary600),
          ),
          const SizedBox(height: 16.0),
          Text(
            'disease.capture_title'.tr(),
            style: AppTypography.headlineMedium.copyWith(fontSize: 20.0),
          ),
          const SizedBox(height: 6.0),
          Text(
            'disease.capture_desc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.soil600, fontSize: 13.0),
          ),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'disease.camera_btn'.tr(),
                  variant: ButtonVariant.primary,
                  onPressed: () => controller.pickAndAnalyzeImage(
                    source: ImageSource.camera,
                    farmerId: farmerId,
                  ),
                  icon: const Icon(Icons.photo_camera_rounded, size: 22.0, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: AppButton(
                  label: 'disease.gallery_btn'.tr(),
                  variant: ButtonVariant.secondary,
                  onPressed: () => controller.pickAndAnalyzeImage(
                    source: ImageSource.gallery,
                    farmerId: farmerId,
                  ),
                  icon: const Icon(Icons.photo_library_rounded, size: 22.0, color: AppColors.soil900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return AppCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(
            width: 44.0,
            height: 44.0,
            child: CircularProgressIndicator(strokeWidth: 3.5, color: AppColors.primary500),
          ),
          const SizedBox(height: 16.0),
          Text('disease.analyzing'.tr(), style: AppTypography.headlineSmall.copyWith(fontSize: 17.0)),
          const SizedBox(height: 6.0),
          Text(
            'disease.analyzing_sub'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.0, color: AppColors.soil600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(DiseaseScanResult result, DiseaseDetectionController controller) {
    final severityColor = _getSeverityColor(result.severity);
    final severityText = _getSeverityText(result.severity);

    return AppCard(
      padding: const EdgeInsets.all(20.0),
      borderColor: severityColor.withOpacity(0.5),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Crop + Severity + Confidence
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: severityColor.withOpacity(0.4)),
                ),
                child: Text(
                  severityText,
                  style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
              Text(
                'disease.accuracy'.tr(args: [(result.confidenceScore * 100).toStringAsFixed(1)]),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.soil600),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Disease Name
          Text(
            result.diseaseNameHi,
            style: AppTypography.displayMedium.copyWith(fontSize: 22.0, color: AppColors.soil900),
          ),
          const SizedBox(height: 4.0),
          Text(
            '${result.cropName} • ${result.diseaseNameEn}',
            style: const TextStyle(fontSize: 13.0, color: AppColors.soil700, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14.0),

          // Symptoms Card
          if (result.symptomsHi.isNotEmpty) ...[
            _sectionHeader('disease.symptoms_header'.tr(), Icons.search_rounded),
            const SizedBox(height: 4.0),
            Text(result.symptomsHi, style: const TextStyle(fontSize: 13.0, color: AppColors.soil800, height: 1.35)),
            const SizedBox(height: 14.0),
          ],

          // Organic Treatment Card
          _sectionHeader('disease.organic_control'.tr(), Icons.eco_rounded, color: AppColors.primary600),
          const SizedBox(height: 4.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: AppColors.primary200),
            ),
            child: Text(
              result.organicTreatmentHi,
              style: const TextStyle(fontSize: 12.5, color: AppColors.soil900, height: 1.4),
            ),
          ),
          const SizedBox(height: 14.0),

          // Safe Chemical Dosage Card
          _sectionHeader('disease.chemical_control'.tr(), Icons.science_rounded, color: AppColors.wheat700),
          const SizedBox(height: 4.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.wheat50,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: AppColors.wheat300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.chemicalTreatmentHi,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.soil900, height: 1.4),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16.0, color: AppColors.wheat800),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        'disease.safety_mask_note'.tr(),
                        style: const TextStyle(fontSize: 11.0, color: AppColors.wheat900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          // Prevention
          if (result.preventionHi.isNotEmpty) ...[
            _sectionHeader('disease.prevention_header'.tr(), Icons.security_rounded),
            const SizedBox(height: 4.0),
            Text(result.preventionHi, style: const TextStyle(fontSize: 12.5, color: AppColors.soil700, height: 1.35)),
            const SizedBox(height: 16.0),
          ],

          // Retake Button
          AppButton(
            label: 'disease.scan_new'.tr(),
            variant: ButtonVariant.secondary,
            onPressed: () => controller.clearCurrentScan(),
            icon: const Icon(Icons.refresh_rounded, size: 20.0, color: AppColors.soil900),
          ),
        ],
      ),
    );
  }

  Widget _buildKvkHelplineCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.terracotta50,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.terracotta200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: AppColors.terracotta600, size: 26.0),
              const SizedBox(width: 10.0),
              Text(
                'disease.expert_talk'.tr(),
                style: AppTypography.headlineSmall.copyWith(fontSize: 16.0, color: AppColors.terracotta800),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            'disease.expert_talk_desc'.tr(),
            style: const TextStyle(fontSize: 12.0, color: AppColors.soil700),
          ),
          const SizedBox(height: 12.0),
          AppButton(
            label: 'disease.helpline_btn_label'.tr(),
            variant: ButtonVariant.terracotta,
            onPressed: _callKisanHelpline,
            icon: const Icon(Icons.phone_in_talk_rounded, size: 20.0, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<DiseaseScanResult> history) {
    if (history.isEmpty) {
      return EmptyStateView(
        title: 'disease.no_history_title'.tr(),
        subtitle: 'disease.no_history_sub'.tr(),
        icon: Icons.history_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final item = history[index];
        final sevColor = _getSeverityColor(item.severity);
        return AppCard(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50.0,
                height: 50.0,
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(Icons.coronavirus_rounded, color: sevColor, size: 28.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.diseaseNameHi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0)),
                    const SizedBox(height: 3.0),
                    Text('${item.cropName} • ' + 'disease.accuracy'.tr(args: [(item.confidenceScore * 100).toInt().toString()]), style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),
                    const SizedBox(height: 3.0),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(item.scannedAt),
                      style: const TextStyle(fontSize: 11.0, color: AppColors.soil500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon, {Color color = AppColors.soil800}) {
    return Row(
      children: [
        Icon(icon, size: 18.0, color: color),
        const SizedBox(width: 6.0),
        Text(
          title,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'none':
        return AppColors.success500;
      case 'low':
        return AppColors.primary500;
      case 'medium':
        return AppColors.wheat700;
      case 'severe':
        return AppColors.terracotta500;
      default:
        return AppColors.wheat700;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity) {
      case 'none':
        return 'disease.severity_healthy'.tr();
      case 'low':
        return 'disease.severity_low'.tr();
      case 'medium':
        return 'disease.severity_medium'.tr();
      case 'severe':
        return 'disease.severity_severe'.tr();
      default:
        return 'disease.severity_medium'.tr();
    }
  }
}

