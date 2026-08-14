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

    // Backend URL - points to NORLEX Backend, not directly to AI providers
    // Dev: http://localhost:8000/api/v1
    // Prod: https://api.norlex.app/api/v1
    const backendUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000/api/v1');

    return EnvConfig(
      envType: type,
      apiBaseUrl: backendUrl,
      appName: 'NORLEX',
      enableLogging: type != EnvType.prod,
    );
  }

  bool get isDev => envType == EnvType.dev;
  bool get isProd => envType == EnvType.prod;
}
