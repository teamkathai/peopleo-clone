import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.badge_outlined, size: 72),
              const SizedBox(height: 12),
              Text('Peopleo SSEPD', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email / Employee ID', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              if (auth.error != null) Text(auth.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              AppButton(
                label: 'Login',
                busy: auth.loading,
                onPressed: () => context.read<AuthProvider>().login(_email.text.trim(), _password.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
