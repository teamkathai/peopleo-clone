import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/leave_service.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _service = LeaveService();
  final _reason = TextEditingController();
  String? _type;
  DateTime? _from, _to;
  String _msg = '';
  List<dynamic> _types = [];
  bool _busy = false;

  @override
  void initState() { super.initState(); _loadTypes(); }

  Future<void> _loadTypes() async {
    try {
      final data = await _service.leaveTypes();
      final list = (data is Map && data['data'] is List) ? data['data'] : (data is List ? data : []);
      setState(() => _types = list);
    } catch (_) {}
  }

  Future<DateTime?> _pick() => showDatePicker(
      context: context, firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now());

  Future<void> _apply() async {
    if (_type == null || _from == null || _to == null) { setState(() => _msg = 'Fill all fields'); return; }
    setState(() { _busy = true; _msg = ''; });
    try {
      final f = DateFormat('yyyy-MM-dd');
      final res = await _service.applyLeave(
        leaveType: _type!, fromDate: f.format(_from!), toDate: f.format(_to!), reason: _reason.text.trim());
      setState(() => _msg = (res['message'] ?? 'Leave applied').toString());
    } catch (e) {
      setState(() => _msg = 'Error: $e');
    } finally { setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Leave')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Leave type', border: OutlineInputBorder()),
          value: _type,
          items: [
            for (final t in _types)
              DropdownMenuItem(
                value: (t['id'] ?? t['leave_type_id'] ?? '').toString(),
                child: Text((t['name'] ?? t['leave_type'] ?? t['title'] ?? 'Type').toString()),
              ),
          ],
          onChanged: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () async { final d = await _pick(); if (d != null) setState(() => _from = d); },
              child: Text(_from == null ? 'From date' : DateFormat('yyyy-MM-dd').format(_from!)))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton(onPressed: () async { final d = await _pick(); if (d != null) setState(() => _to = d); },
              child: Text(_to == null ? 'To date' : DateFormat('yyyy-MM-dd').format(_to!)))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _reason, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _apply, child: const Text('Submit')),
        const SizedBox(height: 12),
        if (_msg.isNotEmpty) Text(_msg),
      ]),
    );
  }
}
