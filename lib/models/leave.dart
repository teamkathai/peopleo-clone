class LeaveType {
  final String id;
  final String name;
  LeaveType(this.id, this.name);
  factory LeaveType.fromJson(Map<String, dynamic> j) =>
      LeaveType((j['id'] ?? j['leave_type_id'] ?? '').toString(),
          (j['name'] ?? j['leave_type'] ?? j['title'] ?? '').toString());
}

class LeaveRecord {
  final String id;
  final String type;
  final String fromDate;
  final String toDate;
  final String status;
  LeaveRecord({required this.id, required this.type, required this.fromDate, required this.toDate, required this.status});
  factory LeaveRecord.fromJson(Map<String, dynamic> j) => LeaveRecord(
        id: (j['id'] ?? '').toString(),
        type: (j['leave_type'] ?? j['type'] ?? '').toString(),
        fromDate: (j['from_date'] ?? '').toString(),
        toDate: (j['to_date'] ?? '').toString(),
        status: (j['status'] ?? 'pending').toString(),
      );
}
