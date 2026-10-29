import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  Map<String, dynamic>? _data;
  String _msg = 'Loading...';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await _service.detailsByToken();
      final map = (res is Map && res['data'] is Map) ? res['data'] as Map : (res is Map ? res : {});
      setState(() { _data = Map<String, dynamic>.from(map); _msg = ''; });
    } catch (e) {
      setState(() => _msg = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _data == null
          ? Center(child: Text(_msg))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in _data!.entries)
                  ListTile(title: Text(e.key), subtitle: Text('${e.value}')),
              ],
            ),
    );
  }
}
