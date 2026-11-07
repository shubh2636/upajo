import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../marketplace/presentation/controllers/cart_controller.dart';
import '../controllers/store_controller.dart';
import '../../domain/models/store_item_model.dart';

class StoreCatalogScreen extends ConsumerStatefulWidget {
  const StoreCatalogScreen({super.key});

  @override
  ConsumerState<StoreCatalogScreen> createState() => _StoreCatalogScreenState();
}

class _StoreCatalogScreenState extends ConsumerState<StoreCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'सभी सामग्री'},
    {'id': 'seed', 'label': 'प्रमाणित बीज (Seeds)'},
    {'id': 'fertilizer', 'label': 'खाद व उर्वरक'},
    {'id': 'bio_nutrient', 'label': 'जैव फफूंदनाशक (Bio)'},
    {'id': 'farm_tool', 'label': 'स्प्रेयर व टूल्स'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeControllerProvider);
    final controller = ref.read(storeControllerProvider.notifier);
    final cartState = ref.watch(cartControllerProvider);
    final items = state.filteredCatalog;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('store.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          // Cart Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_basket_outlined, size: 26.0),
                onPressed: () => context.push(RouteNames.cart),
              ),
              if (cartState.totalItemCount > 0)
                Positioned(
                  right: 8.0,
                  top: 8.0,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: AppColors.primary600,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartState.totalItemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadCatalog(),
        color: AppColors.primary500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Certified Guarantee Hero Banner
              _buildCertifiedBanner(),

              const SizedBox(height: 16.0),

              // 2. Search Field
              TextField(
                controller: _searchController,
                onChanged: (val) => controller.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'बीज, खाद या ब्रांड खोजें (उदा. शरबती, IFFCO)...',
                  hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.soil400),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.soil600),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.soil300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.soil300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.primary500, width: 2.0)),
                ),
              ),

              const SizedBox(height: 14.0),

              // 3. Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = state.selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat['label']!),
                        selected: isSelected,
                        onSelected: (_) => controller.setCategory(cat['id']!),
                        selectedColor: AppColors.primary500,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.soil800,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        side: BorderSide(color: isSelected ? AppColors.primary500 : AppColors.soil300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16.0),

              // 4. Products List
              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary500),
                  ),
                )
              else if (items.isEmpty)
                const EmptyStateView(
                  title: 'कोई उत्पाद नहीं मिला',
                  subtitle: 'आपकी खोज के अनुसार कोई प्रमाणित सामग्री उपलब्ध नहीं है।',
                  icon: Icons.inventory_2_outlined,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildStoreItemCard(item, controller);
                  },
                ),

              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertifiedBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColors.primary500,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 26.0),
          ),
          const SizedBox(width: 12.0),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% सरकारी व ICAR प्रमाणित इनपुट',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.soil900),
                ),
                SizedBox(height: 2.0),
                Text(
                  'राष्ट्रीय बीज निगम (NSC) व IFFCO द्वारा सीधे लैब-परीक्षित शुद्ध बीज व बायो-उर्वरक। घर पर डिलीवरी उपलब्ध।',
                  style: TextStyle(fontSize: 11.5, color: AppColors.soil700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreItemCard(StoreItemModel item, StoreController controller) {
    return AppCard(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with Rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  item.imageUrl ?? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600',
                  width: 90.0,
                  height: 90.0,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90.0,
                    height: 90.0,
                    color: AppColors.soil200,
                    child: const Icon(Icons.spa_rounded, color: AppColors.soil500),
                  ),
                ),
              ),
              const SizedBox(width: 14.0),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.wheat100,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(color: AppColors.wheat300),
                      ),
                      child: Text(
                        item.brand,
                        style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: AppColors.wheat900),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      item.titleHi,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: AppColors.soil900),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'पैकिंग: ${item.packSize}',
                      style: const TextStyle(fontSize: 12.0, color: AppColors.soil600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Description
          Text(
            item.descriptionHi,
            style: const TextStyle(fontSize: 12.0, color: AppColors.soil700, height: 1.35),
          ),
          const SizedBox(height: 12.0),

          // Price & Add to Cart Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${item.price.toInt()}',
                    style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w900, color: AppColors.soil900),
                  ),
                  Text(
                    'स्टॉक: ${item.stockQuantity} उपलब्ध',
                    style: const TextStyle(fontSize: 11.0, color: AppColors.primary700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18.0),
                label: const Text('टोकरी में जोड़ें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                onPressed: () {
                  final added = controller.addItemToCart(ref, item);
                  if (added) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.titleHi} टोकरी में जोड़ा गया!'),
                        backgroundColor: AppColors.primary600,
                        action: SnackBarAction(
                          label: 'टोकरी देखें',
                          textColor: Colors.white,
                          onPressed: () => context.push(RouteNames.cart),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('आपकी टोकरी में दूसरे विक्रेता का सामान है। कृपया पहले वह ऑर्डर पूरा करें।'),
                        backgroundColor: AppColors.wheat800,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

