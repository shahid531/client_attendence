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
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      requestType: json['requestType'] as String? ?? 'Leave',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      submittedAt: DateTime.parse(json['submittedAt'] as String),
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
    };
  }
}
