import '../providers/ai_provider.dart';

/// AI Gateway - Single entry point for all AI features
/// UI never talks to provider directly

abstract class AiGateway {
  Future<AiResponse> complete(AiRequest request);
  Stream<AiResponse> streamComplete(AiRequest request);
  Future<List<AiModel>> listModels();
  Future<bool> isHealthy(AiProviderType providerType);
}

/// Placeholder implementation - clearly marked as not real
class PlaceholderAiGateway implements AiGateway {
  @override
  Future<AiResponse> complete(AiRequest request) async {
    // PLACEHOLDER: This is not a real AI response. Real implementation will be injected later.
    throw UnimplementedError('AiGateway not implemented yet - foundation only. No mock data returned.');
  }

  @override
  Stream<AiResponse> streamComplete(AiRequest request) {
    throw UnimplementedError('AiGateway streaming not implemented yet');
  }

  @override
  Future<List<AiModel>> listModels() async => [];

  @override
  Future<bool> isHealthy(AiProviderType providerType) async => false;
}
