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
        // Create indexes for performance - FIX: was previously in customConstraints which is invalid
        await customStatement('CREATE INDEX IF NOT EXISTS idx_conversations_user_updated ON conversations_table(user_id, updated_at DESC)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_conversations_project ON conversations_table(project_id)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON chat_messages_table(conversation_id, created_at ASC)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_attachments_message ON chat_attachments_table(message_id)');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Safe migration v1 -> v2: preserve existing data, only create new tables
        if (from < 2) {
          await m.createTable(conversationsTable);
          await m.createTable(chatMessagesTable);
          await m.createTable(chatAttachmentsTable);
          await customStatement('CREATE INDEX IF NOT EXISTS idx_conversations_user_updated ON conversations_table(user_id, updated_at DESC)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_conversations_project ON conversations_table(project_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON chat_messages_table(conversation_id, created_at ASC)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_attachments_message ON chat_attachments_table(message_id)');
        }
      },
      beforeOpen: (details) async {
        // Enable FK enforcement - critical for CASCADE to work on SQLite
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Transaction helper for atomic operations
  Future<void> runInTransaction(Future Function() action) {
    return transaction(action);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'norlex.db'));
    return NativeDatabase.createInBackground(file);
  });
}
