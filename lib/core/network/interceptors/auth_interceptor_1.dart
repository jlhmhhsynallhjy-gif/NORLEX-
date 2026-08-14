
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_providers.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;
  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final tokensResult = await repo.getStoredTokens();
      if (tokensResult.isSuccess) {
        final tokens = tokensResult.dataOrNull;
        if (tokens != null) {
          options.headers['Authorization'] = 'Bearer \${tokens.accessToken}';
        }
      }
    } catch (_) {}
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh
      try {
        final repo = ref.read(authRepositoryProvider);
        final tokensResult = await repo.getStoredTokens();
        if (tokensResult.isSuccess) {
          final tokens = tokensResult.dataOrNull;
          if (tokens != null) {
            final refreshResult = await repo.refresh(refreshToken: tokens.refreshToken);
            if (refreshResult.isSuccess) {
              // Retry original request
              final newTokens = refreshResult.dataOrNull;
              if (newTokens != null) {
                err.requestOptions.headers['Authorization'] = 'Bearer \${newTokens.accessToken}';
                final dio = Dio();
                final response = await dio.fetch(err.requestOptions);
                return handler.resolve(response);
              }
            } else {
              // Session expired - logout
              await repo.clearTokens();
            }
          }
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}
