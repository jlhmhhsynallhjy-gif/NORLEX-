import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';

class NorlexApp extends ConsumerWidget {
  const NorlexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'NORLEX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

// Re-export for main.dart
class UncontrolledProviderScope extends StatelessWidget {
  final ProviderContainer container;
  final Widget child;
  const UncontrolledProviderScope({super.key, required this.container, required this.child});

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScopeWidget(container: container, child: child);
  }
}

class UncontrolledProviderScopeWidget extends StatefulWidget {
  final ProviderContainer container;
  final Widget child;
  const UncontrolledProviderScopeWidget({super.key, required this.container, required this.child});
  @override
  State<UncontrolledProviderScopeWidget> createState() => _UncontrolledProviderScopeWidgetState();
}

class _UncontrolledProviderScopeWidgetState extends State<UncontrolledProviderScopeWidget> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(parent: widget.container, child: widget.child);
  }
}
