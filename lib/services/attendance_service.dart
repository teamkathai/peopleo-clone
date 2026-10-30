import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import '../core/api_endpoints.dart';
import 'api_client.dart';

class NearestLocation {
  final String id;
  final String name;
  final double distanceM;
  final double radiusM;
  NearestLocation(this.id, this.name, this.distanceM, this.radiusM);
  bool get inRange => distanceM <= radiusM;
}

class AttendanceService {
  final _api = ApiClient.instance;

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _now() {
    final n = DateTime.now();
    return '${n.year}-${_two(n.month)}-${_two(n.day)} '
        '${_two(n.hour)}:${_two(n.minute)}:${_two(n.second)}';
  }

  static double _haversine(double la1, double lo1, double la2, double lo2) {
    const R = 6371000.0;
    double rad(double d) => d * pi / 180.0;
    final dLa = rad(la2 - la1), dLo = rad(lo2 - lo1);
    final a = sin(dLa / 2) * sin(dLa / 2) +
        cos(rad(la1)) * cos(rad(la2)) * sin(dLo / 2) * sin(dLo / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// POST /employee-punch (multipart).
  /// Live backend requires: punch_type (punch_in|punch_out), current_time,
  /// type_of_attendance, latitude, longitude. location_id + image optional.
  Future<Map<String, dynamic>> punch({
    required String punchType, // "in" | "out"
    required double latitude,
    required double longitude,
    String? locationId,
    File? selfie,
    bool? faceMatched,
    double? similarity,
    String typeOfAttendance = 'Present',
  }) async {
    final form = FormData.fromMap({
      'punch_type': punchType == 'in' ? 'punch_in' : 'punch_out',
      'current_time': _now(),
      'type_of_attendance': typeOfAttendance,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (locationId != null) 'location_id': locationId,
      if (faceMatched != null) 'face_matched': faceMatched ? '1' : '0',
      if (similarity != null) 'similarity': similarity.toStringAsFixed(4),
      if (selfie != null)
        'image': await MultipartFile.fromFile(selfie.path, filename: 'selfie.jpg'),
    });
    final res = await _api.postForm(Endpoints.employeePunch, form);
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Pick the closest assigned location to the given coordinates.
  Future<NearestLocation?> nearestLocation(double lat, double lng) async {
    final raw = (await _api.get(Endpoints.locationList)).data;
    final list = (raw is Map ? raw['data'] : raw);
    if (list is! List || list.isEmpty) return null;
    NearestLocation? best;
    for (final e in list) {
      if (e is! Map) continue;
      final la = double.tryParse('${e['latitude']}');
      final lo = double.tryParse('${e['longitude']}');
      if (la == null || lo == null) continue;
      final d = _haversine(lat, lng, la, lo);
      final radius =
          double.tryParse('${e['capture_radius']}'.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 300;
      if (best == null || d < best.distanceM) {
        best = NearestLocation(
            '${e['id']}', '${e['location']}', d, radius);
      }
    }
    return best;
  }

  Future<dynamic> punchRecords() async =>
      (await _api.get(Endpoints.employeePunchRecords)).data;

  Future<dynamic> attendanceReport({Map<String, dynamic>? query}) async =>
      (await _api.get(Endpoints.attendanceReport, query: query)).data;

  Future<dynamic> locationList() async =>
      (await _api.get(Endpoints.locationList)).data;
}
