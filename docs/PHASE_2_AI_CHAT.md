# NORLEX PHASE 2 - AI Chat Feature - Technical Documentation

## 1. Architecture Flow

```
Presentation (ChatScreen, ConversationsListScreen, Widgets)
   |
   |  Riverpod Provider: chatControllerProvider (StateNotifier)
   v
Application Layer (UseCases: CreateConversation, GetConversations, SendMessage)
   |
   v
Domain Layer (Entities: Conversation, ChatMessage, ChatAttachment, ChatContext, ModelConfig)
   |  Interfaces: ConversationRepository, ChatRepository
   v
Data Layer (Repository Impl: ConversationRepositoryImpl, ChatRepositoryImpl)
   |  -> ChatLocalDataSource (Drift)
   |  -> AiGateway (Abstraction)
   v
Infrastructure (AppDatabase - Drift, DioClient, SecureStorage)
```

### Dependency Rule
```
UI -> Controller -> UseCase -> Repository Interface -> Repository Impl -> DataSource -> DB/Gateway
- UI never imports Drift, Dio, AppDatabase directly - VERIFIED
- Domain never imports Flutter - VERIFIED
- Data layer depends on Domain, not vice versa
```

## 2. Database Schema

### Version 2 (Migration v1 -> v2 safe, preserves data)

#### conversations_table
- id TEXT PRIMARY KEY
- userId TEXT NOT NULL
- projectId TEXT NULLABLE
- title TEXT (1-500 chars)
- createdAt DATETIME NOT NULL
- updatedAt DATETIME NOT NULL
- archived BOOLEAN DEFAULT false
- metadata TEXT DEFAULT '{}' (JSON)
- Indexes: (user_id, updated_at DESC), (project_id)
- No orphan risk: ON DELETE CASCADE from messages

#### chat_messages_table
- id TEXT PRIMARY KEY
- conversationId TEXT FK -> conversations_table(id) ON DELETE CASCADE
- role TEXT (user, assistant, system, tool)
- content TEXT
- createdAt DATETIME
- status TEXT (sending, streaming, completed, failed, cancelled)
- modelId TEXT NULLABLE
- providerId TEXT NULLABLE
- metadata TEXT DEFAULT '{}' (error code, partial_content_preserved, etc)
- Index: (conversation_id, created_at ASC)
- FK enforcement: PRAGMA foreign_keys = ON in beforeOpen

#### chat_attachments_table
- id TEXT PRIMARY KEY
- messageId TEXT FK -> chat_messages_table(id) ON DELETE CASCADE
- fileId TEXT
- type TEXT (image, document, audio, other)
- name TEXT
- mimeType TEXT
- size INTEGER DEFAULT 0
- metadata TEXT DEFAULT '{}'
- Index: (message_id)

### Deletion Behavior
- Delete Conversation -> CASCADE deletes Messages -> CASCADE deletes Attachments
- Also explicit transaction cleanup in ChatLocalDataSource.deleteConversation for safety
- No orphan records

### Transaction Boundaries
- insertMessagesInTransaction: batch insert in single transaction
- deleteConversation: transaction for conversation + explicit message cleanup
- runInTransaction helper available in AppDatabase

## 3. Message Lifecycle

```
User types -> ChatController.sendMessage(content)
  -> Check isStreaming (if true, ignore second send - documented concurrency policy)
  -> Check network connectivity (if offline, save user message as completed, show offline error)
  -> ChatRepository.sendMessageStream()
     -> Save user message (check duplicate ID)
     -> Create assistant placeholder with status=streaming, content=''
     -> Build AiRequest
     -> Call AiGateway.streamComplete()
        -> If UnimplementedError (no backend): mark assistant as failed with code=provider_unavailable, preserve empty content, return FailureResult
        -> If stream:
           accumulatedContent = ''
           on chunk: accumulatedContent += chunk.content
                      assistantMsg = copyWith(content: accumulatedContent, status: streaming/completed)
                      save to DB
           onError: preserve accumulatedContent, mark failed, metadata partial_content_preserved
           onDone: mark completed, update conversation timestamp
  -> Controller reloads messages from DB
```

### Message States
- sending: initial user message creation (short-lived)
- streaming: assistant generating, content grows
- completed: terminal success
- failed: terminal failure, preserves partial content + error code in metadata
- cancelled: terminal cancelled by user

## 4. Streaming Lifecycle

```
start -> chunk1 -> chunk2 -> chunk3 -> completed
content = chunk1 + chunk2 + chunk3 (not chunk3 only) - FIXED via accumulatedContent buffer

Implementation:
- StreamSubscription<AiResponse> _activeSubscriptions[conversationId]
- Completer<void> _cancelCompleters[conversationId] for cancellation
- Completer<void> streamDoneCompleter for stream completion
- Future.any([streamDoneCompleter.future, cancelCompleter.future])

Order preserved: Dart Stream guarantees order
Duplicate prevention: hasEmittedFinal flag prevents duplicate final yield
```

## 5. Cancellation Behavior

### Cases Covered
- Case A: Stop during streaming -> cancelCompleter.complete(), subscription.cancel(), save partial as cancelled
- Case B: Stop immediately after completion -> check isCompleted before complete, safe
- Case C: Double Stop -> check !completer.isCompleted before complete, safe
- Case D: Network failure during cancellation -> try/catch around cancel, ignore errors
- Case E: Leave ChatScreen during streaming -> ref.onDispose -> disposeController() -> cancelGeneration()
- Case F: App closed during streaming -> same as E via dispose

