import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..bootstrap(),
      child: const PeopleoApp(),
    ),
  );
}

class PeopleoApp extends StatelessWidget {
  const PeopleoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peopleo SSEPD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1565C0), useMaterial3: true),
      home: Consumer<AuthProvider>(
        builder: (_, auth, __) => auth.loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
