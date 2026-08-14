import 'package:drift/drift.dart';

class ConversationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id}
}
