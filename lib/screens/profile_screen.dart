import 'package:flutter/material.dart';
import '../services/profile_service.dart';

const _purple = Color(0xFF5A41E0);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  Map<String, dynamic>? _d;
  String _msg = 'Loading...';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await _service.detailsByToken();
      var v = res;
      if (v is Map && v['data'] != null) v = v['data'];
      if (v is List) v = v.isNotEmpty ? v.first : {};
      setState(() { _d = Map<String, dynamic>.from(v as Map); _msg = ''; });
    } catch (e) {
      setState(() => _msg = 'Error: $e');
    }
  }

  String? _s(List<String> keys) {
    if (_d == null) return null;
    for (final k in keys) {
      final v = _d![k];
      if (v != null && '$v'.trim().isNotEmpty && '$v' != 'null' && '$v' != 'NA') {
        return '$v';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4FB),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _d == null
          ? Center(child: Text(_msg))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _banner(),
                  const SizedBox(height: 18),
                  _section('Work', [
                    _row('Employee ID', _s(['employee_id'])),
                    _row('Department', _s(['department'])),
                    _row('Sub department', _s(['subdepartment'])),
                    _row('Designation', _s(['designation'])),
                    _row('Shift', _s(['shift'])),
                    _row('Date of joining', _s(['date_of_joining'])),
                    _row('Date of exit', _s(['date_of_exit'])),
                    _row('Total experience', _s(['total_experience'])),
                  ]),
                  _section('Contact', [
                    _row('Email', _s(['email'])),
                    _row('Personal email', _s(['peronal_email', 'personal_email'])),
                    _row('Contact', _s(['employee_contact'])),
                    _row('Alternate contact', _s(['employee_alternate_contact'])),
                    _row('Local address', _s(['local_address'])),
                    _row('Permanent address', _s(['permanent_address'])),
                    _row('District', _s(['district_name'])),
                  ]),
                  _section('Personal', [
                    _row('Father / Guardian', _s(['father_name'])),
                    _row('Date of birth', _s(['date_of_birth'])),
                    _row('Gender', _s(['gender'])),
                    _row('Marital status', _s(['marital_status'])),
                    _row('Blood group', _s(['blood_group'])),
                  ]),
                  _section('IDs', [
                    _row('PAN', _s(['pan_no'])),
                    _row('Aadhaar', _s(['aadhaar_no'])),
                    _row('UAN', _s(['uan_no'])),
                    _row('ESIC', _s(['esic_no'])),
                  ]),
                  _section('Emergency', [
                    _row('Name', _s(['emergency_name'])),
                    _row('Contact', _s(['emergency_contact'])),
                    _row('Relation', _s(['emergency_relation'])),
                  ]),
                  _bankSection(),
                  _locationSection(),
                ],
              ),
            ),
    );
  }

  Widget _banner() {
    final photo = _s(['profile_image']);
    final hasPhoto = photo != null && photo.startsWith('http');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: _purple.withOpacity(.12),
          backgroundImage: hasPhoto ? NetworkImage(photo) : null,
          child: hasPhoto ? null : const Icon(Icons.person, size: 42, color: _purple),
        ),
        const SizedBox(height: 12),
        Text(_s(['full_name']) ?? 'Employee',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_s(['designation']) ?? '',
            style: TextStyle(color: Colors.grey[600])),
        if (_s(['department']) != null)
          Text(_s(['department'])!, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        if (_s(['status']) != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(_s(['status'])!,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    final visible = rows.whereType<_Row>().toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _purple)),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            for (var i = 0; i < visible.length; i++) ...[
              visible[i],
              if (i != visible.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ]
          ]),
        ),
      ]),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return _Row(label: label, value: value);
  }

  Widget _bankSection() {
    final raw = _d?['bank_details'];
    final b = (raw is List && raw.isNotEmpty && raw.first is Map)
        ? raw.first as Map
        : (raw is Map ? raw : null);
    if (b == null) return const SizedBox.shrink();
    String? bs(String k) {
      final v = b[k];
      return (v != null && '$v'.trim().isNotEmpty && '$v' != 'null') ? '$v' : null;
    }
    return _section('Bank', [
      _row('Account holder', bs('account_holder_name')),
      _row('Account number', bs('account_number')),
      _row('Bank', bs('bank_name')),
      _row('Branch', bs('branch_location')),
      _row('IFSC', bs('ifsc_code')),
    ]);
  }

  Widget _locationSection() {
    final raw = _d?['locations'];
    if (raw is! List || raw.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (final l in raw) {
      if (l is! Map) continue;
      final name = '${l['location_name'] ?? l['name'] ?? ''}'.trim();
      if (name.isEmpty || name == 'null') continue;
      rows.add(_Row(label: name, value: 'radius ${l['radius'] ?? '-'} m'));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _section('Assigned locations', rows);
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 4,
          child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        Expanded(
          flex: 6,
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ]),
    );
  }
}