### No Issues
- No duplicate messages (hasEmittedFinal + ID check)
- No memory leak (finally always removes from maps)
- No unhandled exception (try/catch around cancel)
- No state update after dispose (_isDisposed + mounted checks)

## 6. Retry Behavior

- If assistant message failed:
  1. User taps Retry on failed assistant bubble
  2. retryMessage(messageId) finds last user message for that conversation
  3. Returns that user message
  4. Controller calls sendMessage(lastUser.content) -> new generation
  5. New assistant message created with new ID, old failed preserved or overwritten? Current: old failed preserved, new added (no duplicate user)
- If user message failed (offline case):
  - User message already saved as completed
  - Retry re-sends same content as new generation

- Behavior: No User duplicate unless explicitly new send. Only new assistant message.

## 7. Regenerate Behavior

- Triggered by Regenerate button on assistant message
- Steps:
  1. Find last assistant message in conversation (lastIndexWhere role==assistant)
  2. Delete it from DB
  3. Find last user message
  4. Return last user message
  5. Controller calls sendMessage(lastUser.content) -> new assistant response with new ID
- DB: old assistant deleted, new created
- Expandable later for multiple regenerations history

## 8. Public APIs for Phase 3

### Classes
- Conversation, ChatMessage, ChatAttachment, ChatContext, ModelConfig
- MessageRole, MessageStatus, AttachmentType enums
- ChatState
- AppDatabase, ChatLocalDataSource

### Interfaces
- ConversationRepository: createConversation, getConversation, listConversations, updateConversation, deleteConversation, archiveConversation, searchConversations
- ChatRepository: addMessage, getMessages, deleteMessage, updateMessage, sendMessageStream, retryMessage, regenerateLastAssistantMessage, cancelGeneration
- AiGateway: complete, streamComplete, listModels, isHealthy
- AiProvider: type, name, capabilities, isAvailable

### Methods
- ChatLocalDataSource: insertConversation, getConversation, listConversations, searchConversations, deleteConversation, insertMessage, getMessages, getLastUserMessage, deleteMessage, updateConversationTimestamp, messageExists
- ChatController: sendMessage, cancelGeneration, retryMessage, regenerateLast, deleteMessage, selectModel, disposeController

### Providers (Riverpod)
- databaseProvider
- chatLocalDataSourceProvider
- conversationRepositoryProvider
- chatRepositoryProvider
- createConversationUseCaseProvider, getConversationsUseCaseProvider, sendMessageUseCaseProvider
- conversationsProvider, filteredConversationsProvider, conversationsSearchProvider
- chatControllerProvider.family (conversationId)
- defaultModelProvider
- aiGatewayProvider, modelRegistryProvider, aiServiceProvider
- networkInfoProvider, connectivityStatusProvider

### No Breaking Changes Expected
- These APIs are stable foundation for Phase 3
- New features should extend, not modify

## 9. Known Limitations (Honest)

- No real AI provider connected - PlaceholderAiGateway throws UnimplementedError, caught as provider_unavailable
- No file upload implementation yet - LocalFileService throws UnimplementedError (foundation only)
- No voice-to-text integration yet - button shows snackbar foundation message
- No long-term memory system - ChatContext.userMemory is nullable placeholder
- No backend sync - all local Drift only
- No pagination beyond limit/offset in getMessages
- Search uses LIKE, not FTS5 - will need FTS for large datasets later
- ModelRegistry empty by default - UI shows fallback chip

## 10. Security

- No API keys in app - EnvConfig via dart-define only
- No tokens logged - LoggingInterceptor logs only method+path
- No secrets in logs - verified
- SecureStorage uses encryptedSharedPreferences on Android

## 11. Verification Status

### VERIFIED STATICALLY (Manual code review, no Flutter SDK)
- Database schema: FK, CASCADE, indexes, nullable handling - PASS (STATIC REVIEW)
- Migration v1->v2 safe - PASS (STATIC REVIEW)
- Repository memory leaks fixed - PASS (STATIC REVIEW)
- Streaming aggregation chunk1+chunk2+chunk3 - PASS (STATIC REVIEW)
- Cancellation 6 cases - PASS (STATIC REVIEW)
- Retry behavior - PASS (STATIC REVIEW)
- Regenerate behavior - PASS (STATIC REVIEW)
- Controller lifecycle dispose - PASS (STATIC REVIEW)
- Concurrency policy documented - PASS (STATIC REVIEW)
- No TODOs in production code - PASS (STATIC REVIEW)
- No fake AI responses - PASS (STATIC REVIEW)
- No hardcoded secrets - PASS (STATIC REVIEW)
- Architecture layers respected (UI not importing Drift/Dio) - PASS (STATIC REVIEW)
- Domain not importing Flutter - PASS (STATIC REVIEW)

### NOT VERIFIED (Requires Flutter SDK)
- flutter pub get - NOT EXECUTED (no Flutter SDK in container)
- flutter analyze - NOT EXECUTED
- flutter test - NOT EXECUTED
- build_runner for app_database.g.dart - NOT EXECUTED
- Drift code generation - NOT VERIFIED
- UI rendering on device (RTL/LTR, keyboard, scrolling) - NOT VERIFIED
- Actual DB operations on device - NOT VERIFIED
- Real streaming with backend - NOT VERIFIED (no backend)

## 12. Build Instructions

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Expected: App opens to ConversationsListScreen, shows empty state with NORLEX branding, allows creating conversation, chat screen shows honest "AI provider not configured" on send.
