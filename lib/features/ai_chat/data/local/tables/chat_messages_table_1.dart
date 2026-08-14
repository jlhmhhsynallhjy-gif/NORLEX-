import 'package:drift/drift.dart';

class ChatMessagesTable extends Table {
  TextColumn get id => text()();
  // FK with CASCADE - critical for orphan prevention
  TextColumn get conversationId => text().customConstraint('REFERENCES conversations_table(id) ON DELETE CASCADE')();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text()();
  TextColumn get modelId => text().nullable()();
  TextColumn get providerId => text().nullable()();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id}
}
