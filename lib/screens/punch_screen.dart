import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../services/attendance_service.dart';
import '../services/face/face_recognizer.dart';
import '../services/face/face_store.dart';
import 'face_capture_screen.dart';

class PunchScreen extends StatefulWidget {
  final String punchType; // "in" | "out"
  const PunchScreen({super.key, required this.punchType});
  @override
  State<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  final _attendance = AttendanceService();
  final _recognizer = FaceRecognizer();
  String _status = 'Ready';
  bool _busy = false;

  @override
  void initState() { super.initState(); _recognizer.load(); }

  Future<Position?> _location() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return null;
    return Geolocator.getCurrentPosition();
  }

  Future<void> _run() async {
    setState(() { _busy = true; _status = 'Capturing face...'; });
    try {
      final enrolled = await FaceStore.load();
      if (enrolled == null) {
        setState(() => _status = 'No enrolled face. Use Register Face first.');
        return;
      }
      final cap = await Navigator.push<FaceCaptureResult>(
        context, MaterialPageRoute(builder: (_) => FaceCaptureScreen(prompt: 'Punch ${widget.punchType.toUpperCase()}')),
      );
      if (cap == null) { setState(() => _status = 'Cancelled'); return; }
      if (!cap.live) { setState(() => _status = 'Liveness failed \u2014 please blink.'); return; }
      if (!_recognizer.isReady) { setState(() => _status = 'Face model missing (add mobilefacenet.tflite).'); return; }

      final emb = _recognizer.embed(cap.crop);
      if (emb == null) { setState(() => _status = 'Could not read face.'); return; }
      final sim = FaceRecognizer.similarity(enrolled, emb);
      final matched = sim >= ApiConfig.faceMatchThreshold;
      setState(() => _status = 'Similarity ${sim.toStringAsFixed(3)} \u2014 ${matched ? "MATCH" : "NO MATCH"}');
      if (!matched) return;

      setState(() => _status = 'Getting location...');
      final pos = await _location();
      if (pos == null) { setState(() => _status = 'Location permission needed.'); return; }

      setState(() => _status = 'Submitting punch...');
      final res = await _attendance.punch(
        punchType: widget.punchType,
        latitude: pos.latitude,
        longitude: pos.longitude,
        selfie: cap.jpeg,
        faceMatched: matched,
        similarity: sim,
      );
      setState(() => _status = (res['message'] ?? 'Punch submitted').toString());
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _recognizer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Punch ${widget.punchType.toUpperCase()}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(widget.punchType == 'in' ? Icons.login : Icons.logout, size: 80),
          const SizedBox(height: 16),
          Text(_status, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _run,
            icon: const Icon(Icons.camera_alt),
            label: Text('Verify & Punch ${widget.punchType == 'in' ? 'In' : 'Out'}'),
          ),
        ]),
      ),
    );
  }
}
