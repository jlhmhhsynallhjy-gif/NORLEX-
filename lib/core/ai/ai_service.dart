import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gateway/ai_gateway.dart';
import 'providers/ai_provider.dart';

final aiGatewayProvider = Provider<AiGateway>((ref) => PlaceholderAiGateway());

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref.watch(aiGatewayProvider));
});

/// AiService - Used by Features, not by UI directly
class AiService {
  final AiGateway _gateway;
  AiService(this._gateway);

  Future<AiResponse> chat(AiRequest request) => _gateway.complete(request);
  Stream<AiResponse> chatStream(AiRequest request) => _gateway.streamComplete(request);
}
