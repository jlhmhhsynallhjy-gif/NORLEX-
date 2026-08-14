import 'package:drift/drift.dart';

class ChatAttachmentsTable extends Table {
  TextColumn get id => text()();
  // FK with CASCADE to messages
  TextColumn get messageId => text().customConstraint('REFERENCES chat_messages_table(id) ON DELETE CASCADE')();
  TextColumn get fileId => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get mimeType => text()();
  IntColumn get size => integer().withDefault(const Constant(0))();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id}
}
