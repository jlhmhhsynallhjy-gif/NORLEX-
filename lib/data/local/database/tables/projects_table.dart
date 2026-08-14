import 'package:drift/drift.dart';

class ProjectsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('general'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get aiContext => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
