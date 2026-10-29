import '../core/api_endpoints.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  /// POST /mob-login  { email, password, token(fcm) }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final res = await _api.post(Endpoints.mobLogin, data: {
      'email': email,
      'password': password,
      if (fcmToken != null) 'token': fcmToken,
    });
    final body = res.data as Map<String, dynamic>;
    final token = (body['token'] ?? body['access_token'] ?? body['data']?['token'])?.toString();
    if (token != null) await _api.saveToken(token);
    return body;
  }

  /// POST /validate-otp { mobile, otp }
  Future<Map<String, dynamic>> validateOtp({required String mobile, required String otp}) async {
    final res = await _api.post(Endpoints.validateOtp, data: {'mobile': mobile, 'otp': otp});
    return res.data as Map<String, dynamic>;
  }

  /// POST /forget-password-emp { email }
  Future<void> forgotPassword(String email) async {
    await _api.post(Endpoints.forgetPasswordEmp, data: {'email': email});
  }

  /// POST /change-password { password, new_password }
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    await _api.post(Endpoints.changePassword, data: {
      'password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> logout() => _api.clearToken();
}
