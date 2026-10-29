import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../services/face/face_detector_service.dart';
import '../services/face/face_recognizer.dart';

/// Shared capture flow: detect a single live face, crop it, return the crop
/// plus a captured JPEG file. Used for both enrollment and punch matching.
class FaceCaptureResult {
  final File jpeg;
  final img.Image crop;
  final bool live;
  FaceCaptureResult(this.jpeg, this.crop, this.live);
}

class FaceCaptureScreen extends StatefulWidget {
  final String prompt;
  const FaceCaptureScreen({super.key, required this.prompt});
  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _controller;
  final _detector = FaceDetectorService();
  String _status = 'Align your face in the frame';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    if (_busy || _controller == null) return;
    setState(() { _busy = true; _status = 'Checking...'; });
    try {
      final shot = await _controller!.takePicture();
      final file = File(shot.path);
      final faces = await _detector.detect(InputImage.fromFilePath(shot.path));
      if (faces.isEmpty) { setState(() => _status = 'No face detected'); return; }
      if (faces.length > 1) { setState(() => _status = 'Multiple faces \u2014 only you'); return; }
      final face = faces.first;
      final live = _detector.evaluateLiveness(face);

      final decoded = img.decodeJpg(await file.readAsBytes());
      if (decoded == null) { setState(() => _status = 'Capture failed'); return; }
      final r = face.boundingBox;
      final crop = img.copyCrop(decoded,
          x: r.left.clamp(0, decoded.width - 1).toInt(),
          y: r.top.clamp(0, decoded.height - 1).toInt(),
          width: r.width.clamp(1, decoded.width.toDouble()).toInt(),
          height: r.height.clamp(1, decoded.height.toDouble()).toInt());

      if (!mounted) return;
      Navigator.pop(context, FaceCaptureResult(file, crop, live));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.prompt)),
      body: c == null || !c.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(child: CameraPreview(c)),
              Padding(padding: const EdgeInsets.all(12), child: Text(_status)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _capture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture'),
                ),
              ),
            ]),
    );
  }
}
