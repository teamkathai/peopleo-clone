import '../core/api_endpoints.dart';
import 'api_client.dart';

class LeaveService {
  final _api = ApiClient.instance;

  Future<dynamic> leaveTypes() async => (await _api.get(Endpoints.leaveTypeList)).data;
  Future<dynamic> myLeaves() async => (await _api.get(Endpoints.myLeaveList)).data;
  Future<dynamic> balance() async => (await _api.get(Endpoints.leaveBalance)).data;

  /// POST /apply-leave { leave_type, from_date, to_date, reason }
  Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    final res = await _api.post(Endpoints.applyLeave, data: {
      'leave_type': leaveType,
      'from_date': fromDate,
      'to_date': toDate,
      'reason': reason,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelRequest(String leaveId) async {
    final res = await _api.post(Endpoints.empLeaveCancelRequest, data: {'leave_id': leaveId});
    return res.data as Map<String, dynamic>;
  }
}
