import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Open-source face recognition using a MobileFaceNet TFLite model.
/// Produces an L2-normalized embedding; matching is cosine similarity.
/// Drop-in replacement for KBY-AI templateExtraction + similarityCalculation.
class FaceRecognizer {
  Interpreter? _interpreter;
  int _inputSize = 112;
  int _embeddingSize = 192;
  bool get isReady => _interpreter != null;

  Future<void> load({String asset = 'assets/models/mobilefacenet.tflite'}) async {
    try {
      final bytes = await rootBundle.load(asset);
      _interpreter = Interpreter.fromBuffer(bytes.buffer.asUint8List());
      final inShape = _interpreter!.getInputTensor(0).shape; // [1,112,112,3]
      final outShape = _interpreter!.getOutputTensor(0).shape; // [1,192]
      _inputSize = inShape[1];
      _embeddingSize = outShape[1];
    } catch (_) {
      _interpreter = null; // model absent -> recognition disabled gracefully
    }
  }

  /// Returns a normalized embedding, or null when the model is not loaded.
  List<double>? embed(img.Image faceCrop) {
    final itp = _interpreter;
    if (itp == null) return null;

    final resized = img.copyResize(faceCrop, width: _inputSize, height: _inputSize);
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [
            (p.r - 127.5) / 128.0,
            (p.g - 127.5) / 128.0,
            (p.b - 127.5) / 128.0,
          ];
        }),
      ),
    );
    final output = List.generate(1, (_) => List.filled(_embeddingSize, 0.0));
    itp.run(input, output);
    return _l2normalize(output[0]);
  }

  static List<double> _l2normalize(List<double> v) {
    var sum = 0.0;
    for (final x in v) sum += x * x;
    final norm = sqrt(sum) + 1e-10;
    return v.map((x) => x / norm).toList();
  }

  /// Cosine similarity between two normalized embeddings (-1..1).
  static double similarity(List<double> a, List<double> b) {
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) dot += a[i] * b[i];
    return dot;
  }

  void dispose() => _interpreter?.close();
}
