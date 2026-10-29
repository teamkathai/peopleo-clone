import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_endpoints.dart';
import 'api_client.dart';

class AttendanceService {
  final _api = ApiClient.instance;

  /// POST /employee-punch (multipart) with selfie + geo + match result.
  Future<Map<String, dynamic>> punch({
    required String punchType, // "in" | "out"
    required double latitude,
    required double longitude,
    String? locationId,
    required File selfie,
    required bool faceMatched,
    double? similarity,
  }) async {
    final form = FormData.fromMap({
      'punch_type': punchType,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (locationId != null) 'location_id': locationId,
      'face_matched': faceMatched ? '1' : '0',
      if (similarity != null) 'similarity': similarity.toStringAsFixed(4),
      'image': await MultipartFile.fromFile(selfie.path, filename: 'selfie.jpg'),
    });
    final res = await _api.postForm(Endpoints.employeePunch, form);
    return res.data as Map<String, dynamic>;
  }

  Future<dynamic> punchRecords() async =>
      (await _api.get(Endpoints.employeePunchRecords)).data;

  Future<dynamic> attendanceReport({Map<String, dynamic>? query}) async =>
      (await _api.get(Endpoints.attendanceReport, query: query)).data;

  Future<dynamic> locationList() async =>
      (await _api.get(Endpoints.locationList)).data;
}
