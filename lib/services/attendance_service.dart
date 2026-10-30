import 'package:dio/dio.dart';
import '../core/api_endpoints.dart';
import 'api_client.dart';

class AttendanceService {
  final _api = ApiClient.instance;

  /// POST /employee-punch with the EXACT field set the original app sends:
  /// punch_type ("1"=in / "2"=out), current_time (yyyy-MM-dd HH:mm:ss),
  /// type_of_attendance ("present"/"absent"), latitude, longitude,
  /// location_id, remark, app_key, app_version.
  Future<Map<String, dynamic>> employeePunch(Map<String, dynamic> body) async {
    final res = await _api.post(Endpoints.employeePunch, data: body);
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// POST /punchfail_record { latitude, longitude, remark }
  Future<void> postFailPunch(Map<String, dynamic> body) async {
    await _api.post(Endpoints.punchfailRecord, data: body);
  }

  /// GET /employee-punch-records?month=0  (today's record is data[0])
  Future<dynamic> punchRecords({String month = '0'}) async =>
      (await _api.get(Endpoints.employeePunchRecords, query: {'month': month})).data;

  /// GET /location-list -> locations assigned to the user.
  Future<List<Map<String, dynamic>>> locations() async {
    final raw = (await _api.get(Endpoints.locationList)).data;
    final list = raw is Map ? raw['data'] : raw;
    if (list is! List) return [];
    return [for (final e in list) if (e is Map) Map<String, dynamic>.from(e)];
  }
}
