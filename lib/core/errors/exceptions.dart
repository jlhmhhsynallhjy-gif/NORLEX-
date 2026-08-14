class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  const ServerException(this.message, {this.statusCode, this.code});
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}
