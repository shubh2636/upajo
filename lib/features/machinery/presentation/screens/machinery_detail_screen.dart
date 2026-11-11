import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/machinery_controller.dart';
import '../../domain/models/machinery_model.dart';

class MachineryDetailScreen extends ConsumerStatefulWidget {
  final MachineryModel machine;

  const MachineryDetailScreen({super.key, required this.machine});

  @override
  ConsumerState<MachineryDetailScreen> createState() => _MachineryDetailScreenState();
}

class _MachineryDetailScreenState extends ConsumerState<MachineryDetailScreen> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  int get _totalDays {
    final diff = _endDate.difference(_startDate).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  double get _totalRent => _totalDays * widget.machine.dailyRate;
  double get _grandTotal => _totalRent + widget.machine.securityDeposit;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.soil900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _callOwner() async {
    final phone = widget.machine.ownerPhone;
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(machineryControllerProvider);
    final controller = ref.read(machineryControllerProvider.notifier);
    final user = ref.watch(authControllerProvider).userProfile;
    final renterId = user?.id ?? 'demo_renter_id';
    final title = context.locale.languageCode == 'en' ? widget.machine.titleEn : widget.machine.titleHi;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0)),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.soil200)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('machinery.total_est_amount'.tr(), style: const TextStyle(fontSize: 11.0, color: AppColors.soil600)),
                  Text(
                    '₹${_grandTotal.toInt()}',
                    style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w900, color: AppColors.primary700),
                  ),
                ],
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: AppButton(
                  label: 'machinery.send_booking_req'.tr(),
                  isLoading: state.isLoading,
                  onPressed: () async {
                    final success = await controller.requestBooking(
                      machineryId: widget.machine.id,
                      renterId: renterId,
                      ownerId: widget.machine.ownerId,
                      startDate: _startDate,
                      endDate: _endDate,
                      dailyRate: widget.machine.dailyRate,
                      securityDeposit: widget.machine.securityDeposit,
                    );

                    if (!mounted) return;
                    if (success) {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary500),
                              const SizedBox(width: 8.0),
                              Text('machinery.booking_sent_title'.tr()),
                            ],
                          ),
                          content: Text(
                            'machinery.booking_sent_desc'.tr(args: [widget.machine.ownerName ?? 'machinery.verified_farmer'.tr()]),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.pushReplacement(RouteNames.myRentals);
                              },
                              child: Text('machinery.view_my_bookings'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Machine Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: Image.network(
                widget.machine.images.isNotEmpty
                    ? widget.machine.images.first
                    : 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600',
                height: 220.0,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220.0,
                  color: AppColors.soil200,
                  child: const Center(
                    child: Icon(Icons.agriculture_rounded, size: 64.0, color: AppColors.soil400),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Title & Location Card
            AppCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.displayMedium.copyWith(fontSize: 20.0, color: AppColors.soil900),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    widget.machine.titleEn,
                    style: const TextStyle(fontSize: 13.0, color: AppColors.soil600),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 18.0, color: AppColors.primary600),
                      const SizedBox(width: 6.0),
                      Text(
                        '${widget.machine.villageOrCity}, ${widget.machine.district}, ${widget.machine.state}',
                        style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: AppColors.soil800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),

            // Specifications Bento Grid
            Row(
              children: [
                _specTile('machinery.spec_power'.tr(), '${widget.machine.hp} HP', Icons.speed_rounded),
                const SizedBox(width: 10.0),
                _specTile('machinery.model_year'.tr(), '${widget.machine.modelYear}', Icons.calendar_today_rounded),
                const SizedBox(width: 10.0),
                _specTile('machinery.spec_rating'.tr(), '${widget.machine.rating} ★', Icons.star_rounded, color: AppColors.wheat700),
              ],
            ),
            const SizedBox(height: 14.0),

            // Owner Details Card
            AppCard(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      color: AppColors.primary50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary600, size: 24.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.machine.ownerName ?? 'machinery.verified_owner_badge'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        Text('machinery.owner_doc_verified'.tr(), style: const TextStyle(fontSize: 11.5, color: AppColors.primary600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: AppColors.primary600),
                    onPressed: _callOwner,
                    tooltip: 'machinery.call_owner_tooltip'.tr(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Date Picker Card
            AppCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'machinery.booking_duration'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18.0),
                        label: Text('machinery.change_dates'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        onPressed: _selectDateRange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.soil100,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('machinery.start_date'.tr(), style: const TextStyle(fontSize: 11.0, color: AppColors.soil600)),
                            const SizedBox(height: 4.0),
                            Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.soil400),
                        Column(
                          children: [
                            Text('machinery.end_date'.tr(), style: const TextStyle(fontSize: 11.0, color: AppColors.soil600)),
                            const SizedBox(height: 4.0),
                            Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('machinery.total_duration'.tr(), style: const TextStyle(fontSize: 11.0, color: AppColors.soil600)),
                            const SizedBox(height: 4.0),
                            Text('machinery.days_count'.tr(args: [_totalDays.toString()]), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0, color: AppColors.primary700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Rent Calculation Breakdown Card
            AppCard(
              padding: const EdgeInsets.all(16.0),
              backgroundColor: AppColors.wheat50,
              borderColor: AppColors.wheat300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('machinery.price_calc'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                  const SizedBox(height: 10.0),
                  _breakdownRow('machinery.daily_rate_breakdown'.tr(args: [widget.machine.dailyRate.toInt().toString(), _totalDays.toString()]), '₹${_totalRent.toInt()}'),
                  const SizedBox(height: 6.0),
                  _breakdownRow('machinery.deposit_record_label'.tr(), '₹${widget.machine.securityDeposit.toInt()}'),
                  const Divider(height: 20.0, color: AppColors.wheat300),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('machinery.total_payable'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0)),
                      Text('₹${_grandTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18.0, color: AppColors.soil900)),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'machinery.deposit_security_disclaimer'.tr(),
                    style: const TextStyle(fontSize: 11.0, color: AppColors.soil600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _specTile(String title, String val, IconData icon, {Color color = AppColors.primary600}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.soil200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.0),
            const SizedBox(height: 4.0),
            Text(title, style: const TextStyle(fontSize: 10.5, color: AppColors.soil600)),
            const SizedBox(height: 2.0),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.soil700)),
        Text(amount, style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
