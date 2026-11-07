import '../models/store_item_model.dart';

abstract class StoreRepository {
  /// Fetches items from the certified input store
  Future<List<StoreItemModel>> getStoreCatalog({String? itemType});

  /// Fetches single store item details
  Future<StoreItemModel?> getStoreItemById(String id);
}

