
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/remote/auth_api.dart';
import '../data/local/auth_local_storage.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/entities/auth_user.dart';
import '../domain/entities/auth_tokens.dart';
import '../../../core/utils/result.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(backendApiClientProvider);
  return AuthApi(dio);
});

final authLocalStorageProvider = Provider<AuthLocalStorage>((ref) {
  final secure = ref.watch(secureStorageServiceProvider);
  final local = ref.watch(localStorageServiceProvider);
  return AuthLocalStorage(secureStorage: secure, localStorage: local);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(authApiProvider),
    local: ref.watch(authLocalStorageProvider),
  );
});

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? error;
  const AuthState({this.status = AuthStatus.initial, this.user, this.error});
  AuthState copyWith({AuthStatus? status, AuthUser? user, String? error}) {
    return AuthState(status: status ?? this.status, user: user ?? this.user, error: error);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthController(this._ref) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    final repo = _ref.read(authRepositoryProvider);
    final tokensResult = await repo.getStoredTokens();
    if (tokensResult is Success<AuthTokens?> && tokensResult.data != null) {
      // Try to get user from storage first
      final userResult = await repo.getStoredUser();
      if (userResult is Success<AuthUser?> && userResult.data != null) {
        state = AuthState(status: AuthStatus.authenticated, user: userResult.data);
        // Try refresh in background to validate
        _tryRefresh();
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _tryRefresh() async {
    final repo = _ref.read(authRepositoryProvider);
    final tokensResult = await repo.getStoredTokens();
    if (tokensResult is Success<AuthTokens?> && tokensResult.data != null) {
      final refreshResult = await repo.refresh(refreshToken: tokensResult.data!.refreshToken);
      if (refreshResult is FailureResult) {
        // Session expired
        await repo.clearTokens();
        state = const AuthState(status: AuthStatus.unauthenticated, error: 'Session expired');
      }
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.login(email: email, password: password);
    if (result is Success<(AuthUser, AuthTokens)>) {
      state = AuthState(status: AuthStatus.authenticated, user: result.data.$1);
      return true;
    } else if (result is FailureResult<(AuthUser, AuthTokens)>) {
      state = AuthState(status: AuthStatus.unauthenticated, error: result.failure.message);
      return false;
    }
    return false;
  }

  Future<bool> register({required String email, required String password, String? fullName}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.register(email: email, password: password, fullName: fullName);
    if (result is Success<(AuthUser, AuthTokens)>) {
      state = AuthState(status: AuthStatus.authenticated, user: result.data.$1);
      return true;
    } else if (result is FailureResult<(AuthUser, AuthTokens)>) {
      state = AuthState(status: AuthStatus.unauthenticated, error: result.failure.message);
      return false;
    }
    return false;
  }

  Future<void> logout() async {
    final repo = _ref.read(authRepositoryProvider);
    final tokensResult = await repo.getStoredTokens();
    if (tokensResult is Success<AuthTokens?> && tokensResult.data != null) {
      await repo.logout(refreshToken: tokensResult.data!.refreshToken);
    } else {
      await repo.clearTokens();
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
