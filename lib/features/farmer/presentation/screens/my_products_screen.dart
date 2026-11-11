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
  String? _updatingId;

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

  Future<void> _toggleProductStatus(ProductModel product) async {
    setState(() => _updatingId = product.id);
    final repo = ref.read(marketplaceRepositoryProvider);
    try {
      final updated = product.copyWith(isActive: !product.isActive);
      await repo.updateProduct(updated);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isActive
                  ? 'farmer.product_resumed'.tr()
                  : 'farmer.product_paused'.tr(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('farmer.delete_produce_title'.tr()),
        content: Text('farmer.delete_produce_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.clay500),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updatingId = product.id);
    final repo = ref.read(marketplaceRepositoryProvider);
    try {
      await repo.deleteProduct(product.id);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('farmer.produce_deleted_success'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingId = null);
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
          : _products.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.grass_rounded, size: 56.0, color: AppColors.soil400),
                        const SizedBox(height: 14.0),
                        Text('common.empty'.tr(), style: AppTypography.headlineSmall),
                        const SizedBox(height: 6.0),
                        Text('farmer.add_product'.tr(), style: const TextStyle(color: AppColors.soil600)),
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
                    final isUpdating = _updatingId == p.id;

                    return AppCard(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                          child: Text(
                                            p.titleHi,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                          decoration: BoxDecoration(
                                            color: p.isActive ? AppColors.primary100 : AppColors.soil200,
                                            borderRadius: BorderRadius.circular(6.0),
                                          ),
                                          child: Text(
                                            p.isActive ? 'common.active'.tr() : 'common.pending'.tr(),
                                            style: TextStyle(
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.bold,
                                              color: p.isActive ? AppColors.primary800 : AppColors.soil700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text('₹${p.pricePerKg.toStringAsFixed(0)} / ${'common.kg'.tr()}', style: AppTypography.priceMedium),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      '${'farmer.active_stock'.tr()}: ${p.stockKg} ${'common.kg'.tr()} • ${'farmer.pack_sizes'.tr()}: ${p.packSizesKg.join(', ')} ${'common.kg'.tr()}',
                                      style: const TextStyle(fontSize: 12.0, color: AppColors.soil600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: isUpdating ? null : () => _toggleProductStatus(p),
                                icon: Icon(
                                  p.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                  size: 18.0,
                                  color: p.isActive ? AppColors.wheat700 : AppColors.primary600,
                                ),
                                label: Text(
                                  p.isActive ? 'farmer.pause_action'.tr() : 'farmer.resume_action'.tr(),
                                  style: TextStyle(
                                    color: p.isActive ? AppColors.wheat700 : AppColors.primary600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              TextButton.icon(
                                onPressed: isUpdating ? null : () => _deleteProduct(p),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18.0, color: AppColors.clay500),
                                label: Text(
                                  'common.delete'.tr(),
                                  style: const TextStyle(color: AppColors.clay500, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
