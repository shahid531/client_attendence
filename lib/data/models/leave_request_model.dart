import '../../domain/entities/leave_request.dart';

class LeaveRequestModel extends LeaveRequest {
  const LeaveRequestModel({
    required super.id,
    super.requestId = '',
    super.employeeId = '',
    super.employeeName = '',
    super.attendanceId = '',
    required super.title,
    required super.requestType,
    required super.startDate,
    required super.endDate,
    required super.reason,
    required super.status,
    required super.submittedAt,
    super.requestedTimeOut,
    super.assignedApproverName,
    super.timeIn,
    super.timeOut,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    final idStr = (json['id'] ?? json['requestId'] ?? '').toString();
    final reqIdStr = json['requestId']?.toString() ?? idStr;
    final empName = json['employeeName']?.toString() ?? '';
    final empId = json['employeeId']?.toString() ?? '';
    final type = json['requestType']?.toString() ?? 'Leave';

    String titleStr = json['title']?.toString() ?? '';
    if (titleStr.isEmpty) {
      if (empName.isNotEmpty) {
        titleStr = '$empName - $type';
      } else {
        titleStr = 'Request #$idStr';
      }
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final startDate = parseDate(json['requestDate'] ?? json['startDate'] ?? json['createdAt']);
    final endDate = parseDate(json['requestDate'] ?? json['endDate'] ?? json['requestedTimeOut'] ?? json['createdAt']);
    final submittedAt = parseDate(json['createdAt'] ?? json['submittedAt']);

    return LeaveRequestModel(
      id: idStr,
      requestId: reqIdStr,
      employeeId: empId,
      employeeName: empName,
      attendanceId: json['attendanceId']?.toString() ?? '',
      title: titleStr,
      requestType: type,
      startDate: startDate,
      endDate: endDate,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      submittedAt: submittedAt,
      requestedTimeOut: json['requestedTimeOut']?.toString(),
      assignedApproverName: json['assignedApproverName']?.toString(),
      timeIn: json['timeIn']?.toString(),
      timeOut: json['timeOut']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'attendanceId': attendanceId,
      'title': title,
      'requestType': requestType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'requestedTimeOut': requestedTimeOut,
      'assignedApproverName': assignedApproverName,
      'timeIn': timeIn,
      'timeOut': timeOut,
    };
  }
}


