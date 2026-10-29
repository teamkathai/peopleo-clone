import '../core/api_endpoints.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  /// POST /mob-login  { mobile, password, token(fcm) }
  /// The live backend keys the login on `mobile`, not email.
  Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
    String? fcmToken,
  }) async {
    final res = await _api.post(Endpoints.mobLogin, data: {
      'mobile': mobile,
      'password': password,
      if (fcmToken != null) 'token': fcmToken,
    });
    final body = res.data as Map<String, dynamic>;
    final token = (body['token'] ??
            body['access_token'] ??
            body['data']?['token'])
        ?.toString();
    if (token != null) await _api.saveToken(token);
    return body;
  }

  /// POST /forget-password-emp { mobile }  -> sends an OTP to the number.
  Future<Map<String, dynamic>> requestPasswordOtp(String mobile) async {
    final res =
        await _api.post(Endpoints.forgetPasswordEmp, data: {'mobile': mobile});
    return res.data as Map<String, dynamic>;
  }

  /// POST /validate-otp { mobile, otp }
  Future<Map<String, dynamic>> validateOtp({
    required String mobile,
    required String otp,
  }) async {
    final res = await _api
        .post(Endpoints.validateOtp, data: {'mobile': mobile, 'otp': otp});
    return res.data as Map<String, dynamic>;
  }

  /// POST /set-password { mobile, password }  (used after OTP validation)
  Future<Map<String, dynamic>> setPassword({
    required String mobile,
    required String password,
  }) async {
    final res = await _api.post(Endpoints.setPassword,
        data: {'mobile': mobile, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  /// POST /change-password { password, new_password }
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _api.post(Endpoints.changePassword, data: {
      'password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> logout() => _api.clearToken();
}
