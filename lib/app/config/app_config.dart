import 'env_config.dart';

class AppConfig {
  final EnvConfig env;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final String dbName;

  const AppConfig({
    required this.env,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.dbName = 'norlex.db',
  });

  factory AppConfig.fromEnv(EnvConfig envConfig) {
    return AppConfig(env: envConfig);
  }
}
