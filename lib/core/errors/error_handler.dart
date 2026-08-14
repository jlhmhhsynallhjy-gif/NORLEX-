import 'package:dio/dio.dart';
import 'failures.dart';
import 'exceptions.dart';

class ErrorHandler {
  static Failure handleException(Object error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    if (error is ServerException) {
      return ServerFailure(error.message, statusCode: error.statusCode, code: error.code);
    }
    if (error is NetworkException) {
      return NetworkFailure(error.message);
    }
    if (error is CacheException) {
      return CacheFailure(error.message);
    }
    if (error is AuthException) {
      return AuthFailure(error.message);
    }
    return ServerFailure(error.toString());
  }

  static Failure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timeout');
      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final msg = e.response?.data is Map ? (e.response?.data['message'] ?? 'Server error') : 'Server error';
        return ServerFailure(msg.toString(), statusCode: status);
      default:
        return ServerFailure(e.message ?? 'Unexpected error');
    }
  }
}
