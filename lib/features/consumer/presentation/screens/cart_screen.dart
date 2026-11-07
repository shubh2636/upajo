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
              child: const Text('खाली करें', style: TextStyle(color: AppColors.clay500, fontWeight: FontWeight.bold)),
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
                    Text('आपकी टोकरी खाली है', style: AppTypography.headlineMedium),
                    const SizedBox(height: 6.0),
                    const Text('खेत से सीधी ताज़ी उपज खरीदने के लिए बाज़ार देखें', style: TextStyle(color: AppColors.soil600)),
                    const SizedBox(height: 24.0),
                    AppButton(
                      label: 'फसलें देखें (Browse Marketplace)',
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
                                  Text('${item.packSizeKg} किग्रा बोरी (₹${item.pricePerPack.toStringAsFixed(0)} / बोरी)', style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),
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
                        Text('प्राप्ति का तरीका (Delivery Mode):', style: AppTypography.headlineSmall),
                        const SizedBox(height: 12.0),

                        RadioListTile<String>(
                          value: 'pickup',
                          groupValue: cartState.deliveryMode,
                          title: const Text('खेत से स्वयं उठाना (Farm Pickup)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                          subtitle: const Text('सीधे किसान के खेत या घर से उठाएं — कोई डिलीवरी शुल्क नहीं (₹0)', style: TextStyle(fontSize: 11.5)),
                          activeColor: AppColors.primary500,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => cartNotifier.setDeliveryMode(val!),
                        ),
                        const Divider(height: 16.0),

                        RadioListTile<String>(
                          value: 'self_delivery',
                          groupValue: cartState.deliveryMode,
                          title: const Text('घर पर डिलीवरी (Doorstep Delivery)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                          subtitle: const Text('किसान या स्थानीय पार्टनर द्वारा आपके पते पर डिलीवरी (₹150 शुल्क)', style: TextStyle(fontSize: 11.5)),
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
                        Text('मूल्य विवरण (Bill Summary)', style: AppTypography.headlineSmall),
                        const SizedBox(height: 12.0),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('उपज का कुल मूल्य (Subtotal)', style: TextStyle(fontSize: 13.5, color: AppColors.soil700)),
                            Text('₹${cartState.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                          ],
                        ),
                        const SizedBox(height: 8.0),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('डिलीवरी शुल्क (Delivery Fee)', style: TextStyle(fontSize: 13.5, color: AppColors.soil700)),
                            Text(
                              cartState.deliveryFee == 0 ? 'मुफ़्त (₹0)' : '₹${cartState.deliveryFee.toStringAsFixed(0)}',
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
                            const Text('कुल देय राशि (Total)', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900)),
                            Text('₹${cartState.total.toStringAsFixed(0)}', style: AppTypography.headlineMedium.copyWith(color: AppColors.primary600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  AppButton(
                    label: 'ऑर्डर करें (Proceed to Checkout)',
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

