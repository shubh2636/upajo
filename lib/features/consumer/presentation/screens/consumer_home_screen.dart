import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';
import '../../../marketplace/presentation/controllers/cart_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ConsumerHomeScreen extends ConsumerStatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  ConsumerState<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends ConsumerState<ConsumerHomeScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'name': 'सभी', 'id': ''},
    {'name': 'गेहूं व अनाज', 'id': 'grains'},
    {'name': 'दालें', 'id': 'pulses'},
    {'name': 'ताज़ी सब्जियां', 'id': 'vegetables'},
    {'name': 'देसी मसाले', 'id': 'spices'},
    {'name': 'बाग के फल', 'id': 'fruits'},
    {'name': 'शुद्ध तेल', 'id': 'oilseeds'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketState = ref.watch(marketplaceControllerProvider);
    final cartState = ref.watch(cartControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.userProfile;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco_rounded, color: AppColors.primary500, size: 20.0),
                const SizedBox(width: 6.0),
                Text('app_name'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18.0)),
              ],
            ),
            Text(
              user?.villageOrCity != null ? 'स्थान: ${user!.villageOrCity}, ${user.district}' : 'खेत से सीधी ताज़ी उपज',
              style: const TextStyle(fontSize: 11.5, color: AppColors.soil600),
            ),
          ],
        ),
        actions: [
          // Cart Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 26.0),
                onPressed: () => context.push(RouteNames.cart),
              ),
              if (cartState.items.isNotEmpty)
                Positioned(
                  right: 8.0,
                  top: 8.0,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: AppColors.clay500,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18.0, minHeight: 18.0),
                    child: Text(
                      '${cartState.totalItemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push(RouteNames.consumerOrders),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(marketplaceControllerProvider.notifier).loadProducts(),
        color: AppColors.primary500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Voice Input Bar
              AppTextField(
                controller: _searchController,
                hintText: 'फसल, दाल, फल या किसान खोजें...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.soil400),
                onVoiceInputPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('बोलकर खोजें (Listening...)')),
                  );
                },
                onChanged: (val) {
                  ref.read(marketplaceControllerProvider.notifier).setSearchQuery(val.trim());
                },
              ),
              const SizedBox(height: 14.0),

              // Category & Organic Chips Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: marketState.isOrganicOnly,
                      avatar: const Icon(Icons.eco_outlined, size: 16.0),
                      label: const Text('केवल जैविक (Organic)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0)),
                      selectedColor: AppColors.primary100,
                      checkmarkColor: AppColors.primary700,
                      onSelected: (_) {
                        ref.read(marketplaceControllerProvider.notifier).toggleOrganicOnly();
                      },
                    ),
                    const SizedBox(width: 8.0),
                    ..._categories.map((cat) {
                      final isSelected = (marketState.selectedCategory ?? '') == cat['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text(cat['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.0)),
                          selectedColor: AppColors.primary500,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.soil800),
                          onSelected: (_) {
                            ref.read(marketplaceControllerProvider.notifier).setCategory(cat['id']!.isEmpty ? null : cat['id']);
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // Section Heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('सीधे खेत से ताज़ा फसलें', style: AppTypography.headlineSmall),
                  Text('${marketState.products.length} उपलब्ध', style: const TextStyle(fontSize: 12.0, color: AppColors.soil600, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12.0),

              if (marketState.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (marketState.products.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.eco_rounded, size: 54.0, color: AppColors.soil400),
                        const SizedBox(height: 12.0),
                        Text('कोई फसल नहीं मिली', style: AppTypography.headlineSmall),
                        const SizedBox(height: 6.0),
                        const Text('कृपया अन्य श्रेणी या फिल्टर चुनकर प्रयास करें', style: TextStyle(fontSize: 12.5, color: AppColors.soil600)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: marketState.products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14.0),
                  itemBuilder: (context, index) {
                    final product = marketState.products[index];
                    return _ProductCard(
                      product: product,
                      onTap: () {
                        context.push(RouteNames.productDetail.replaceFirst(':id', product.id), extra: product);
                      },
                      onQuickAdd: () {
                        final defaultPack = product.packSizesKg.first;
                        final added = ref.read(cartControllerProvider.notifier).addToCart(product, defaultPack, 1);
                        if (!added) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('आपकी टोकरी में पहले से दूसरे किसान की उपज है। एक समय में एक ही किसान से ऑर्डर करें।')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.titleHi} (${defaultPack}kg) टोकरी में जोड़ा गया!'),
                              backgroundColor: AppColors.primary500,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.push(RouteNames.cart);
          if (index == 2) context.push(RouteNames.consumerOrders);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'बाज़ार'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'टोकरी'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'मेरे ऑर्डर'),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                child: Image.network(
                  product.images.isNotEmpty ? product.images.first : '',
                  height: 160.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160.0,
                    color: AppColors.soil100,
                    child: const Center(child: Icon(Icons.grass_rounded, size: 48.0, color: AppColors.soil400)),
                  ),
                ),
              ),
              if (product.isOrganic)
                Positioned(
                  top: 10.0,
                  left: 10.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(color: AppColors.primary500, borderRadius: BorderRadius.circular(8.0)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco_rounded, size: 14.0, color: Colors.white),
                        SizedBox(width: 4.0),
                        Text('100% जैविक', style: TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 10.0,
                right: 10.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6.0)),
                  child: Text(
                    'स्टॉक: ${product.stockKg.toStringAsFixed(0)} kg',
                    style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.villageOrCity}, ${product.district}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.soil600, fontWeight: FontWeight.w600),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 14.0, color: AppColors.primary500),
                        SizedBox(width: 3.0),
                        Text('सत्यापित किसान', style: TextStyle(fontSize: 11.0, color: AppColors.primary600, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),

                Text(product.titleHi, style: AppTypography.headlineSmall),
                const SizedBox(height: 6.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${product.pricePerKg.toStringAsFixed(0)} / किलो', style: AppTypography.priceLarge),
                    ElevatedButton.icon(
                      onPressed: onQuickAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.soil100,
                        foregroundColor: AppColors.soil900,
                        elevation: 0,
                        minimumSize: const Size(110.0, 42.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16.0),
                      label: const Text('डालें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                    ),
                  ],
                ),

                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 6.0,
                  children: product.packSizesKg.map((size) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(color: AppColors.wheat100, borderRadius: BorderRadius.circular(4.0)),
                      child: Text(
                        '${size}kg (₹${(product.pricePerKg * size).toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.wheat900),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
