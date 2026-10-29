/// Live backend configuration.
/// NOTE: endpoints are kept EXACTLY as the original app uses them. Do not alter.
class ApiConfig {
  ApiConfig._();

  /// Base URL extracted from the original build. Untouched.
  static const String baseUrl = 'https://ssepdats-backend.ino-o.com/api/v1';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Face match acceptance threshold (cosine similarity). Tune per model.
  static const double faceMatchThreshold = 0.62;
}
