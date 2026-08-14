import 'package:drift/drift.dart';

class ChatAttachmentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get messageId => text()();
  TextColumn get fileId => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get mimeType => text()();
  IntColumn get size => integer()();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id}
}
