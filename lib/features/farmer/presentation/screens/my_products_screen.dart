import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';

class MyProductsScreen extends ConsumerStatefulWidget {
  const MyProductsScreen({super.key});

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user != null) {
      final repo = ref.read(marketplaceRepositoryProvider);
      try {
        final list = await repo.getFarmerProducts(user.id);
        if (mounted) setState(() { _products = list; _isLoading = false; });
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('farmer.my_products'.tr()),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary500),
            onPressed: () async {
              await context.push(RouteNames.addProduct);
              _loadProducts();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.grass_rounded, size: 56.0, color: AppColors.soil400),
                        const SizedBox(height: 14.0),
                        Text('कोई उपज नहीं जोड़ी गई है', style: AppTypography.headlineSmall),
                        const SizedBox(height: 6.0),
                        const Text('अपनी पहली फसल जोड़ें और सीधे ग्राहकों को बेचें', style: TextStyle(color: AppColors.soil600)),
                        const SizedBox(height: 20.0),
                        AppButton(
                          label: 'farmer.add_product'.tr(),
                          onPressed: () async {
                            await context.push(RouteNames.addProduct);
                            _loadProducts();
                          },
                          width: 220.0,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14.0),
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    return AppCard(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              p.images.isNotEmpty ? p.images.first : '',
                              width: 80.0,
                              height: 80.0,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80.0,
                                height: 80.0,
                                color: AppColors.soil100,
                                child: const Icon(Icons.grass_rounded, color: AppColors.soil400),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(p.titleHi, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                                    ),
                                    if (p.isOrganic)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                        decoration: BoxDecoration(color: AppColors.primary100, borderRadius: BorderRadius.circular(4.0)),
                                        child: const Text('जैविक', style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: AppColors.primary800)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Text('₹${p.pricePerKg.toStringAsFixed(0)} / किलो', style: AppTypography.priceMedium),
                                const SizedBox(height: 4.0),
                                Text('स्टॉक: ${p.stockKg} किग्रा • पैक: ${p.packSizesKg.join(', ')} kg', style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
