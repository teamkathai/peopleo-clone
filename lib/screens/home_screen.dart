import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../services/dashboard_service.dart';
import 'punch_screen.dart';
import 'enroll_face_screen.dart';
import 'leave_screen.dart';
import 'expense_screen.dart';
import 'profile_screen.dart';

const _purple = Color(0xFF5A41E0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = DashboardService();
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.load();
  }

  void _reload() => setState(() => _future = _svc.load());

  Future<void> _punch(bool punchedIn) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PunchScreen(punchType: punchedIn ? 'out' : 'in')),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat("d'th' MMMM yyyy").format(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4FB),
      body: SafeArea(
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snap) {
            final d = snap.data ?? DashboardData();
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
                    const Text('Today',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(today, style: TextStyle(color: Colors.grey[600])),
                  ]),
                  const SizedBox(height: 10),
                  _card(const Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Attendance',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Set attendance for today',
                          style: TextStyle(color: Colors.grey)),
                    ]),
                  )),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(d.punchedIn ? 'Punch-out' : 'Punch-in',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 14),
                  Center(child: _punchButton(d.punchedIn)),
                  const SizedBox(height: 26),
                  Row(children: [
                    Expanded(
                      child: _card(Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: const [
                            Icon(Icons.location_on_outlined, size: 18, color: _purple),
                            SizedBox(width: 4),
                            Text('Location', style: TextStyle(color: Colors.grey)),
                          ]),
                          const SizedBox(height: 8),
                          Text(d.locationName.isEmpty ? 'Not set' : d.locationName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _card(Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: const [
                            Icon(Icons.access_time, size: 18, color: _purple),
                            SizedBox(width: 4),
                            Text('Duration', style: TextStyle(color: Colors.grey)),
                          ]),
                          const SizedBox(height: 8),
                          Text(d.totalHours,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                      )),
                    ),
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
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
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
          if (s != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => s!));
          }
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

  Widget _chip(IconData ic, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
            color: _purple, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ic, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Flexible(
                child: Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _punchButton(bool punchedIn) {
    return GestureDetector(
      onTap: () => _punch(punchedIn),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF7BE26A), Color(0xFF34B64A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.green.withOpacity(.4),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.fingerprint, size: 56, color: Colors.white),
      ),
    );
  }
}
