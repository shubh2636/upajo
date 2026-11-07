// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class CachedProduct extends DataClass implements Insertable<CachedProduct> {
  final String id;
  final String farmerId;
  final String categoryId;
  final String titleHi;
  final String titleEn;
  final String descriptionHi;
  final double pricePerKg;
  final double stockKg;
  final String packSizesJson;
  final String imagesJson;
  final String villageOrCity;
  final String district;
  final bool isOrganic;
  final DateTime harvestDate;
  final DateTime cachedAt;

  const CachedProduct({
    required this.id,
    required this.farmerId,
    required this.categoryId,
    required this.titleHi,
    required this.titleEn,
    required this.descriptionHi,
    required this.pricePerKg,
    required this.stockKg,
    required this.packSizesJson,
    required this.imagesJson,
    required this.villageOrCity,
    required this.district,
    required this.isOrganic,
    required this.harvestDate,
    required this.cachedAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['farmer_id'] = Variable<String>(farmerId);
    map['category_id'] = Variable<String>(categoryId);
    map['title_hi'] = Variable<String>(titleHi);
    map['title_en'] = Variable<String>(titleEn);
    map['description_hi'] = Variable<String>(descriptionHi);
    map['price_per_kg'] = Variable<double>(pricePerKg);
    map['stock_kg'] = Variable<double>(stockKg);
    map['pack_sizes_json'] = Variable<String>(packSizesJson);
    map['images_json'] = Variable<String>(imagesJson);
    map['village_or_city'] = Variable<String>(villageOrCity);
    map['district'] = Variable<String>(district);
    map['is_organic'] = Variable<bool>(isOrganic);
    map['harvest_date'] = Variable<DateTime>(harvestDate);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedProductsCompanion toCompanion(bool nullToAbsent) {
    return CachedProductsCompanion(
      id: Value(id),
      farmerId: Value(farmerId),
      categoryId: Value(categoryId),
      titleHi: Value(titleHi),
      titleEn: Value(titleEn),
      descriptionHi: Value(descriptionHi),
      pricePerKg: Value(pricePerKg),
      stockKg: Value(stockKg),
      packSizesJson: Value(packSizesJson),
      imagesJson: Value(imagesJson),
      villageOrCity: Value(villageOrCity),
      district: Value(district),
      isOrganic: Value(isOrganic),
      harvestDate: Value(harvestDate),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedProduct.fromJson(Map<String, dynamic> json) {
    return CachedProduct(
      id: json['id'] as String,
      farmerId: json['farmerId'] as String,
      categoryId: json['categoryId'] as String,
      titleHi: json['titleHi'] as String,
      titleEn: json['titleEn'] as String,
      descriptionHi: json['descriptionHi'] as String,
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      stockKg: (json['stockKg'] as num).toDouble(),
      packSizesJson: json['packSizesJson'] as String,
      imagesJson: json['imagesJson'] as String,
      villageOrCity: json['villageOrCity'] as String,
      district: json['district'] as String,
      isOrganic: json['isOrganic'] as bool,
      harvestDate: DateTime.parse(json['harvestDate'] as String),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'farmerId': farmerId,
        'categoryId': categoryId,
        'titleHi': titleHi,
        'titleEn': titleEn,
        'descriptionHi': descriptionHi,
        'pricePerKg': pricePerKg,
        'stockKg': stockKg,
        'packSizesJson': packSizesJson,
        'imagesJson': imagesJson,
        'villageOrCity': villageOrCity,
        'district': district,
        'isOrganic': isOrganic,
        'harvestDate': harvestDate.toIso8601String(),
        'cachedAt': cachedAt.toIso8601String(),
      };
}

class CachedProductsCompanion extends UpdateCompanion<CachedProduct> {
  final Value<String> id;
  final Value<String> farmerId;
  final Value<String> categoryId;
  final Value<String> titleHi;
  final Value<String> titleEn;
  final Value<String> descriptionHi;
  final Value<double> pricePerKg;
  final Value<double> stockKg;
  final Value<String> packSizesJson;
  final Value<String> imagesJson;
  final Value<String> villageOrCity;
  final Value<String> district;
  final Value<bool> isOrganic;
  final Value<DateTime> harvestDate;
  final Value<DateTime> cachedAt;

  const CachedProductsCompanion({
    this.id = const Value.absent(),
    this.farmerId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.titleHi = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.descriptionHi = const Value.absent(),
    this.pricePerKg = const Value.absent(),
    this.stockKg = const Value.absent(),
    this.packSizesJson = const Value.absent(),
    this.imagesJson = const Value.absent(),
    this.villageOrCity = const Value.absent(),
    this.district = const Value.absent(),
    this.isOrganic = const Value.absent(),
    this.harvestDate = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });

  CachedProductsCompanion.insert({
    required String id,
    required String farmerId,
    required String categoryId,
    required String titleHi,
    required String titleEn,
    required String descriptionHi,
    required double pricePerKg,
    required double stockKg,
    required String packSizesJson,
    required String imagesJson,
    required String villageOrCity,
    required String district,
    this.isOrganic = const Value.absent(),
    required DateTime harvestDate,
    this.cachedAt = const Value.absent(),
  })  : id = Value(id),
        farmerId = Value(farmerId),
        categoryId = Value(categoryId),
        titleHi = Value(titleHi),
        titleEn = Value(titleEn),
        descriptionHi = Value(descriptionHi),
        pricePerKg = Value(pricePerKg),
        stockKg = Value(stockKg),
        packSizesJson = Value(packSizesJson),
        imagesJson = Value(imagesJson),
        villageOrCity = Value(villageOrCity),
        district = Value(district),
        harvestDate = Value(harvestDate);
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final int id;
  final String actionType;
  final String payloadJson;
  final int retryCount;
  final DateTime createdAt;

  const SyncQueueItem({
    required this.id,
    required this.actionType,
    required this.payloadJson,
    required this.retryCount,
    required this.createdAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action_type'] = Variable<String>(actionType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      id: Value(id),
      actionType: Value(actionType),
      payloadJson: Value(payloadJson),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as int,
      actionType: json['actionType'] as String,
      payloadJson: json['payloadJson'] as String,
      retryCount: json['retryCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'actionType': actionType,
        'payloadJson': payloadJson,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
      };
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<int> id;
  final Value<String> actionType;
  final Value<String> payloadJson;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;

  const SyncQueueItemsCompanion({
    this.id = const Value.absent(),
    this.actionType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });

  SyncQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required String actionType,
    required String payloadJson,
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : actionType = Value(actionType),
        payloadJson = Value(payloadJson);
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $CachedProductsTable cachedProducts = $CachedProductsTable(this);
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cachedProducts, syncQueueItems];
}

class $CachedProductsTable extends CachedProducts
    with TableInfo<$CachedProductsTable, CachedProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProductsTable(this.attachedDatabase, [this._alias]);

  @override
  String get actualTableName => _alias ?? 'cached_products';

  @override
  CachedProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    return CachedProduct.fromJson(data);
  }

  @override
  $CachedProductsTable createAlias(String alias) {
    return $CachedProductsTable(attachedDatabase, alias);
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);

  @override
  String get actualTableName => _alias ?? 'sync_queue_items';

  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    return SyncQueueItem.fromJson(data);
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}
