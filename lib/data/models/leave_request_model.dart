import '../../domain/entities/leave_request.dart';

class LeaveRequestModel extends LeaveRequest {
  const LeaveRequestModel({
    required super.id,
    required super.title,
    required super.requestType,
    required super.startDate,
    required super.endDate,
    required super.reason,
    required super.status,
    required super.submittedAt,
    super.employeeName,
    super.employeeId,
    super.requestId,
    super.requestedTimeOut,
    super.assignedApproverName,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedStartDate = DateTime.now();
    DateTime parsedEndDate = DateTime.now();
    DateTime parsedSubmittedAt = DateTime.now();

    final rawStartDate = json['requestDate'] ?? json['startDate'] ?? json['createdAt'];
    if (rawStartDate != null) {
      parsedStartDate = DateTime.tryParse(rawStartDate.toString()) ?? DateTime.now();
    }

    final rawEndDate = json['endDate'] ?? json['requestedTimeOut'] ?? rawStartDate;
    if (rawEndDate != null) {
      parsedEndDate = DateTime.tryParse(rawEndDate.toString()) ?? parsedStartDate;
    }

    final rawCreatedAt = json['createdAt'] ?? json['submittedAt'];
    if (rawCreatedAt != null) {
      parsedSubmittedAt = DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
    }

    final empName = json['employeeName']?.toString();
    final reqType = (json['requestType'] ?? 'Leave').toString();
    String calculatedTitle = json['title']?.toString() ?? '';
    if (calculatedTitle.isEmpty) {
      if (empName != null && empName.isNotEmpty) {
        calculatedTitle = '$empName - $reqType Request';
      } else {
        calculatedTitle = '$reqType Request';
      }
    }

    String rawStatus = (json['status'] ?? 'Pending').toString();
    String normalizedStatus = rawStatus;
    if (rawStatus.toUpperCase() == 'PENDING') {
      normalizedStatus = 'Pending';
    } else if (rawStatus.toUpperCase() == 'APPROVED') {
      normalizedStatus = 'Approved';
    } else if (rawStatus.toUpperCase() == 'REJECTED') {
      normalizedStatus = 'Rejected';
    }

    return LeaveRequestModel(
      id: (json['id'] ?? json['requestId'] ?? 'req_${parsedStartDate.millisecondsSinceEpoch}').toString(),
      title: calculatedTitle,
      requestType: reqType,
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      reason: (json['reason'] ?? '').toString(),
      status: normalizedStatus,
      submittedAt: parsedSubmittedAt,
      employeeName: empName,
      employeeId: json['employeeId']?.toString(),
      requestId: json['requestId']?.toString(),
      requestedTimeOut: json['requestedTimeOut']?.toString(),
      assignedApproverName: json['assignedApproverName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'requestType': requestType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'employeeName': employeeName,
      'employeeId': employeeId,
      'requestId': requestId,
      'requestedTimeOut': requestedTimeOut,
      'assignedApproverName': assignedApproverName,
    };
  }
}

