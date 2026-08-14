
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/routing/app_routes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() { _email.dispose(); _password.dispose(); _name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) context.go(AppRoutes.home);
    });

    return Scaffold(
      appBar: AppBar(title: Text(isRtl ? 'إنشاء حساب' : 'Create Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: _name, decoration: InputDecoration(labelText: isRtl ? 'الاسم الكامل' : 'Full Name', prefixIcon: const Icon(Icons.person))),
                const SizedBox(height: 16),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: isRtl ? 'البريد الإلكتروني' : 'Email', prefixIcon: const Icon(Icons.email)), validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: isRtl ? 'كلمة المرور' : 'Password', prefixIcon: const Icon(Icons.lock)), validator: (v) => v == null || v.length < 8 ? 'Min 8 chars' : null),
                const SizedBox(height: 24),
                if (authState.error != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)), child: Text(authState.error!)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: authState.status == AuthStatus.loading ? null : () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(authControllerProvider.notifier).register(email: _email.text.trim(), password: _password.text, fullName: _name.text.trim().isEmpty ? null : _name.text.trim());
                    }
                  },
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: authState.status == AuthStatus.loading ? const CircularProgressIndicator() : Text(isRtl ? 'إنشاء حساب' : 'Create Account'),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: () => context.go(AppRoutes.login), child: Text(isRtl ? 'لديك حساب؟ دخول' : 'Have account? Login')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
