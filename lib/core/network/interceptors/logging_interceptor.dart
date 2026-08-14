import 'package:dio/dio.dart';
import '../../utils/logger.dart';

class LoggingInterceptor extends Interceptor {
  final AppLogger logger;
  LoggingInterceptor({required this.logger});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.debug('REQ [${options.method}] => ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.debug('RES [${response.statusCode}] => ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.warning('ERR [${err.response?.statusCode}] => ${err.requestOptions.path}: ${err.message}');
    super.onError(err, handler);
  }
}
