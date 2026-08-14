
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/repositories/auth_repository.dart';
import '../remote/auth_api.dart';
import '../local/auth_local_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi api;
  final AuthLocalStorage local;

  AuthRepositoryImpl({required this.api, required this.local});

  @override
  Future<Result<(AuthUser, AuthTokens)>> register({required String email, required String password, String? fullName}) async {
    final result = await api.register(email: email, password: password, fullName: fullName);
    if (result is Success<(AuthUser, AuthTokens)>) {
      await local.saveTokens(result.data.$2);
      await local.saveUser(result.data.$1);
    }
    return result;
  }

  @override
  Future<Result<(AuthUser, AuthTokens)>> login({required String email, required String password}) async {
    final result = await api.login(email: email, password: password);
    if (result is Success<(AuthUser, AuthTokens)>) {
      await local.saveTokens(result.data.$2);
      await local.saveUser(result.data.$1);
    }
    return result;
  }

  @override
  Future<Result<AuthTokens>> refresh({required String refreshToken}) async {
    final result = await api.refresh(refreshToken: refreshToken);
    if (result is Success<AuthTokens>) {
      await local.saveTokens(result.data);
    }
    return result;
  }

  @override
  Future<Result<void>> logout({required String refreshToken}) async {
    await api.logout(refreshToken: refreshToken);
    await local.clearTokens();
    return const Success(null);
  }

  @override
  Future<Result<AuthUser>> getMe() async {
    return api.getMe();
  }

  @override
  Future<Result<void>> saveTokens(AuthTokens tokens) async {
    try {
      await local.saveTokens(tokens);
      return const Success(null);
    } catch (e) {
      return FailureResult(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthTokens?>> getStoredTokens() async {
    try {
      final tokens = await local.getTokens();
      return Success(tokens);
    } catch (e) {
      return FailureResult(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> clearTokens() async {
    await local.clearTokens();
    return const Success(null);
  }

  @override
  Future<Result<AuthUser?>> getStoredUser() async {
    final user = await local.getUser();
    return Success(user);
  }

  @override
  Future<Result<void>> saveUser(AuthUser user) async {
    await local.saveUser(user);
    return const Success(null);
  }
}
