import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

/// 阅读 / 听读作答，按 day + kind + 篇 分桶。
class Attempts extends Table {
  IntColumn get day => integer()();
  TextColumn get kind => text()(); // reading | listening
  TextColumn get readingId => text()();
  TextColumn get answersJson => text().withDefault(const Constant('{}'))();
  BoolColumn get submitted => boolean().withDefault(const Constant(false))();
  IntColumn get score => integer().nullable()();
  IntColumn get total => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day, kind, readingId};
}

/// 翻译 / 写作草稿。
class Drafts extends Table {
  IntColumn get day => integer()();
  TextColumn get kind => text()(); // translation | writing
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day, kind};
}

/// 定位标注：绑定训练日、文章、段落与字符区间。
class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get day => integer()();
  TextColumn get target => text()(); // r1 | r2 | writing
  IntColumn get paraIndex => integer()();
  IntColumn get startOffset => integer()();
  IntColumn get endOffset => integer()();
  TextColumn get quote => text()();
  TextColumn get note => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class Notes extends Table {
  IntColumn get day => integer()();
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day};
}

class Reviews extends Table {
  IntColumn get day => integer()();
  TextColumn get wrongReason => text().withDefault(const Constant(''))();
  TextColumn get vocab => text().withDefault(const Constant(''))();
  TextColumn get nextStep => text().withDefault(const Constant(''))();
  TextColumn get scoringJson => text().withDefault(const Constant('[]'))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day};
}

/// 非敏感设置；任何密钥都不进这里。
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 端侧生成并通过质检的题包；payload 与 assets/days/day-XX.json 同构。
class GeneratedDays extends Table {
  IntColumn get day => integer()();
  TextColumn get date => text()();
  TextColumn get theme => text()();
  TextColumn get payloadJson => text()();
  TextColumn get model => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day};
}

@DriftDatabase(tables: [Attempts, Drafts, Annotations, Notes, Reviews, Settings, GeneratedDays])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'cet6'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(generatedDays);
        },
      );
}
