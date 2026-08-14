import 'package:dio/dio.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/ai/providers/ai_provider.dart';
import '../../domain/entities/model_config.dart';

class BackendApi {
  final Dio dio;
  BackendApi(this.dio);

  Future<Result<List<ModelConfig>>> getModels() async {
    try {
      final res = await dio.get('/models');
      final List modelsRaw = res.data['models'] ?? [];
      final models = modelsRaw.map((m) {
        return ModelConfig(
          providerId: m['provider_id'] ?? 'unknown',
          modelId: m['model_id'] ?? m['id'] ?? '',
          displayName: m['display_name'] ?? m['model_id'] ?? '',
          contextWindow: m['context_window'] ?? 8192,
          supportsStreaming: m['supports_streaming'] ?? true,
          supportsVision: m['supports_vision'] ?? false,
          supportsTools: m['supports_tools'] ?? false,
        );
      }).toList();
      return Success(models);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  Stream<Result<String>> streamChat({
    required String modelId,
    required List<Map<String, String>> messages,
    required String conversationId,
  }) async* {
    try {
      // SSE streaming via Dio - will use backend /chat/stream
      // For foundation, this is structure - real SSE parsing will be implemented
      final response = await dio.post(
        '/chat/stream',
        data: {
          'model': modelId,
          'messages': messages,
          'stream': true,
          'conversation_id': conversationId,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      // Parse SSE stream
      // This is foundation - real implementation will parse event: chunk etc
      await for (final chunk in response.data.stream) {
        final str = String.fromCharCodes(chunk);
        // Simple parsing - production will use proper SSE parser
        if (str.contains('data:')) {
          // Extract content
          yield Success(str);
        }
      }
    } catch (e) {
      yield FailureResult(ErrorHandler.handleException(e));
    }
  }
}
