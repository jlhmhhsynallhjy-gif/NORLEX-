
import 'dart:convert';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../../../core/constants/storage_keys.dart';

class AuthLocalStorage {
  final SecureStorageService secureStorage;
  final LocalStorageService localStorage;

  AuthLocalStorage({required this.secureStorage, required this.localStorage});

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';

  Future<void> saveTokens(AuthTokens tokens) async {
    // Access token in memory? For now secure storage but short-lived
    // Refresh token MUST be in secure storage
    await secureStorage.write(key: _accessTokenKey, value: tokens.accessToken);
    await secureStorage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await localStorage.setInt('auth_expires_in', tokens.expiresIn);
    await localStorage.setString('auth_token_type', tokens.tokenType);
  }

  Future<AuthTokens?> getTokens() async {
    final access = await secureStorage.read(key: _accessTokenKey);
    final refresh = await secureStorage.read(key: _refreshTokenKey);
    if (access == null || refresh == null) return null;
    final expiresIn = localStorage.getInt('auth_expires_in') ?? 900;
    return AuthTokens(accessToken: access, refreshToken: refresh, expiresIn: expiresIn);
  }

  Future<void> clearTokens() async {
    await secureStorage.delete(key: _accessTokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
    await localStorage.remove('auth_expires_in');
    await localStorage.remove(_userKey);
  }

  Future<void> saveUser(AuthUser user) async {
    await localStorage.setString(_userKey, jsonEncode({
      'id': user.id,
      'email': user.email,
      'full_name': user.fullName,
      'is_active': user.isActive,
      'created_at': user.createdAt.toIso8601String(),
    }));
  }

  Future<AuthUser?> getUser() async {
    final raw = localStorage.getString(_userKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AuthUser.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
