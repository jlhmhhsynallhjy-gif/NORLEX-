enum EnvType { dev, staging, prod }

class EnvConfig {
  final EnvType envType;
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;

  const EnvConfig({
    required this.envType,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
  });

  factory EnvConfig.fromEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    final type = switch (env) {
      'staging' => EnvType.staging,
      'prod' => EnvType.prod,
      _ => EnvType.dev,
    };

    return EnvConfig(
      envType: type,
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.norlex.app'),
      appName: 'NORLEX',
      enableLogging: type != EnvType.prod,
    );
  }

  bool get isDev => envType == EnvType.dev;
  bool get isProd => envType == EnvType.prod;
}
