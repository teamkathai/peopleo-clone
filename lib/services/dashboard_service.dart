import 'profile_service.dart';
import 'attendance_service.dart';

/// Normalized values for the home dashboard, tolerant of the backend's
/// varying key names / wrapping (Map vs List under "data").
class DashboardData {
  String name;
  String designation;
  String? photoUrl;
  String checkIn;
  String checkOut;
  String totalHours;
  String locationName;
  bool punchedIn;
  DashboardData({
    this.name = 'Employee',
    this.designation = '',
    this.photoUrl,
    this.checkIn = '--:--',
    this.checkOut = '--:--',
    this.totalHours = '00.00 Hrs',
    this.locationName = '',
    this.punchedIn = false,
  });
}

class DashboardService {
  final _profile = ProfileService();
  final _attendance = AttendanceService();

  static Map _unwrap(dynamic d) {
    var v = d;
    if (v is Map && v['data'] != null) v = v['data'];
    if (v is List) return v.isNotEmpty && v.first is Map ? v.first as Map : {};
    return v is Map ? v : {};
  }

  static String? _s(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && '$v'.trim().isNotEmpty && '$v' != 'null') return '$v';
    }
    return null;
  }

  static String _timeOnly(String? v) {
    if (v == null) return '--:--';
    final m = RegExp(r'(\d{1,2}:\d{2})').firstMatch(v);
    return m != null ? m.group(1)! : v;
  }

  Future<DashboardData> load() async {
    final out = DashboardData();
    try {
      final d = _unwrap(await _profile.detailsByToken());
      out.name = _s(d, ['full_name', 'name', 'employee_name', 'emp_name']) ?? out.name;
      out.designation =
          _s(d, ['designation_name', 'designation', 'role']) ?? out.designation;
      out.photoUrl = _s(d, ['profile_image', 'profile_pic', 'photo', 'image']);
      final locs = d['locations'];
      if (locs is List) {
        for (final l in locs) {
          if (l is Map) {
            final n = '${l['location_name'] ?? ''}'.trim();
            if (n.isNotEmpty && n != 'null') { out.locationName = n; break; }
          }
        }
      }
    } catch (_) {}
    try {
      final r = await _attendance.punchRecords();
      var list = r is Map ? r['data'] : r;
      if (list is List && list.isNotEmpty && list.first is Map) {
        final rec = list.first as Map; // most recent / today
        final ci = _s(rec, ['in_time', 'punch_in', 'check_in']);
        final co = _s(rec, ['out_time', 'punch_out', 'check_out']);
        out.checkIn = _timeOnly(ci);
        out.checkOut = _timeOnly(co);
        final dur = _s(rec, ['duration', 'total_hours', 'working_hours']);
        if (dur != null) out.totalHours = dur.contains('Hr') ? dur : '$dur Hrs';
        final recLoc = _s(rec, ['location', 'location_name']);
        if (recLoc != null) out.locationName = recLoc;
        // is_punchout==true means they have checked in and not yet out.
        final ip = rec['is_punchout'];
        if (ip is bool) {
          out.punchedIn = ip;
        } else if (ip != null && '$ip' != 'null') {
          out.punchedIn = '$ip' == 'true' || '$ip' == '1';
        } else {
          out.punchedIn = _timeOnly(ci) != '--:--' && _timeOnly(co) == '--:--';
        }
      }
    } catch (_) {}
    return out;
  }
}
