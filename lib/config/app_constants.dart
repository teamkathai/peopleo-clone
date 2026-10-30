/// Values the original app sends with every punch.
class AppConstants {
  AppConstants._();
  static const String appKey = 'peopleo_ssepd';
  static const String appVersion = '1.0.0';
  // Original KBY-AI thresholds recovered from the AOT snapshot:
  // onFaceDetected parsed livenessThreshold "0.7" and similarity gate "0.5".
  static const double livenessThreshold = 0.7; // *100 -> 70%
  static const double similarityThreshold = 0.5;
}
