import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_bootstrap.dart';
import '../utils/logger.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  final logger = AppLogger('DioClient', enabled: appConfig.env.enableLogging);

  final dio = Dio(
    BaseOptions(
      baseUrl: appConfig.env.apiBaseUrl,
      connectTimeout: appConfig.connectTimeout,
      receiveTimeout: appConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    LoggingInterceptor(logger: logger),
  ]);

  return dio;
});
