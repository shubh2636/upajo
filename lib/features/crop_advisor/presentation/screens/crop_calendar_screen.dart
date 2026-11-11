import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/crop_advisor_controller.dart';
import '../../domain/models/crop_recommendation.dart';

class CropCalendarScreen extends ConsumerStatefulWidget {
  const CropCalendarScreen({super.key});

  @override
  ConsumerState<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends ConsumerState<CropCalendarScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'completed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).userProfile;
      final currentTasks = ref.read(cropAdvisorControllerProvider).activeTasks;
      if (currentTasks.isEmpty && user != null) {
        ref.read(cropAdvisorControllerProvider.notifier).loadFarmerTasks(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cropAdvisorControllerProvider);
    final controller = ref.read(cropAdvisorControllerProvider.notifier);

    final allTasks = state.activeTasks;
    final completedCount = allTasks.where((t) => t.isCompleted).length;
    final totalCount = allTasks.length;
    final progressPercent = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    List<CropCalendarTask> filteredTasks = allTasks;
    if (_selectedFilter == 'pending') {
      filteredTasks = allTasks.where((t) => !t.isCompleted).toList();
    } else if (_selectedFilter == 'completed') {
      filteredTasks = allTasks.where((t) => t.isCompleted).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('advisor.crop_calendar'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Calendar Progress Bento Card
            _buildProgressCard(totalCount, completedCount, progressPercent, state.recommendation),

            const SizedBox(height: 16.0),

            // 2. Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'advisor.all_tasks'.tr(namedArgs: {'count': '$totalCount'})),
                  const SizedBox(width: 8.0),
                  _filterChip('pending', 'advisor.pending_tasks'.tr(namedArgs: {'count': '${totalCount - completedCount}'})),
                  const SizedBox(width: 8.0),
                  _filterChip('completed', 'advisor.completed_tasks'.tr(namedArgs: {'count': '$completedCount'})),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // 3. Task List
            if (filteredTasks.isEmpty)
              EmptyStateView(
                title: 'common.empty'.tr(),
                subtitle: 'advisor.no_tasks_desc'.tr(),
                icon: Icons.task_alt_rounded,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return _buildTaskCard(task, controller);
                },
              ),

            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    int totalCount,
    int completedCount,
    double progress,
    CropRecommendation? rec,
  ) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.soil200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
                    rec != null ? rec.nameHi : 'advisor.crop_calendar'.tr(),
                    style: AppTypography.headlineSmall.copyWith(fontSize: 18.0),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    rec != null ? '${'advisor.recommended_variety'.tr()} ${rec.variety}' : '2026-27',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.soil600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.primary200),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% ${'common.completed'.tr()}',
                  style: const TextStyle(color: AppColors.primary700, fontWeight: FontWeight.bold, fontSize: 13.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10.0,
              backgroundColor: AppColors.soil200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount/$totalCount ${'advisor.tasks_completed'.tr()}',
                style: const TextStyle(fontSize: 12.0, color: AppColors.soil700, fontWeight: FontWeight.w600),
              ),
              Text(
                'advisor.icar_calendar'.tr(),
                style: const TextStyle(fontSize: 11.5, color: AppColors.wheat700, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _selectedFilter == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = id),
      selectedColor: AppColors.primary500,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.soil800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13.0,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary500 : AppColors.soil300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
    );
  }

  Widget _buildTaskCard(CropCalendarTask task, CropAdvisorController controller) {
    final stageColor = _getStageColor(task.stage);
    final stageLabel = _getStageLabel(task.stage);

    return AppCard(
      padding: const EdgeInsets.all(16.0),
      backgroundColor: task.isCompleted ? AppColors.soil100.withOpacity(0.5) : Colors.white,
      borderColor: task.isCompleted ? AppColors.soil300 : AppColors.soil200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accessible Checkbox
              SizedBox(
                width: 32.0,
                height: 32.0,
                child: Checkbox(
                  value: task.isCompleted,
                  activeColor: AppColors.primary500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                  onChanged: (val) {
                    if (val != null) {
                      controller.toggleTask(task.id, val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8.0),

              // Title and Stage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: stageColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(color: stageColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            stageLabel,
                            style: TextStyle(color: stageColor, fontSize: 11.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          task.daysAfterSowing >= 0
                              ? 'advisor.sowing_plus'.tr(namedArgs: {'days': '${task.daysAfterSowing}'})
                              : 'advisor.before_sowing'.tr(),
                          style: const TextStyle(fontSize: 11.5, color: AppColors.soil600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      task.titleHi,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: task.isCompleted ? AppColors.soil500 : AppColors.soil900,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10.0),

          // Description & Agronomic Instruction
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColors.soil50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16.0, color: AppColors.soil500),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    task.descriptionHi,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: task.isCompleted ? AppColors.soil500 : AppColors.soil700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Due Date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14.0, color: AppColors.soil500),
                  const SizedBox(width: 4.0),
                  Text(
                    '${'advisor.due_date'.tr()}: ${DateFormat('dd MMM yyyy').format(task.dueDate)}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.soil600),
                  ),
                ],
              ),
              if (task.isCompleted)
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14.0, color: AppColors.primary600),
                    const SizedBox(width: 4.0),
                    Text(
                      'common.done'.tr(),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.primary600, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'soil_prep':
        return AppColors.soil700;
      case 'sowing':
        return AppColors.primary600;
      case 'irrigation':
        return const Color(0xFF1976D2);
      case 'fertilizer':
        return AppColors.wheat700;
      case 'pest_control':
        return AppColors.terracotta500;
      case 'harvesting':
        return const Color(0xFFE65100);
      default:
        return AppColors.soil700;
    }
  }

  String _getStageLabel(String stage) {
    switch (stage) {
      case 'soil_prep':
        return 'advisor.task_field_prep'.tr();
      case 'sowing':
        return 'advisor.task_sowing'.tr();
      case 'irrigation':
        return 'advisor.task_irrigation'.tr();
      case 'fertilizer':
        return 'advisor.task_fertilizer'.tr();
      case 'pest_control':
        return 'advisor.task_pest'.tr();
      case 'harvesting':
        return 'advisor.task_harvest'.tr();
      default:
        return 'advisor.task_general'.tr();
    }
  }
}
