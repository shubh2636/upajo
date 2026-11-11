import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../controllers/machinery_controller.dart';
import '../../domain/models/machinery_model.dart';

class MachineryBrowseScreen extends ConsumerStatefulWidget {
  const MachineryBrowseScreen({super.key});

  @override
  ConsumerState<MachineryBrowseScreen> createState() => _MachineryBrowseScreenState();
}

class _MachineryBrowseScreenState extends ConsumerState<MachineryBrowseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(machineryControllerProvider.notifier).loadMachinery();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(machineryControllerProvider);
    final controller = ref.read(machineryControllerProvider.notifier);

    final categories = [
      {'id': 'all', 'label': 'machinery.cat_all'.tr()},
      {'id': 'tractor', 'label': 'machinery.cat_tractor'.tr()},
      {'id': 'rotavator', 'label': 'machinery.cat_rotavator'.tr()},
      {'id': 'harvester', 'label': 'machinery.cat_harvester'.tr()},
      {'id': 'drone_sprayer', 'label': 'machinery.cat_drone'.tr()},
      {'id': 'seed_drill', 'label': 'machinery.cat_seed_drill'.tr()},
      {'id': 'thresher', 'label': 'machinery.cat_thresher'.tr()},
    ];

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('machinery.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'machinery.my_rentals_tooltip'.tr(),
            onPressed: () => context.push(RouteNames.myRentals),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        elevation: 3.0,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 22.0),
        label: Text('machinery.list_machine'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        onPressed: () => context.push(RouteNames.listMachinery),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadMachinery(),
        color: AppColors.primary500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Earthy Rental Banner
              _buildTopHeroBanner(),

              const SizedBox(height: 16.0),

              // 2. Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = state.selectedType == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat['label']!),
                        selected: isSelected,
                        onSelected: (_) => controller.filterByType(cat['id']!),
                        selectedColor: AppColors.primary500,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.soil800,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary500 : AppColors.soil300,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16.0),

              // 3. Machinery List
              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary500),
                  ),
                )
              else if (state.machineryList.isEmpty)
                EmptyStateView(
                  title: 'machinery.no_machinery_title'.tr(),
                  subtitle: 'machinery.no_machinery_sub'.tr(),
                  icon: Icons.agriculture_rounded,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.machineryList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                  itemBuilder: (context, index) {
                    final machine = state.machineryList[index];
                    return _buildMachineryCard(context, machine, controller);
                  },
                ),

              const SizedBox(height: 80.0), // Padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.wheat50,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.wheat300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.wheat500,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(Icons.handshake_rounded, color: AppColors.soil900, size: 28.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'machinery.hero_title'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: AppColors.soil900),
                ),
                const SizedBox(height: 3.0),
                Text(
                  'machinery.hero_desc'.tr(),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.soil700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineryCard(BuildContext context, MachineryModel machine, MachineryController controller) {
    final title = context.locale.languageCode == 'en' ? machine.titleEn : machine.titleHi;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        controller.selectMachine(machine);
        context.push(RouteNames.machineryDetail, extra: machine);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                child: Image.network(
                  machine.images.isNotEmpty
                      ? machine.images.first
                      : 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600',
                  height: 170.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 170.0,
                    color: AppColors.soil200,
                    child: const Center(
                      child: Icon(Icons.agriculture_rounded, size: 64.0, color: AppColors.soil400),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10.0,
                left: 10.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14.0, color: AppColors.wheat400),
                      const SizedBox(width: 3.0),
                      Text(
                        '${machine.rating} (${machine.totalBookings})',
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              if (machine.hp > 0)
                Positioned(
                  top: 10.0,
                  right: 10.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'machinery.hp_power'.tr(args: [machine.hp.toString()]),
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: AppColors.soil900),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15.0, color: AppColors.soil600),
                    const SizedBox(width: 4.0),
                    Text(
                      '${machine.villageOrCity}, ${machine.district}',
                      style: const TextStyle(fontSize: 12.0, color: AppColors.soil600),
                    ),
                    const Spacer(),
                    Text(
                      'machinery.owner_prefix'.tr(args: [machine.ownerName ?? 'machinery.verified_farmer'.tr()]),
                      style: const TextStyle(fontSize: 12.0, color: AppColors.primary700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Pricing Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${machine.dailyRate.toInt()}',
                              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w900, color: AppColors.soil900),
                            ),
                            Text('/${'machinery.per_day'.tr()}', style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),
                            const SizedBox(width: 8.0),
                            Text(
                              '(₹${machine.hourlyRate.toInt()}/${'machinery.per_hour'.tr()})',
                              style: const TextStyle(fontSize: 12.0, color: AppColors.soil500),
                            ),
                          ],
                        ),
                        Text(
                          'machinery.deposit_record_amount'.tr(args: ['₹${machine.securityDeposit.toInt()}']),
                          style: const TextStyle(fontSize: 11.0, color: AppColors.wheat800, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      ),
                      onPressed: () {
                        controller.selectMachine(machine);
                        context.push(RouteNames.machineryDetail, extra: machine);
                      },
                      child: Text('machinery.rent_now'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
