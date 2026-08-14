import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/storage_keys.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.watch(secureStorageProvider));
});

class SecureStorageService {
  final FlutterSecureStorage _storage;
  SecureStorageService(this._storage);

  Future<String?> readToken() => _storage.read(key: StorageKeys.accessToken);
  Future<void> saveToken(String token) => _storage.write(key: StorageKeys.accessToken, value: token);
  Future<void> deleteToken() => _storage.delete(key: StorageKeys.accessToken);

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> clear() => _storage.deleteAll();
}
