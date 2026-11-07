class StoreItemModel {
  final String id;
  final String titleHi;
  final String titleEn;
  final String itemType; // 'seed', 'fertilizer', 'bio_nutrient', 'farm_tool'
  final String brand;
  final double price;
  final String packSize;
  final int stockQuantity;
  final String? imageUrl;
  final String descriptionHi;
  final String descriptionEn;
  final bool isActive;

  const StoreItemModel({
    required this.id,
    required this.titleHi,
    required this.titleEn,
    required this.itemType,
    required this.brand,
    required this.price,
    required this.packSize,
    required this.stockQuantity,
    this.imageUrl,
    required this.descriptionHi,
    required this.descriptionEn,
    this.isActive = true,
  });

  factory StoreItemModel.fromJson(Map<String, dynamic> json) {
    return StoreItemModel(
      id: json['id'] as String? ?? '',
      titleHi: json['title_hi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      itemType: json['item_type'] as String? ?? 'seed',
      brand: json['brand'] as String? ?? 'NSC',
      price: (json['price'] as num?)?.toDouble() ?? 100.0,
      packSize: json['pack_size'] as String? ?? '1 Pack',
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 50,
      imageUrl: json['image_url'] as String?,
      descriptionHi: json['description_hi'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_hi': titleHi,
      'title_en': titleEn,
      'item_type': itemType,
      'brand': brand,
      'price': price,
      'pack_size': packSize,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      'description_hi': descriptionHi,
      'description_en': descriptionEn,
      'is_active': isActive,
    };
  }
}
