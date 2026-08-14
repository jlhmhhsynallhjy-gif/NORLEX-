
import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../entities/auth_tokens.dart';

abstract class AuthRepository {
  Future<Result<(AuthUser, AuthTokens)>> register({required String email, required String password, String? fullName});
  Future<Result<(AuthUser, AuthTokens)>> login({required String email, required String password});
  Future<Result<AuthTokens>> refresh({required String refreshToken});
  Future<Result<void>> logout({required String refreshToken});
  Future<Result<AuthUser>> getMe();
  Future<Result<void>> saveTokens(AuthTokens tokens);
  Future<Result<AuthTokens?>> getStoredTokens();
  Future<Result<void>> clearTokens();
  Future<Result<AuthUser?>> getStoredUser();
  Future<Result<void>> saveUser(AuthUser user);
}
