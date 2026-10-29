import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the enrolled face embedding locally (open-source replacement for
/// KBY-AI's stored template). Kept on-device; only match outcome is sent up.
class FaceStore {
  static const _key = 'enrolled_embedding';

  static Future<void> save(List<double> embedding) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(embedding));
  }

  static Future<List<double>?> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).map((e) => (e as num).toDouble()).toList();
  }

  static Future<bool> hasEnrollment() async => (await load()) != null;
}
