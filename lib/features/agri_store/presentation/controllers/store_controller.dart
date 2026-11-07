import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/store_item_model.dart';
import '../../domain/repositories/store_repository.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../../marketplace/presentation/controllers/cart_controller.dart';
import '../../../marketplace/domain/models/product_model.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepositoryImpl();
});

class StoreState {
  final bool isLoading;
  final List<StoreItemModel> catalog;
  final String selectedCategory; // 'all', 'seed', 'fertilizer', 'bio_nutrient', 'farm_tool'
  final String searchQuery;
  final String? errorMessage;

  const StoreState({
    this.isLoading = false,
    this.catalog = const [],
    this.selectedCategory = 'all',
    this.searchQuery = '',
    this.errorMessage,
  });

  List<StoreItemModel> get filteredCatalog {
    return catalog.where((item) {
      final matchesCat = selectedCategory == 'all' || item.itemType == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          item.titleHi.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.brand.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  StoreState copyWith({
    bool? isLoading,
    List<StoreItemModel>? catalog,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
  }) {
    return StoreState(
      isLoading: isLoading ?? this.isLoading,
      catalog: catalog ?? this.catalog,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

class StoreController extends StateNotifier<StoreState> {
  final StoreRepository _repository;

  StoreController(this._repository) : super(const StoreState()) {
    loadCatalog();
  }

  Future<void> loadCatalog({String? itemType}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cat = itemType ?? state.selectedCategory;
      final items = await _repository.getStoreCatalog(itemType: cat);
      state = state.copyWith(catalog: items, selectedCategory: cat, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'भंडार सामग्री लोड नहीं हो सकी: $e');
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
      farmerName: '${item.brand} (सरकारी प्रमाणित)',
      farmerPhone: '18001801551',
      nameHi: item.titleHi,
      nameEn: item.titleEn,
      category: item.itemType,
      pricePerKg: item.price,
      totalStockKg: item.stockQuantity.toDouble(),
      harvestDate: DateTime.now(),
      deliveryMode: 'self_delivery',
      isOrganic: item.itemType == 'bio_nutrient' || item.brand.contains('Organic'),
      images: [item.imageUrl ?? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600'],
      villageOrCity: 'केंद्रीय कृषि बीज निगम',
      district: 'सीहोर',
      state: 'मध्य प्रदेश',
      packSizes: const [1], // 1 pack unit
    );

    return ref.read(cartControllerProvider.notifier).addToCart(product, 1, 1);
  }
}

final storeControllerProvider =
    StateNotifierProvider<StoreController, StoreState>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return StoreController(repo);
});
