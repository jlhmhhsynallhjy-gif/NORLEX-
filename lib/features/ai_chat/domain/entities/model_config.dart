import '../../../core/ai/providers/ai_provider.dart';

class ModelConfig {
  final String providerId;
  final String modelId;
  final String displayName;
  final Set<AiCapability> capabilities;
  final int contextWindow;
  final bool supportsStreaming;
  final bool supportsVision;
  final bool supportsTools;

  const ModelConfig({
    required this.providerId,
    required this.modelId,
    required this.displayName,
    this.capabilities = const {AiCapability.chat},
    this.contextWindow = 8192,
    this.supportsStreaming = true,
    this.supportsVision = false,
    this.supportsTools = false,
  });

  bool get canStream => supportsStreaming && capabilities.contains(AiCapability.chat);
}
