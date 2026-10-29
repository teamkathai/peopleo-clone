import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _service = ExpenseService();
  final _clientId = TextEditingController();
  final _amount = TextEditingController();
  final _remark = TextEditingController();
  DateTime _date = DateTime.now();
  File? _receipt;
  String _msg = '';
  bool _busy = false;

  Future<void> _submit() async {
    setState(() { _busy = true; _msg = ''; });
    try {
      final res = await _service.addExpense(
        clientId: _clientId.text.trim(),
        amount: _amount.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_date),
        remark: _remark.text.trim(),
        receipt: _receipt,
      );
      setState(() => _msg = (res['message'] ?? 'Expense submitted').toString());
    } catch (e) {
      setState(() => _msg = 'Error: $e');
    } finally { setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _clientId, decoration: const InputDecoration(labelText: 'Client ID', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _remark, decoration: const InputDecoration(labelText: 'Remark', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.camera);
            if (x != null) setState(() => _receipt = File(x.path));
          },
          icon: const Icon(Icons.attach_file),
          label: Text(_receipt == null ? 'Attach receipt' : 'Receipt attached'),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _submit, child: const Text('Submit')),
        const SizedBox(height: 12),
        if (_msg.isNotEmpty) Text(_msg),
      ]),
    );
  }
}
