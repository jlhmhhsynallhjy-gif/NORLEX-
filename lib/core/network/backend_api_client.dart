import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_bootstrap.dart';
import '../utils/logger.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'dio_client.dart';

/// Backend API Client - connects Flutter to NORLEX Backend
/// Follows same pattern as DioClient but with backend-specific config

final backendApiClientProvider = Provider<Dio>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  final logger = AppLogger('BackendApi', enabled: appConfig.env.enableLogging);
  
  final dio = Dio(
    BaseOptions(
      baseUrl: appConfig.env.apiBaseUrl, // Points to backend, e.g., https://api.norlex.app or http://localhost:8000/api/v1
      connectTimeout: appConfig.connectTimeout,
      receiveTimeout: const Duration(seconds: 120), // Longer for streaming
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    LoggingInterceptor(logger: logger),
  ]);

  return dio;
});

class BackendEndpoints {
  static const String models = '/models';
  static const String chatCompletions = '/chat/completions';
  static const String chatStream = '/chat/stream';
  static const String conversations = '/conversations';
  static const String health = '/health';
}
