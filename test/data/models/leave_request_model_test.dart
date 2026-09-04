import 'package:client_attendence/data/models/leave_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeaveRequestModel', () {
    test('should parse backend JSON response correctly', () {
      final json = {
        "id": 12,
        "requestId": "REQD0A86734",
        "employeeId": "20173",
        "employeeName": "Saheed Ansari",
        "attendanceId": "ATT63249DED",
        "requestType": "WFH",
        "requestDate": "2026-09-04",
        "status": "PENDING",
        "requestedTimeOut": "2026-09-04T11:24:42",
        "reason": "hub",
        "assignedApproverRole": "ADMIN",
        "assignedApproverEmployeeId": null,
        "assignedApproverName": "Administrator",
        "createdAt": "2026-09-04T11:22:58",
        "updatedAt": "2026-09-04T11:24:42"
      };

      final model = LeaveRequestModel.fromJson(json);

      expect(model.id, "12");
      expect(model.requestId, "REQD0A86734");
      expect(model.employeeName, "Saheed Ansari");
      expect(model.employeeId, "20173");
      expect(model.requestType, "WFH");
      expect(model.status, "Pending");
      expect(model.reason, "hub");
      expect(model.assignedApproverName, "Administrator");
      expect(model.requestedTimeOut, "2026-09-04T11:24:42");
    });
  });
}
