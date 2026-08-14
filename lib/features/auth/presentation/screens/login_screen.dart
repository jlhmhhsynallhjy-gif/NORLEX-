
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/routing/app_routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(isRtl ? 'تسجيل الدخول' : 'Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: isRtl ? 'البريد الإلكتروني' : 'Email', prefixIcon: const Icon(Icons.email)),
                  validator: (v) => v == null || !v.contains('@') ? (isRtl ? 'بريد غير صالح' : 'Invalid email') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: isRtl ? 'كلمة المرور' : 'Password', prefixIcon: const Icon(Icons.lock)),
                  validator: (v) => v == null || v.length < 8 ? (isRtl ? '8 أحرف على الأقل' : 'Min 8 chars') : null,
                ),
                const SizedBox(height: 24),
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [Icon(Icons.error, color: Theme.of(context).colorScheme.error), const SizedBox(width: 8), Expanded(child: Text(authState.error!))]),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: authState.status == AuthStatus.loading ? null : () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(authControllerProvider.notifier).login(email: _email.text.trim(), password: _password.text);
                    }
                  },
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: authState.status == AuthStatus.loading ? const CircularProgressIndicator() : Text(isRtl ? 'دخول' : 'Login'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(AppRoutes.register),
                  child: Text(isRtl ? 'ليس لديك حساب؟ سجل الآن' : 'No account? Register'),
                ),
                const Spacer(),
                if (authState.status == AuthStatus.loading)
                  Text(isRtl ? 'جاري التحقق...' : 'Authenticating...', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
