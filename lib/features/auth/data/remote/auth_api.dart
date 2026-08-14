
import 'package:dio/dio.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/auth_tokens.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<Result<(AuthUser, AuthTokens)>> register({required String email, required String password, String? fullName}) async {
    try {
      final res = await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      final userJson = res.data['user'];
      final tokens = AuthTokens.fromJson(res.data);
      final user = AuthUser.fromJson({...userJson, 'created_at': DateTime.now().toIso8601String()});
      return Success((user, tokens));
    } on DioException catch (e) {
      final code = e.response?.data['code'] ?? 'register_failed';
      final msg = e.response?.data['message'] ?? 'Registration failed';
      return FailureResult(ServerFailure(msg, code: code));
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  Future<Result<(AuthUser, AuthTokens)>> login({required String email, required String password}) async {
    try {
      final res = await dio.post('/auth/login', data: {'email': email, 'password': password});
      final userJson = res.data['user'];
      final tokens = AuthTokens.fromJson(res.data);
      final user = AuthUser.fromJson({...userJson, 'created_at': DateTime.now().toIso8601String()});
      return Success((user, tokens));
    } on DioException catch (e) {
      final code = e.response?.data['code'] ?? 'login_failed';
      final msg = e.response?.data['message'] ?? 'Login failed';
      return FailureResult(ServerFailure(msg, code: code));
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  Future<Result<AuthTokens>> refresh({required String refreshToken}) async {
    try {
      final res = await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      final tokens = AuthTokens.fromJson(res.data);
      return Success(tokens);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  Future<Result<void>> logout({required String refreshToken}) async {
    try {
      await dio.post('/auth/logout', data: {'refresh_token': refreshToken});
      return const Success(null);
    } catch (e) {
      // Even if backend fails, we clear local
      return const Success(null);
    }
  }

  Future<Result<AuthUser>> getMe() async {
    try {
      final res = await dio.get('/auth/me');
      final user = AuthUser.fromJson(res.data['user'] ?? res.data);
      return Success(user);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }
}
