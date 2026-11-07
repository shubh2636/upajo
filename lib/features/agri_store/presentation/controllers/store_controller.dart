import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/store_item_model.dart';
import '../../domain/repositories/store_repository.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../marketplace/presentation/controllers/cart_controller.dart';

class StoreState {
  final List<StoreItemModel> items;
  final bool isLoading;
  final String? error;
  final String selectedCategory; // 'all', 'seed', 'fertilizer', 'bio_nutrient', 'farm_tool'
  final String searchQuery;

  const StoreState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'all',
    this.searchQuery = '',
  });

  StoreState copyWith({
    List<StoreItemModel>? items,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return StoreState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<StoreItemModel> get filteredItems {
    return items.where((item) {
      final matchesCategory = selectedCategory == 'all' || item.itemType == selectedCategory;
      final matchesQuery = searchQuery.isEmpty ||
          item.titleHi.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.titleEn.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.brand.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<StoreItemModel> get filteredCatalog => filteredItems;
}

class StoreController extends StateNotifier<StoreState> {
  final StoreRepository _repository;

  StoreController(this._repository) : super(const StoreState()) {
    loadStoreCatalog();
  }

  Future<void> loadCatalog() => loadStoreCatalog();

  Future<void> loadStoreCatalog() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repository.getStoreCatalog();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Converts Store item into ProductModel and adds to the shared cart
  bool addItemToCart(WidgetRef ref, StoreItemModel item) {
    final product = ProductModel(
      id: item.id,
      farmerId: 'upajo_certified_store',
      categoryId: item.itemType,
      titleHi: item.titleHi,
      titleEn: item.titleEn,
      descriptionHi: item.descriptionHi,
      descriptionEn: item.descriptionEn,
      images: [item.imageUrl ?? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600'],
      pricePerKg: item.price,
      stockKg: item.stockQuantity.toDouble(),
      packSizesKg: const [1],
      harvestDate: DateTime.now(),
      shelfLifeDays: 365,
      deliveryModes: const ['delivery', 'pickup'],
      isOrganic: item.itemType == 'bio_nutrient' || item.brand.contains('Organic'),
      isActive: true,
      villageOrCity: 'केंद्रीय कृषि बीज निगम',
      district: 'सीहोर',
      state: 'मध्य प्रदेश',
      pinCode: '466001',
      createdAt: DateTime.now(),
      farmerName: '${item.brand} (सरकारी प्रमाणित)',
      farmerPhone: '18001801551',
      farmerVerified: true,
    );

    return ref.read(cartControllerProvider.notifier).addToCart(product, 1, 1);
  }
}

final storeControllerProvider =
    StateNotifierProvider<StoreController, StoreState>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return StoreController(repo);
});
