import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();
  bool _loading = false;
  String? _error;
  bool _loggedIn = false;

  bool get loading => _loading;
  String? get error => _error;
  bool get loggedIn => _loggedIn;

  Future<void> bootstrap() async {
    final sp = await SharedPreferences.getInstance();
    _loggedIn = (sp.getString('auth_token') ?? '').isNotEmpty;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final body = await _auth.login(email: email, password: password);
      final ok = (body['status'] == true) ||
          (body['success'] == true) ||
          (body['token'] != null) ||
          (body['data']?['token'] != null);
      _loggedIn = ok;
      if (!ok) _error = (body['message'] ?? 'Login failed').toString();
      return ok;
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _loggedIn = false;
    notifyListeners();
  }
}
