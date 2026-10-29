import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import 'punch_screen.dart';
import 'enroll_face_screen.dart';
import 'leave_screen.dart';
import 'expense_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <(IconData, String, Widget)>[
      (Icons.login, 'Punch In', const PunchScreen(punchType: 'in')),
      (Icons.logout, 'Punch Out', const PunchScreen(punchType: 'out')),
      (Icons.face_retouching_natural, 'Register Face', const EnrollFaceScreen()),
      (Icons.event_note, 'Leave', const LeaveScreen()),
      (Icons.receipt_long, 'Expenses', const ExpenseScreen()),
      (Icons.person, 'Profile', const ProfileScreen()),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.power_settings_new), onPressed: () => context.read<AuthProvider>().logout()),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final t in tiles)
            Card(
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => t.$3)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(t.$1, size: 40),
                  const SizedBox(height: 8),
                  Text(t.$2),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
