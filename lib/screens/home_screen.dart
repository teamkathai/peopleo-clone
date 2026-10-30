import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../services/attendance_service.dart';
import '../services/dashboard_service.dart';
import '../services/face/face_recognizer.dart';
import '../services/face/face_store.dart';
import '../state/auth_provider.dart';
import 'enroll_face_screen.dart';
import 'expense_screen.dart';
import 'face_capture_screen.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';
import 'select_location_screen.dart';

const _purple = Color(0xFF5A41E0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = DashboardService();
  final _att = AttendanceService();
  final _recognizer = FaceRecognizer();
  late Future<DashboardData> _future;
  SelectedLocation? _loc;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _recognizer.load();
    _future = _svc.load();
  }

  void _reload() => setState(() => _future = _svc.load());

  @override
  void dispose() { _recognizer.dispose(); super.dispose(); }

  // ---- punch orchestration (mirrors original DashboardController) ----
  Future<void> _onPressPunch(bool punchedIn) async {
    if (_busy) return;
    // 1. require a selected location (Select Location to set attendance for)
    if (_loc == null) {
      final picked = await Navigator.push<SelectedLocation>(context,
          MaterialPageRoute(builder: (_) => const SelectLocationScreen()));
      if (picked == null) return;
      setState(() => _loc = picked);
    }
    // 2. confirm before punch-out
    if (punchedIn) {
      final yes = await _confirm('Are you confirm to punch out', 'Yes', 'No');
      if (yes != true) return;
    }
    setState(() => _busy = true);
    try {
      await _runPunch(punchType: punchedIn ? '2' : '1', typeOfAttendance: 'present');
    } finally {
      if (mounted) setState(() => _busy = false);
      _reload();
    }
  }

  Future<void> _runPunch({required String punchType, required String typeOfAttendance}) async {
    // permissions
    if (!await _ensure(Permission.camera, 'Camera')) return;
    if (!await _ensure(Permission.location, 'Location')) return;

    // position + mock-location guard
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {
      _toast('Error getting location. Please try again.');
      return;
    }
    if (pos.isMocked) {
      _toast('Location Error! Mock location detected.');
      await _failRecord(pos, 'Some tricks are done with the device application.');
      return;
    }

    // face capture + liveness + similarity (open-source MobileFaceNet)
    final enrolled = await FaceStore.load();
    if (enrolled == null) {
      await _info('Action Required!', 'Register your face first (Register Face in the menu).');
      return;
    }
    final cap = await Navigator.push<FaceCaptureResult>(context,
        MaterialPageRoute(builder: (_) => const FaceCaptureScreen(prompt: 'Punch')));
    if (cap == null) return;

    final livenessPct = cap.live ? 100.0 : 0.0;
    double simPct = 0;
    bool matched = false;
    if (_recognizer.isReady) {
      final emb = _recognizer.embed(cap.crop);
      if (emb != null) {
        final sim = FaceRecognizer.similarity(enrolled, emb);
        simPct = sim * 100;
        matched = sim >= AppConstants.similarityThreshold &&
            livenessPct >= AppConstants.livenessThreshold * 100;
      }
    }
    if (!matched) {
      _toast('Face not matched.');
      await _failRecord(pos,
          '*Version : ${AppConstants.appVersion}, *Similarity: ${simPct.toStringAsFixed(2)} %, *Liveness: ${livenessPct.toStringAsFixed(2)} %');
      return;
    }

    // distance geofence
    final dist = Geolocator.distanceBetween(
        _loc!.latitude, _loc!.longitude, pos.latitude, pos.longitude);
    if (!_loc!.isTour && _loc!.radius > 0 && dist > _loc!.radius) {
      await _punchFail(pos, dist);
      return;
    }

    // submit exact body
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final body = <String, dynamic>{
      'punch_type': punchType,
      'current_time': now,
      'type_of_attendance': typeOfAttendance,
      'latitude': pos.latitude.toString(),
      'longitude': pos.longitude.toString(),
      'location_id': _loc!.locationId,
      'remark': _loc!.remark,
      'app_key': AppConstants.appKey,
      'app_version': AppConstants.appVersion,
    };
    try {
      final res = await _att.employeePunch(body);
      _toast((res['message']?.toString().isNotEmpty ?? false)
          ? res['message'].toString()
          : 'Punch recorded.');
    } catch (_) {
      _toast('Server response error!');
    }
  }

  Future<void> _punchFail(Position pos, double distM) async {
    final km = (distM / 1000);
    await _failRecord(pos,
        '*Office Distance: ${km.toStringAsFixed(2)} Km');
    await _info('Important',
        'You are about ${km.toStringAsFixed(2)} KM away from office location.');
    try {
      final lvl = await Battery().batteryLevel;
      if (lvl < 20) {
        await _info('Important',
            "Your phone's battery level is low. Kindly connect it to a charger before proceeding the punch-in process.");
      }
    } catch (_) {}
  }

  Future<void> _failRecord(Position pos, String remark) async {
    try {
      await _att.postFailPunch({
        'latitude': pos.latitude.toString(),
        'longitude': pos.longitude.toString(),
        'remark': remark,
      });
    } catch (_) {}
  }

  Future<bool> _ensure(Permission p, String label) async {
    var s = await p.status;
    if (!s.isGranted) s = await p.request();
    if (!s.isGranted) {
      await _info('$label Permission Denied',
          'You have denied the required ${label.toLowerCase()} permission. Please enable it in the app settings.');
      return false;
    }
    return true;
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _info(String title, String msg) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );

  Future<bool?> _confirm(String msg, String yes, String no) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(no)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(yes)),
          ],
        ),
      );

  // ----------------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMM y').format(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4FB),
      body: SafeArea(
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snap) {
            final d = snap.data ?? DashboardData();
            final punchedIn = d.punchedIn;
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _header(d),
                  const SizedBox(height: 16),
                  Row(children: [
                    _chip(Icons.login, 'Check in', d.checkIn),
                    const SizedBox(width: 10),
                    _chip(Icons.logout, 'Check out', d.checkOut),
                    const SizedBox(width: 10),
                    _chip(Icons.timelapse, 'Total hours', d.totalHours),
                  ]),
                  const SizedBox(height: 18),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(today, style: TextStyle(color: Colors.grey[600])),
                  ]),
                  const SizedBox(height: 10),
                  _attendanceCard(),
                  const SizedBox(height: 22),
                  Center(child: Text(punchedIn ? 'Punch-Out' : 'Punch-In',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                  const SizedBox(height: 14),
                  Center(child: _punchButton(punchedIn)),
                  const SizedBox(height: 26),
                  Row(children: [
                    Expanded(child: _infoCard(Icons.location_on_outlined, 'Location',
                        _loc?.name ?? (d.locationName.isEmpty ? 'Not selected' : d.locationName))),
                    const SizedBox(width: 12),
                    Expanded(child: _infoCard(Icons.access_time, 'Duration', d.totalHours)),
                  ]),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: _purple,
        onTap: (i) {
          if (i == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _attendanceCard() {
    return GestureDetector(
      onTap: () async {
        final picked = await Navigator.push<SelectedLocation>(context,
            MaterialPageRoute(builder: (_) => const SelectLocationScreen()));
        if (picked != null) setState(() => _loc = picked);
      },
      child: _card(Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Attendance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_loc == null ? 'Set attendance for today' : 'Location: ${_loc!.name}',
              style: const TextStyle(color: Colors.grey)),
        ]),
      )),
    );
  }

  Widget _header(DashboardData d) {
    final hasPhoto = d.photoUrl != null && d.photoUrl!.startsWith('http');
    return Row(children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: _purple.withOpacity(.15),
        backgroundImage: hasPhoto ? NetworkImage(d.photoUrl!) : null,
        child: hasPhoto ? null : const Icon(Icons.person, color: _purple),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome, ${d.name}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          if (d.designation.isNotEmpty)
            Text(d.designation, style: TextStyle(color: Colors.grey[600])),
        ]),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.notifications_none),
        onSelected: (v) {
          Widget? s;
          if (v == 'face') s = const EnrollFaceScreen();
          if (v == 'leave') s = const LeaveScreen();
          if (v == 'expense') s = const ExpenseScreen();
          if (v == 'logout') { context.read<AuthProvider>().logout(); return; }
          if (s != null) Navigator.push(context, MaterialPageRoute(builder: (_) => s!));
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'face', child: Text('Register Face')),
          PopupMenuItem(value: 'leave', child: Text('Leave')),
          PopupMenuItem(value: 'expense', child: Text('Expenses')),
          PopupMenuItem(value: 'logout', child: Text('Logout')),
        ],
      ),
    ]);
  }

  Widget _chip(IconData ic, String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(ic, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Flexible(child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  Widget _infoCard(IconData ic, String label, String value) => _card(Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ic, size: 18, color: _purple),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      ));

  Widget _card(Widget child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: child,
      );

  Widget _punchButton(bool punchedIn) => GestureDetector(
        onTap: _busy ? null : () => _onPressPunch(punchedIn),
        child: Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: punchedIn
                  ? const [Color(0xFFFF7A7A), Color(0xFFE23636)]
                  : const [Color(0xFF7BE26A), Color(0xFF34B64A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(
                color: (punchedIn ? Colors.red : Colors.green).withOpacity(.4),
                blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: _busy
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : const Icon(Icons.fingerprint, size: 56, color: Colors.white),
        ),
      );
}
