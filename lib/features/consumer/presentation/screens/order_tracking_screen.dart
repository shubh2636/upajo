import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../analytics/data/services/invoice_pdf_generator.dart';
import '../../../marketplace/domain/models/order_model.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';
import 'order_rating_sheet.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPickup = order.deliveryMode == 'pickup';

    // Status steps index:
    // 0: confirmed, 1: harvesting_packed, 2: out_for_delivery/ready_for_pickup, 3: delivered
    int currentStep = 0;
    if (order.status == 'harvesting_packed') currentStep = 1;
    if (order.status == 'out_for_delivery' || order.status == 'ready_for_pickup') currentStep = 2;
    if (order.status == 'delivered') currentStep = 3;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('${'nav.orders'.tr()}: ${order.orderNumber}'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Summary Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: currentStep == 3 ? AppColors.primary500 : AppColors.wheat500,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentStep == 3 ? '${'consumer.step_delivered'.tr()} ✓' : 'consumer.in_transit'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.0),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    isPickup ? 'consumer.farmgate_pickup'.tr() : 'consumer.home_delivery'.tr(),
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13.0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20.0),

            // Timeline Stepper Card
            AppCard(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('consumer.status_timeline'.tr(), style: AppTypography.headlineSmall),
                  const SizedBox(height: 20.0),

                  _buildStep(
                    title: 'consumer.step_confirmed'.tr(),
                    subtitle: 'consumer.step_confirmed'.tr(),
                    isActive: currentStep >= 0,
                    isDone: currentStep > 0,
                  ),
                  _buildStep(
                    title: 'consumer.step_packed'.tr(),
                    subtitle: 'consumer.step_packed'.tr(),
                    isActive: currentStep >= 1,
                    isDone: currentStep > 1,
                  ),
                  _buildStep(
                    title: isPickup ? 'consumer.step_ready_pickup'.tr() : 'consumer.step_out_delivery'.tr(),
                    subtitle: isPickup ? 'consumer.step_ready_pickup'.tr() : 'consumer.step_out_delivery'.tr(),
                    isActive: currentStep >= 2,
                    isDone: currentStep > 2,
                  ),
                  _buildStep(
                    title: 'consumer.step_delivered'.tr(),
                    subtitle: 'consumer.step_delivered'.tr(),
                    isActive: currentStep >= 3,
                    isDone: currentStep >= 3,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18.0),

            // Farmer Contact Card
            AppCard(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22.0,
                    backgroundColor: AppColors.primary100,
                    child: Icon(Icons.person_rounded, color: AppColors.primary600),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${'auth.role_farmer'.tr()}: ${order.farmerName ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                        Text('farmer.whatsapp_customer'.tr(), style: const TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: AppColors.primary600),
                    onPressed: () {
                      final phone = order.farmerPhone;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            phone != null && phone.isNotEmpty
                                ? '+91 $phone'
                                : 'common.empty'.tr(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18.0),

            // Download Invoice Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                side: const BorderSide(color: AppColors.primary400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary600),
              label: Text(
                'consumer.download_gst_invoice'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary700),
              ),
              onPressed: () {
                InvoicePdfGenerator.printOrShareInvoice(
                  invoiceNumber: order.orderNumber,
                  farmerName: order.farmerName ?? 'Verified Farmer',
                  farmerVillage: 'Madhya Pradesh',
                  farmerDistrict: 'Madhya Pradesh',
                  farmerPhone: order.farmerPhone ?? '',
                  buyerName: order.deliveryAddress['full_name'] as String? ?? 'Buyer',
                  buyerAddress: order.deliveryAddress['address_line'] as String? ?? '',
                  buyerPhone: order.deliveryAddress['phone'] as String? ?? '',
                  cropName: 'Produce',
                  variety: 'Grade-A',
                  packSizeKg: 10,
                  quantityPacks: 1,
                  pricePerKg: order.subtotalAmount > 0 ? (order.subtotalAmount / 10) : 35.0,
                  deliveryFee: order.deliveryFee,
                  paymentMode: order.paymentMethod,
                );
              },
            ),

            const SizedBox(height: 14.0),

            // Live OSM Delivery Tracking
            if (!isPickup) ...[
              AppButton(
                label: 'consumer.track_live_osm'.tr(),
                variant: ButtonVariant.primary,
                onPressed: () => context.push(RouteNames.liveTracking, extra: order.id),
                icon: const Icon(Icons.navigation_rounded, size: 20.0, color: Colors.white),
              ),
              const SizedBox(height: 12.0),
            ],

            // Cancel Order Button (Available only if placed or confirmed)
            if (order.status == 'placed' || order.status == 'confirmed') ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.clay500,
                  side: const BorderSide(color: AppColors.clay300),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('consumer.cancel_order_prompt'.tr()),
                      content: Text('consumer.cancel_order_prompt'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('common.no'.tr()),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.clay500),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('consumer.cancel_order_action'.tr(), style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(marketplaceRepositoryProvider).updateOrderStatus(order.id, 'cancelled');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('consumer.cancel_order_action'.tr())),
                      );
                      context.pop();
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined, size: 20.0),
                label: Text('consumer.cancel_order_action'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12.0),
            ],

            // Rating CTA if Delivered
            if (currentStep == 3)
              AppButton(
                label: 'consumer.rate_produce'.tr(),
                variant: ButtonVariant.secondary,
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => OrderRatingSheet(order: order),
                  );
                },
                icon: const Icon(Icons.star_rounded, size: 22.0),
              ),

            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary500
                    : isActive
                        ? AppColors.wheat500
                        : AppColors.soil200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : Icons.circle,
                size: isDone ? 15.0 : 8.0,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: 48.0,
                color: isDone ? AppColors.primary500 : AppColors.soil200,
              ),
          ],
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: isActive ? AppColors.soil900 : AppColors.soil400,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isActive ? AppColors.soil600 : AppColors.soil400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

