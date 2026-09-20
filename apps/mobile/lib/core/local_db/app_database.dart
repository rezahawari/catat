import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Tables definition
class LocalSpaces extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'personal' or 'business'
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'cash', 'bank', 'ewallet'
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get icon => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get note => text().nullable()();
  TextColumn get transactionDate => text()(); // YYYY-MM-DD
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringRule => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))(); // 'pending', 'synced'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'catat_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [LocalSpaces, LocalAccounts, LocalCategories, LocalTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Stream transactions for space
  Stream<List<LocalTransaction>> watchTransactions(String spaceId) {
    return (select(localTransactions)
          ..where((t) => t.spaceId.equals(spaceId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  // Get pending transactions for sync
  Future<List<LocalTransaction>> getPendingTransactions() {
    return (select(localTransactions)..where((t) => t.syncStatus.equals('pending'))).get();
  }

  // Insert or update transaction
  Future<int> upsertTransaction(LocalTransactionsCompanion entry) {
    return into(localTransactions).insertOnConflictUpdate(entry);
  }
}
