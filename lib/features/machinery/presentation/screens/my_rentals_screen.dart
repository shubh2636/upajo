import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/machinery_controller.dart';
import '../../domain/models/rental_booking_model.dart';

class MyRentalsScreen extends ConsumerStatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  ConsumerState<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends ConsumerState<MyRentalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).userProfile;
      if (user != null) {
        ref.read(machineryControllerProvider.notifier).loadUserRentals(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String? phone) async {
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
    final userId = user?.id ?? 'demo_user_id';

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: const Text('मेरी बुकिंग्स व किराए', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.soil900,
          unselectedLabelColor: AppColors.soil600,
          indicatorColor: AppColors.primary500,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: 'मेरे लिए गए (${state.myBorrowedRentals.length})'),
            Tab(text: 'मेरे दिए गए (${state.myLentRentals.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Borrowed by user
          _buildRentalList(
            rentals: state.myBorrowedRentals,
            isOwnerView: false,
            controller: controller,
            userId: userId,
            emptyTitle: 'कोई सक्रिय बुकिंग नहीं',
            emptySubtitle: 'आपने अभी तक कोई यंत्र किराए पर नहीं लिया है।',
          ),

          // Tab 2: Lent by user (Owner view)
          _buildRentalList(
            rentals: state.myLentRentals,
            isOwnerView: true,
            controller: controller,
            userId: userId,
            emptyTitle: 'कोई अनुरोध नहीं आया',
            emptySubtitle: 'आपके सूचीबद्ध यंत्रों पर अभी कोई बुकिंग अनुरोध नहीं आया है।',
          ),
        ],
      ),
    );
  }

  Widget _buildRentalList({
    required List<RentalBookingModel> rentals,
    required bool isOwnerView,
    required MachineryController controller,
    required String userId,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (rentals.isEmpty) {
      return EmptyStateView(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: Icons.receipt_long_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: rentals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final item = rentals[index];
        final statusColor = _getStatusColor(item.status);
        final statusLabel = _getStatusLabel(item.status);

        return AppCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.machineryTitle ?? 'कृषि यंत्र',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 16.0, color: AppColors.soil600),
                  const SizedBox(width: 6.0),
                  Text(
                    '${DateFormat('dd MMM').format(item.startDate)} से ${DateFormat('dd MMM yyyy').format(item.endDate)} (${item.totalDays} दिन)',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.soil700),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  const Icon(Icons.currency_rupee_rounded, size: 16.0, color: AppColors.primary600),
                  const SizedBox(width: 4.0),
                  Text(
                    'कुल राशि: ₹${item.totalAmount.toInt()} (जमानत: ₹${item.depositAmount.toInt()})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0, color: AppColors.soil900),
                  ),
                ],
              ),
              const Divider(height: 20.0),

              // Contact & Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16.0, color: AppColors.soil600),
                      const SizedBox(width: 4.0),
                      Text(
                        isOwnerView
                            ? 'किराएदार: ${item.renterName ?? "किसान"}'
                            : 'मालिक: ${item.ownerName ?? "किसान"}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.soil800, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: AppColors.primary600, size: 20.0),
                    onPressed: () => _makeCall(isOwnerView ? item.renterPhone : item.ownerPhone),
                    tooltip: 'कॉल करें',
                  ),
                ],
              ),

              // Owner Action Buttons (Approve / Reject)
              if (isOwnerView && item.status == 'pending') ...[
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        onPressed: () => controller.updateBookingStatus(item.id, 'approved', userId),
                        child: const Text('स्वीकार करें (Approve)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.clay500,
                          side: const BorderSide(color: AppColors.clay500),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        onPressed: () => controller.updateBookingStatus(item.id, 'rejected', userId),
                        child: const Text('अस्वीकार करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'completed':
        return AppColors.success500;
      case 'pending':
        return AppColors.wheat700;
      case 'in_use':
        return AppColors.primary600;
      case 'rejected':
      case 'cancelled':
        return AppColors.clay500;
      default:
        return AppColors.soil700;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'स्वीकृत (Approved)';
      case 'pending':
        return 'समीक्षाधीन (Pending)';
      case 'in_use':
        return 'उपयोग जारी (In Use)';
      case 'completed':
        return 'पूर्ण (Completed)';
      case 'rejected':
        return 'अस्वीकृत';
      case 'cancelled':
        return 'रद्द';
      default:
        return status;
    }
  }
}

