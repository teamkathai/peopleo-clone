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
      final cap = await Navigator.push<FaceCaptureResult>(
        context, MaterialPageRoute(builder: (_) => FaceCaptureScreen(prompt: 'Punch ${widget.punchType.toUpperCase()}')),
      );
      if (cap == null) { setState(() => _status = 'Cancelled'); return; }
      if (!cap.live) { setState(() => _status = 'Liveness failed \u2014 please blink.'); return; }

      bool matched = true;
      double? sim;
      // Only enforce face matching when both a model and an enrolled face exist.
      if (_recognizer.isReady && enrolled != null) {
        final emb = _recognizer.embed(cap.crop);
        if (emb == null) { setState(() => _status = 'Could not read face.'); return; }
        sim = FaceRecognizer.similarity(enrolled, emb);
        matched = sim >= ApiConfig.faceMatchThreshold;
        setState(() => _status = 'Similarity ${sim!.toStringAsFixed(3)} \u2014 ${matched ? "MATCH" : "NO MATCH"}');
        if (!matched) return;
      }

      setState(() => _status = 'Getting location...');
      final pos = await _location();
      if (pos == null) { setState(() => _status = 'Location permission needed.'); return; }

      setState(() => _status = 'Finding nearest site...');
      String? locId;
      try {
        final near = await _attendance.nearestLocation(pos.latitude, pos.longitude);
        if (near != null) {
          locId = near.id;
          if (!near.inRange) {
            setState(() => _status =
                'You are ${near.distanceM.round()} m from ${near.name} (allowed ${near.radiusM.round()} m).');
            return;
          }
        }
      } catch (_) {/* location list optional */}

      setState(() => _status = 'Submitting punch...');
      final res = await _attendance.punch(
        punchType: widget.punchType,
        latitude: pos.latitude,
        longitude: pos.longitude,
        locationId: locId,
        selfie: cap.jpeg,
        faceMatched: matched,
        similarity: sim,
      );
      final ok = res['status'] == true;
      final msg = (res['message']?.toString().isNotEmpty ?? false)
          ? res['message'].toString()
          : (ok ? 'Punch ${widget.punchType} recorded.' : 'Punch failed.');
      setState(() => _status = msg);
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
