import 'package:client_attendence/data/models/attendance_record_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceRecordModel', () {
    test('should parse backend JSON with string totalHours and ISO timestamps successfully', () {
      final json = {
        "id": 8,
        "attendanceId": "ATT991A51DA",
        "employeeId": "20173",
        "employeeName": "Saheed Ansari",
        "attendanceDate": "2026-09-03",
        "attendanceType": "WFH",
        "timeIn": "2026-09-03T11:54:25",
        "timeOut": "2026-09-03T11:54:30",
        "totalHours": "00:00",
        "attendanceStatus": "PRESENT",
        "requestStatus": "APPROVED",
        "requestId": "REQ7AE7A960",
        "createdAt": "2026-09-03T11:54:25",
        "updatedAt": "2026-09-04T11:05:57"
      };

      final model = AttendanceRecordModel.fromJson(json);

      expect(model.id, "ATT991A51DA");
      expect(model.workType, "WFH");
      expect(model.status, "PRESENT");
      expect(model.totalHours, 0.0);
      expect(model.checkInTime.contains('11:54'), true);
      expect(model.checkOutTime?.contains('11:54'), true);
    });

    test('should parse numeric totalHours and standard time strings', () {
      final json = {
        "id": "att_001",
        "date": "2026-09-01T09:00:00",
        "checkInTime": "09:00 AM",
        "checkOutTime": "05:30 PM",
        "workType": "GPS",
        "location": "HQ",
        "description": "Work",
        "totalHours": 8.5,
        "status": "Present"
      };

      final model = AttendanceRecordModel.fromJson(json);

      expect(model.id, "att_001");
      expect(model.totalHours, 8.5);
      expect(model.checkInTime, "09:00 AM");
      expect(model.checkOutTime, "05:30 PM");
    });
  });
}
