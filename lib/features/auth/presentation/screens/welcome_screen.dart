
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.auto_awesome, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(isRtl ? 'مرحبا بك في نورلكس' : 'Welcome to NORLEX', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(isRtl ? 'منصتك الموحدة للذكاء الاصطناعي' : 'Your unified AI platform', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(isRtl ? 'تسجيل الدخول' : 'Login'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.register),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(isRtl ? 'إنشاء حساب' : 'Create Account'),
              ),
              const SizedBox(height: 24),
              Text(isRtl ? 'آمن • خاص • مفتوح' : 'Secure • Private • Open', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
