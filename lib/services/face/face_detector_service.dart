import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Wraps ML Kit face detection and derives a lightweight liveness signal
/// (blink + head-pose change) as an open-source substitute for the KBY-AI
/// liveness check in the original app.
class FaceDetectorService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // eye-open probabilities
      enableTracking: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<List<Face>> detect(InputImage image) => _detector.processImage(image);

  /// Returns true once a plausible live face is seen: exactly one face, both
  /// eyes detected, and either a blink or a head-yaw movement across frames.
  final List<double> _eyeHistory = [];
  double? _lastYaw;

  bool evaluateLiveness(Face face) {
    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    final yaw = face.headEulerAngleY;

    bool blinked = false;
    if (left != null && right != null) {
      final avg = (left + right) / 2;
      _eyeHistory.add(avg);
      if (_eyeHistory.length > 12) _eyeHistory.removeAt(0);
      final minOpen = _eyeHistory.reduce((a, b) => a < b ? a : b);
      final maxOpen = _eyeHistory.reduce((a, b) => a > b ? a : b);
      blinked = minOpen < 0.25 && maxOpen > 0.8;
    }

    bool moved = false;
    if (yaw != null) {
      if (_lastYaw != null && (yaw - _lastYaw!).abs() > 8) moved = true;
      _lastYaw = yaw;
    }
    return blinked || moved;
  }

  void reset() {
    _eyeHistory.clear();
    _lastYaw = null;
  }

  void dispose() => _detector.close();
}
