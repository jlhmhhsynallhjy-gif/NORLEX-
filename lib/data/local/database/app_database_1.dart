import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables/projects_table.dart';
import 'tables/files_table.dart';
import 'tables/tasks_table.dart';
import '../../../features/ai_chat/data/local/tables/conversations_table.dart';
import '../../../features/ai_chat/data/local/tables/chat_messages_table.dart';
import '../../../features/ai_chat/data/local/tables/chat_attachments_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  ProjectsTable,
  FilesTable,
  TasksTable,
  ConversationsTable,
  ChatMessagesTable,
  ChatAttachmentsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(conversationsTable);
          await m.createTable(chatMessagesTable);
          await m.createTable(chatAttachmentsTable);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'norlex.db'));
    return NativeDatabase.createInBackground(file);
  });
}
