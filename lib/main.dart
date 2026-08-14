import 'package:flutter/material.dart';
import 'app/app_bootstrap.dart';
import 'app/app.dart';

Future<void> main() async {
  final container = await AppBootstrap.init();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NorlexApp(),
    ),
  );
}
