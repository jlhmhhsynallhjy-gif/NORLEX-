import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'config/env_config.dart';

class AppBootstrap {
  static Future<ProviderContainer> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    final sharedPrefs = await SharedPreferences.getInstance();
    final envConfig = EnvConfig.fromEnvironment();
    final appConfig = AppConfig.fromEnv(envConfig);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        envConfigProvider.overrideWithValue(envConfig),
        appConfigProvider.overrideWithValue(appConfig),
      ],
    );

    // Initialize core services that don't need context
    // Note: No API keys loaded here. Keys are injected via secure backend only.

    return container;
  }
}

// Providers for bootstrap
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final envConfigProvider = Provider<EnvConfig>((ref) {
  throw UnimplementedError('EnvConfig not initialized');
});

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig not initialized');
});
