/// AI Provider Abstraction - No direct UI coupling allowed

enum AiProviderType { openAi, anthropic, google, openSource, custom }

enum AiCapability { chat, completion, image, audio, transcription, embedding, code }

abstract class AiProvider {
  AiProviderType get type;
  String get name;
  Set<AiCapability> get capabilities;
  bool get isAvailable;

  // NOTE: No API keys here. Provider config is injected via secure backend / EnvConfig
}

class AiModel {
  final String id;
  final String displayName;
  final AiProviderType providerType;
  final Set<AiCapability> capabilities;
  final int maxTokens;
  final bool supportsStreaming;

  const AiModel({
    required this.id,
    required this.displayName,
    required this.providerType,
    required this.capabilities,
    this.maxTokens = 4096,
    this.supportsStreaming = true,
  });
}

class AiRequest {
  final String prompt;
  final String? systemPrompt;
  final String modelId;
  final Map<String, dynamic>? parameters;
  final List<AiFileAttachment>? attachments;

  const AiRequest({
    required this.prompt,
    required this.modelId,
    this.systemPrompt,
    this.parameters,
    this.attachments,
  });
}

class AiResponse {
  final String id;
  final String content;
  final String modelId;
  final int? tokensUsed;
  final bool isStreaming;
  final DateTime createdAt;

  const AiResponse({
    required this.id,
    required this.content,
    required this.modelId,
    this.tokensUsed,
    this.isStreaming = false,
    required this.createdAt,
  });
}

class AiFileAttachment {
  final String fileId;
  final String fileName;
  final String mimeType;
  const AiFileAttachment({required this.fileId, required this.fileName, required this.mimeType});
}

abstract class AiProviderException implements Exception {
  final String message;
  const AiProviderException(this.message);
}
