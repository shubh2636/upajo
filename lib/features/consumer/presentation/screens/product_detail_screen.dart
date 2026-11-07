import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../marketplace/presentation/controllers/cart_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late int _selectedPackSize;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedPackSize = widget.product.packSizesKg.isNotEmpty
        ? widget.product.packSizesKg.first
        : 10;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final packPrice = p.pricePerKg * _selectedPackSize;
    final totalPrice = packPrice * _quantity;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text(p.titleHi),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('उपज का लिंक कॉपी किया गया')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Banner
            Image.network(
              p.images.isNotEmpty ? p.images.first : '',
              height: 240.0,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 240.0,
                color: AppColors.soil100,
                child: const Center(child: Icon(Icons.grass_rounded, size: 64.0, color: AppColors.soil400)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${p.villageOrCity}, ${p.district} (${p.state})',
                        style: const TextStyle(fontSize: 13.0, color: AppColors.soil600, fontWeight: FontWeight.w600),
                      ),
                      if (p.isOrganic)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(color: AppColors.primary100, borderRadius: BorderRadius.circular(6.0)),
                          child: const Text('100% जैविक (Organic)', style: TextStyle(color: AppColors.primary800, fontSize: 11.0, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6.0),

                  Text(p.titleHi, style: AppTypography.displaySmall),
                  const SizedBox(height: 8.0),

                  Row(
                    children: [
                      Text('₹${p.pricePerKg.toStringAsFixed(0)}', style: AppTypography.displayMedium.copyWith(color: AppColors.primary600)),
                      const Text(' / किलो', style: TextStyle(fontSize: 14.0, color: AppColors.soil600, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('उपलब्ध स्टॉक: ${p.stockKg.toStringAsFixed(0)} किग्रा', style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: AppColors.soil700)),
                    ],
                  ),

                  const SizedBox(height: 20.0),

                  // Pack Sizes Choice
                  Text('बोरी का वजन चुनें (Select Pack Size):', style: AppTypography.headlineSmall),
                  const SizedBox(height: 10.0),

                  Row(
                    children: p.packSizesKg.map((size) {
                      final isSelected = _selectedPackSize == size;
                      final sizePrice = p.pricePerKg * size;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () => setState(() => _selectedPackSize = size),
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary50 : Colors.white,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary500 : AppColors.soil200,
                                  width: isSelected ? 2.0 : 1.2,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                children: [
                                  Text('$size ${'common.kg'.tr()}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.0, color: isSelected ? AppColors.primary600 : AppColors.soil800)),
                                  const SizedBox(height: 4.0),
                                  Text('₹${sizePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.0)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20.0),

                  // Quantity Selector (+ / -)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('बोरियों की संख्या (Bags):', style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 28.0),
                          ),
                          Text('$_quantity', style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900)),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 28.0),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 32.0),

                  // Farmer Details Card
                  AppCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24.0,
                          backgroundColor: AppColors.primary100,
                          child: Icon(Icons.person_rounded, color: AppColors.primary700),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.farmerName ?? 'अन्नदाता किसान', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0)),
                              const Text('सत्यापित खेत मालिक • सीधे खेत से बिक्री', style: TextStyle(fontSize: 11.5, color: AppColors.soil600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: AppColors.primary500),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Description
                  Text('उपज की खासियत:', style: AppTypography.headlineSmall),
                  const SizedBox(height: 6.0),
                  Text(p.descriptionHi, style: AppTypography.bodyMedium),
                  const SizedBox(height: 100.0), // Spacing for bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.soil200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10.0,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('कुल मूल्य (Total)', style: TextStyle(fontSize: 11.0, color: AppColors.soil600)),
                  Text('₹${totalPrice.toStringAsFixed(0)}', style: AppTypography.headlineMedium.copyWith(color: AppColors.primary600)),
                ],
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: AppButton(
                  label: 'consumer.add_to_cart'.tr(),
                  onPressed: () {
                    final added = ref.read(cartControllerProvider.notifier).addToCart(p, _selectedPackSize, _quantity);
                    if (!added) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('आपकी टोकरी में पहले से दूसरे किसान की उपज है।')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${p.titleHi} (${_selectedPackSize}kg x $_quantity) टोकरी में जोड़ा गया!'),
                          backgroundColor: AppColors.primary500,
                        ),
                      );
                      context.push(RouteNames.cart);
                    }
                  },
                  icon: const Icon(Icons.shopping_bag_rounded, size: 20.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

