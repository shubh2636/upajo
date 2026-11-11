import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../marketplace/presentation/controllers/cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final cartNotifier = ref.read(cartControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('consumer.cart_title'.tr()),
        backgroundColor: Colors.white,
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () => cartNotifier.clearCart(),
              child: Text('consumer.clear_cart'.tr(), style: const TextStyle(color: AppColors.clay500, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: cartState.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 64.0, color: AppColors.soil400),
                    const SizedBox(height: 16.0),
                    Text('consumer.empty_cart_title'.tr(), style: AppTypography.headlineMedium),
                    const SizedBox(height: 6.0),
                    Text('consumer.empty_cart_desc'.tr(), style: const TextStyle(color: AppColors.soil600)),
                    const SizedBox(height: 24.0),
                    AppButton(
                      label: 'consumer.browse_market_btn'.tr(),
                      onPressed: () => context.go(RouteNames.consumerHome),
                      width: 250.0,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cart Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartState.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return AppCard(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(
                                item.product.images.isNotEmpty ? item.product.images.first : '',
                                width: 70.0,
                                height: 70.0,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(width: 70.0, height: 70.0, color: AppColors.soil100),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.titleHi, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                  const SizedBox(height: 2.0),
                                  Text('${item.packSizeKg} ${'common.kg'.tr()} (₹${item.pricePerPack.toStringAsFixed(0)} / ${'common.unit'.tr()})', style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),
                                  const SizedBox(height: 6.0),
                                  Text('₹${item.totalPrice.toStringAsFixed(0)}', style: AppTypography.headlineSmall.copyWith(color: AppColors.primary600)),
                                ],
                              ),
                            ),
                            // Quantity selector
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 22.0),
                                  onPressed: () {
                                    cartNotifier.updateQuantity(item.product.id, item.packSizeKg, item.quantity - 1);
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 22.0),
                                  onPressed: () {
                                    cartNotifier.updateQuantity(item.product.id, item.packSizeKg, item.quantity + 1);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20.0),

                  // Delivery Preference Toggle
                  AppCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('consumer.delivery_mode_label'.tr(), style: AppTypography.headlineSmall),
                        const SizedBox(height: 12.0),

                        RadioListTile<String>(
                          value: 'pickup',
                          groupValue: cartState.deliveryMode,
                          title: Text('consumer.farmgate_pickup'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                          subtitle: Text('consumer.pickup_subtitle'.tr(), style: const TextStyle(fontSize: 11.5)),
                          activeColor: AppColors.primary500,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => cartNotifier.setDeliveryMode(val!),
                        ),
                        const Divider(height: 16.0),

                        RadioListTile<String>(
                          value: 'self_delivery',
                          groupValue: cartState.deliveryMode,
                          title: Text('consumer.home_delivery'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                          subtitle: Text('consumer.delivery_subtitle'.tr(), style: const TextStyle(fontSize: 11.5)),
                          activeColor: AppColors.primary500,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => cartNotifier.setDeliveryMode(val!),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20.0),

                  // Bill Breakdown Card
                  AppCard(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('consumer.bill_summary'.tr(), style: AppTypography.headlineSmall),
                        const SizedBox(height: 12.0),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('consumer.subtotal'.tr(), style: const TextStyle(fontSize: 13.5, color: AppColors.soil700)),
                            Text('₹${cartState.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                          ],
                        ),
                        const SizedBox(height: 8.0),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('consumer.delivery_fee'.tr(), style: const TextStyle(fontSize: 13.5, color: AppColors.soil700)),
                            Text(
                              cartState.deliveryFee == 0 ? 'consumer.free_delivery'.tr() : '₹${cartState.deliveryFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: cartState.deliveryFee == 0 ? AppColors.primary600 : AppColors.soil800,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20.0),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('consumer.total_payable'.tr(), style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900)),
                            Text('₹${cartState.total.toStringAsFixed(0)}', style: AppTypography.headlineMedium.copyWith(color: AppColors.primary600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  AppButton(
                    label: 'consumer.proceed_to_checkout'.tr(),
                    onPressed: () => context.push(RouteNames.checkout),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20.0),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
    );
  }
}

