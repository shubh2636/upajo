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
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
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

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'farmerId': serializer.toJson<String>(farmerId),
      'categoryId': serializer.toJson<String>(categoryId),
      'titleHi': serializer.toJson<String>(titleHi),
      'titleEn': serializer.toJson<String>(titleEn),
      'descriptionHi': serializer.toJson<String>(descriptionHi),
      'pricePerKg': serializer.toJson<double>(pricePerKg),
      'stockKg': serializer.toJson<double>(stockKg),
      'packSizesJson': serializer.toJson<String>(packSizesJson),
      'imagesJson': serializer.toJson<String>(imagesJson),
      'villageOrCity': serializer.toJson<String>(villageOrCity),
      'district': serializer.toJson<String>(district),
      'isOrganic': serializer.toJson<bool>(isOrganic),
      'harvestDate': serializer.toJson<DateTime>(harvestDate),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedProduct copyWith({
    String? id,
    String? farmerId,
    String? categoryId,
    String? titleHi,
    String? titleEn,
    String? descriptionHi,
    double? pricePerKg,
    double? stockKg,
    String? packSizesJson,
    String? imagesJson,
    String? villageOrCity,
    String? district,
    bool? isOrganic,
    DateTime? harvestDate,
    DateTime? cachedAt,
  }) {
    return CachedProduct(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      categoryId: categoryId ?? this.categoryId,
      titleHi: titleHi ?? this.titleHi,
      titleEn: titleEn ?? this.titleEn,
      descriptionHi: descriptionHi ?? this.descriptionHi,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      stockKg: stockKg ?? this.stockKg,
      packSizesJson: packSizesJson ?? this.packSizesJson,
      imagesJson: imagesJson ?? this.imagesJson,
      villageOrCity: villageOrCity ?? this.villageOrCity,
      district: district ?? this.district,
      isOrganic: isOrganic ?? this.isOrganic,
      harvestDate: harvestDate ?? this.harvestDate,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
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

  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (farmerId.present) map['farmer_id'] = Variable<String>(farmerId.value);
    if (categoryId.present) map['category_id'] = Variable<String>(categoryId.value);
    if (titleHi.present) map['title_hi'] = Variable<String>(titleHi.value);
    if (titleEn.present) map['title_en'] = Variable<String>(titleEn.value);
    if (descriptionHi.present) map['description_hi'] = Variable<String>(descriptionHi.value);
    if (pricePerKg.present) map['price_per_kg'] = Variable<double>(pricePerKg.value);
    if (stockKg.present) map['stock_kg'] = Variable<double>(stockKg.value);
    if (packSizesJson.present) map['pack_sizes_json'] = Variable<String>(packSizesJson.value);
    if (imagesJson.present) map['images_json'] = Variable<String>(imagesJson.value);
    if (villageOrCity.present) map['village_or_city'] = Variable<String>(villageOrCity.value);
    if (district.present) map['district'] = Variable<String>(district.value);
    if (isOrganic.present) map['is_organic'] = Variable<bool>(isOrganic.value);
    if (harvestDate.present) map['harvest_date'] = Variable<DateTime>(harvestDate.value);
    if (cachedAt.present) map['cached_at'] = Variable<DateTime>(cachedAt.value);
    return map;
  }
}

class $CachedProductsTable extends CachedProducts
    with TableInfo<$CachedProductsTable, CachedProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProductsTable(this.attachedDatabase, [this._alias]);

  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> farmerId = GeneratedColumn<String>(
      'farmer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> titleHi = GeneratedColumn<String>(
      'title_hi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
      'title_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> descriptionHi = GeneratedColumn<String>(
      'description_hi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<double> pricePerKg = GeneratedColumn<double>(
      'price_per_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  late final GeneratedColumn<double> stockKg = GeneratedColumn<double>(
      'stock_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  late final GeneratedColumn<String> packSizesJson = GeneratedColumn<String>(
      'pack_sizes_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> imagesJson = GeneratedColumn<String>(
      'images_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> villageOrCity = GeneratedColumn<String>(
      'village_or_city', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
      'district', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isOrganic = GeneratedColumn<bool>(
      'is_organic', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(''),
      defaultValue: const Constant(false));
  late final GeneratedColumn<DateTime> harvestDate = GeneratedColumn<DateTime>(
      'harvest_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);

  @override
  List<GeneratedColumn> get $columns => [
        id,
        farmerId,
        categoryId,
        titleHi,
        titleEn,
        descriptionHi,
        pricePerKg,
        stockKg,
        packSizesJson,
        imagesJson,
        villageOrCity,
        district,
        isOrganic,
        harvestDate,
        cachedAt,
      ];

  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => 'cached_products';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  CachedProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProduct(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      farmerId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}farmer_id'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      titleHi: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title_hi'])!,
      titleEn: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title_en'])!,
      descriptionHi: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description_hi'])!,
      pricePerKg: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}price_per_kg'])!,
      stockKg: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}stock_kg'])!,
      packSizesJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pack_sizes_json'])!,
      imagesJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}images_json'])!,
      villageOrCity: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}village_or_city'])!,
      district: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}district'])!,
      isOrganic: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_organic'])!,
      harvestDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}harvest_date'])!,
      cachedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedProductsTable createAlias(String alias) {
    return $CachedProductsTable(attachedDatabase, alias);
  }
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
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
    map['id'] = Variable<int>(id);
    map['action_type'] = Variable<String>(actionType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actionType': serializer.toJson<String>(actionType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }
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

  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (actionType.present) map['action_type'] = Variable<String>(actionType.value);
    if (payloadJson.present) map['payload_json'] = Variable<String>(payloadJson.value);
    if (retryCount.present) map['retry_count'] = Variable<int>(retryCount.value);
    if (createdAt.present) map['created_at'] = Variable<DateTime>(createdAt.value);
    return map;
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
      'action_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);

  @override
  List<GeneratedColumn> get $columns => [id, actionType, payloadJson, retryCount, createdAt];

  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => 'sync_queue_items';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      actionType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}action_type'])!,
      payloadJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      retryCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
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

