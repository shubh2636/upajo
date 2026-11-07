import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Cached Products table for instant offline catalog viewing
class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get farmerId => text()();
  TextColumn get categoryId => text()();
  TextColumn get titleHi => text()();
  TextColumn get titleEn => text()();
  TextColumn get descriptionHi => text()();
  RealColumn get pricePerKg => real()();
  RealColumn get stockKg => real()();
  TextColumn get packSizesJson => text()();
  TextColumn get imagesJson => text()();
  TextColumn get villageOrCity => text()();
  TextColumn get district => text()();
  BoolColumn get isOrganic => boolean().withDefault(const Constant(false))();
  DateTimeColumn get harvestDate => dateTime()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline Action Queue table to sync changes when network restores
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()(); // 'create_order', 'update_order_status', 'add_product'
  TextColumn get payloadJson => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [CachedProducts, SyncQueueItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Insert or update cached products
  Future<void> cacheProducts(List<CachedProductsCompanion> products) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedProducts, products);
    });
  }

  // Get cached products stream
  Stream<List<CachedProduct>> watchAllCachedProducts() {
    return select(cachedProducts).watch();
  }

  // Queue offline action
  Future<int> enqueueAction(String actionType, String payloadJson) {
    return into(syncQueueItems).insert(
      SyncQueueItemsCompanion.insert(
        actionType: actionType,
        payloadJson: payloadJson,
      ),
    );
  }

  // Get pending queue items
  Future<List<SyncQueueItem>> getPendingQueue() {
    return (select(syncQueueItems)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  // Remove processed item
  Future<int> removeQueueItem(int id) {
    return (delete(syncQueueItems)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'upajo_offline_v1.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
