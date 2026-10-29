import '../core/api_endpoints.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  /// Safely pull a bearer token out of whatever shape the backend returns.
  /// `data` may be a Map, or a List like [{...,"token":...}], or absent.
  static String? _extractToken(Map body) {
    final top = body['token'] ?? body['access_token'];
    if (top != null) return top.toString();
    final data = body['data'];
    if (data is Map) {
      final t = data['token'] ?? data['access_token'];
      return t?.toString();
    }
    if (data is List && data.isNotEmpty && data.first is Map) {
      final first = data.first as Map;
      final t = first['token'] ?? first['access_token'];
      return t?.toString();
    }
    return null;
  }

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
    final body = Map<String, dynamic>.from(res.data as Map);
    final token = _extractToken(body);
    if (token != null && token.isNotEmpty) await _api.saveToken(token);
    return body;
  }

  /// POST /forget-password-emp { mobile }  -> sends an OTP to the number.
  Future<Map<String, dynamic>> requestPasswordOtp(String mobile) async {
    final res =
        await _api.post(Endpoints.forgetPasswordEmp, data: {'mobile': mobile});
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// POST /validate-otp { mobile, otp }
  Future<Map<String, dynamic>> validateOtp({
    required String mobile,
    required String otp,
  }) async {
    final res = await _api
        .post(Endpoints.validateOtp, data: {'mobile': mobile, 'otp': otp});
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// POST /set-password { mobile, password }  (used after OTP validation)
  Future<Map<String, dynamic>> setPassword({
    required String mobile,
    required String password,
  }) async {
    final res = await _api.post(Endpoints.setPassword,
        data: {'mobile': mobile, 'password': password});
    return Map<String, dynamic>.from(res.data as Map);
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
