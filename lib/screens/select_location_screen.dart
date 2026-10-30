import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

const _purple = Color(0xFF5A41E0);

/// The chosen attendance location (or a "Tour" entry with remarks),
/// mirroring the original app's Select Location + Tour-remarks flow.
class SelectedLocation {
  final String locationId;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isTour;
  final String remark;
  SelectedLocation({
    required this.locationId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.isTour = false,
    this.remark = '',
  });
}

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});
  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final _svc = AttendanceService();
  List<Map<String, dynamic>> _locs = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final l = await _svc.locations();
      setState(() { _locs = l; _loading = false; });
    } catch (e) {
      setState(() { _err = 'No location data found'; _loading = false; });
    }
  }

  double _d(dynamic v) => double.tryParse('$v') ?? 0;

  void _pick(Map<String, dynamic> e) {
    final name = '${e['location_name'] ?? e['location'] ?? e['name'] ?? ''}';
    final isTour = name.toLowerCase().contains('tour');
    if (isTour) { _askRemark(e, name); return; }
    Navigator.pop(context, SelectedLocation(
      locationId: '${e['location_id'] ?? e['id'] ?? ''}',
      name: name,
      latitude: _d(e['latitude']),
      longitude: _d(e['longitude']),
      radius: _d('${e['radius'] ?? e['capture_radius']}'.replaceAll(RegExp(r'[^0-9.]'), '')),
    ));
  }

  Future<void> _askRemark(Map<String, dynamic> e, String name) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Action Required!'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: const InputDecoration(
              hintText: 'Enter remarks to select "Tour"', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    final remark = c.text.trim();
    if (ok == true && remark.isNotEmpty && RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(remark) == false) {
      Navigator.pop(context, SelectedLocation(
        locationId: '${e['location_id'] ?? e['id'] ?? ''}',
        name: name, latitude: _d(e['latitude']), longitude: _d(e['longitude']),
        radius: _d('${e['radius'] ?? e['capture_radius']}'.replaceAll(RegExp(r'[^0-9.]'), '')),
        isTour: true, remark: remark,
      ));
    } else if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remarks required (no special characters).')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4FB),
      appBar: AppBar(
        title: const Text('Select Location to set attendance for'),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null || _locs.isEmpty
              ? Center(child: Text(_err ?? 'No location data found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _locs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final e = _locs[i];
                    final name = '${e['location_name'] ?? e['location'] ?? e['name'] ?? ''}';
                    final client = '${e['client'] ?? e['branch'] ?? ''}';
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: _purple),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: client.isEmpty ? null : Text(client),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pick(e),
                      ),
                    );
                  },
                ),
    );
  }
}
