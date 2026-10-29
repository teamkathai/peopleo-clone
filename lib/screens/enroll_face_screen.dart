import 'package:flutter/material.dart';
import '../services/face/face_recognizer.dart';
import '../services/face/face_store.dart';
import 'face_capture_screen.dart';

class EnrollFaceScreen extends StatefulWidget {
  const EnrollFaceScreen({super.key});
  @override
  State<EnrollFaceScreen> createState() => _EnrollFaceScreenState();
}

class _EnrollFaceScreenState extends State<EnrollFaceScreen> {
  final _recognizer = FaceRecognizer();
  String _msg = 'Register your face once to enable face-verified punches.';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _recognizer.load().then((_) => setState(() => _ready = true));
  }

  Future<void> _enroll() async {
    final res = await Navigator.push<FaceCaptureResult>(
      context, MaterialPageRoute(builder: (_) => const FaceCaptureScreen(prompt: 'Register Face')),
    );
    if (res == null) return;
    if (!_recognizer.isReady) {
      setState(() => _msg = 'Face model not loaded. Add assets/models/mobilefacenet.tflite.');
      return;
    }
    final emb = _recognizer.embed(res.crop);
    if (emb == null) { setState(() => _msg = 'Could not read face.'); return; }
    await FaceStore.save(emb);
    setState(() => _msg = 'Face registered successfully.');
  }

  @override
  void dispose() { _recognizer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Face')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.face_6, size: 80),
          const SizedBox(height: 16),
          Text(_msg, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: _ready ? _enroll : null, child: const Text('Capture & Register')),
        ]),
      ),
    );
  }
}
