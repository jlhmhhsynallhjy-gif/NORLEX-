import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/repositories/project_repository.dart';
import '../../features/ai_chat/data/local/chat_local_data_source.dart';
import '../../features/ai_chat/data/repositories/conversation_repository_impl.dart';
import '../../features/ai_chat/data/repositories/chat_repository_impl.dart';
import '../../features/ai_chat/domain/repositories/conversation_repository.dart';
import '../../features/ai_chat/domain/repositories/chat_repository.dart';
import '../../core/ai/ai_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl();
});

final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  return ChatLocalDataSource(ref.read(databaseProvider));
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(ref.read(chatLocalDataSourceProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    ref.read(chatLocalDataSourceProvider),
    ref.read(aiGatewayProvider),
  );
});
