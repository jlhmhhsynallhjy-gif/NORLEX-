import 'package:drift/drift.dart';

class ConversationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id}
  
  @override
  List<Set<Column>> get uniqueKeys => [];

  @override
  List<String> get customConstraints => [
    'CREATE INDEX IF NOT EXISTS idx_conversations_user_updated ON conversations_table (user_id, updated_at DESC)',
    'CREATE INDEX IF NOT EXISTS idx_conversations_project ON conversations_table (project_id)',
  ];
}
