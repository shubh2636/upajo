import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../data/repositories/marketplace_repository_impl.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepositoryImpl();
});

class MarketplaceState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedCategory;
  final String? selectedDistrict;
  final bool isOrganicOnly;
  final String searchQuery;

  const MarketplaceState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory,
    this.selectedDistrict,
    this.isOrganicOnly = false,
    this.searchQuery = '',
  });

  MarketplaceState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    String? selectedDistrict,
    bool? isOrganicOnly,
    String? searchQuery,
  }) {
    return MarketplaceState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      isOrganicOnly: isOrganicOnly ?? this.isOrganicOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MarketplaceController extends StateNotifier<MarketplaceState> {
  final MarketplaceRepository _repository;

  MarketplaceController(this._repository) : super(const MarketplaceState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getProducts(
        categoryId: state.selectedCategory,
        district: state.selectedDistrict,
        isOrganic: state.isOrganicOnly ? true : null,
        query: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(products: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setCategory(String? categoryId) {
    if (state.selectedCategory == categoryId) {
      state = state.copyWith(selectedCategory: null);
    } else {
      state = state.copyWith(selectedCategory: categoryId);
    }
    loadProducts();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadProducts();
  }

  void toggleOrganicOnly() {
    state = state.copyWith(isOrganicOnly: !state.isOrganicOnly);
    loadProducts();
  }

  void setDistrict(String? district) {
    state = state.copyWith(selectedDistrict: district);
    loadProducts();
  }
}

final marketplaceControllerProvider =
    StateNotifierProvider<MarketplaceController, MarketplaceState>((ref) {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return MarketplaceController(repo);
});

