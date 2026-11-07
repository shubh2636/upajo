import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../marketplace/domain/models/order_model.dart';
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
        title: Text('ऑर्डर: ${order.orderNumber}'),
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
                    currentStep == 3 ? 'ऑर्डर प्राप्त हो चुका है (Delivered) ✓' : 'ऑर्डर प्रगति पर है (In Progress)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.0),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    isPickup ? 'खेत से उठाना (Farm Pickup)' : 'घर पर डिलीवरी (Doorstep Delivery)',
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
                  Text('ऑर्डर प्रगति स्थिति (Status Timeline)', style: AppTypography.headlineSmall),
                  const SizedBox(height: 20.0),

                  _buildStep(
                    title: 'ऑर्डर स्वीकृत (Confirmed)',
                    subtitle: 'किसान द्वारा ऑर्डर स्वीकार कर लिया गया है',
                    isActive: currentStep >= 0,
                    isDone: currentStep > 0,
                  ),
                  _buildStep(
                    title: 'कटाई व पैकिंग पूर्ण (Packed)',
                    subtitle: 'खेत से ताज़ी फसल पैक कर दी गई है',
                    isActive: currentStep >= 1,
                    isDone: currentStep > 1,
                  ),
                  _buildStep(
                    title: isPickup ? 'खेत से उठाने के लिए तैयार' : 'डिलीवरी के लिए रवाना (Out for Delivery)',
                    subtitle: isPickup ? 'आप सीधे किसान के खेत जाकर उठा सकते हैं' : 'डिलीवरी पार्टनर रास्ते में है',
                    isActive: currentStep >= 2,
                    isDone: currentStep > 2,
                  ),
                  _buildStep(
                    title: 'सफलतापूर्वक प्राप्त (Delivered)',
                    subtitle: 'फसल आपके हाथों में सुरक्षित पहुँच चुकी है',
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
                        Text('अन्नदाता: ${order.farmerName ?? 'सत्यापित किसान'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                        const Text('सीधे किसान से संपर्क करें', style: TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: AppColors.primary600),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('किसान से संपर्क: ${order.farmerPhone ?? '+91 9876543210'}')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18.0),

            // Live OSM Delivery Tracking (Part 5)
            if (!isPickup) ...[
              AppButton(
                label: 'लाइव डिलीवरी ट्रैक करें (Live OSM Map)',
                variant: ButtonVariant.primary,
                onPressed: () => context.push(RouteNames.liveTracking, extra: order.id),
                icon: const Icon(Icons.navigation_rounded, size: 20.0, color: Colors.white),
              ),
              const SizedBox(height: 12.0),
            ],

            // Rating CTA if Delivered
            if (currentStep == 3)
              AppButton(
                label: 'फसल की गुणवत्ता को रेट करें (Rate Produce)',
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

