
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../../features/ai_chat/presentation/screens/conversations_list_screen.dart';
import '../../features/ai_chat/presentation/screens/chat_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthPage = state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.register || state.matchedLocation == AppRoutes.welcome;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      if (isSplash) {
        if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) return null;
        if (isAuthenticated) return AppRoutes.home;
        return AppRoutes.welcome;
      }

      if (!isAuthenticated && !isAuthPage && !isSplash) {
        return AppRoutes.welcome;
      }

      if (isAuthenticated && isAuthPage) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const ConversationsListScreen()),
      GoRoute(path: AppRoutes.aiChat, builder: (context, state) => const ConversationsListScreen()),
      GoRoute(path: '/chat/:id', builder: (context, state) { final id = state.pathParameters['id']!; return ChatScreen(conversationId: id); }),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const _PlaceholderScreen(title: 'Settings')),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const _PlaceholderScreen(title: 'Profile')),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Route not found: \${state.uri}'))),
  );
});

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text(title)));
  }
}
