import 'package:client_attendence/data/models/attendance_record_model.dart';
import 'package:client_attendence/data/models/user_model.dart';
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

  group('UserModel', () {
    test('should parse backend JSON with timeInDescription and timeOutDescription successfully', () {
      final json = {
        "token": "3bbdb5fd4b9b4a43a724b8085a42a6de",
        "username": "2020",
        "employeeId": "2020",
        "fullName": "Unil Gandhi",
        "role": "RM",
        "firstLogin": false,
        "location": {
          "id": 1,
          "locationId": "001",
          "clientName": "Deva Interprices",
          "locationName": "Deva Int",
          "address": "Pune",
          "latitude": 18.58742586542344,
          "longitude": 73.73845322922567,
          "allowedRadius": 100.0,
          "status": "Active",
          "createdAt": "2026-09-02T10:30:32",
          "updatedAt": "2026-09-07T12:42:11"
        },
        "timeIn": "2026-09-10T11:11:44",
        "timeOut": "2026-09-10T12:02:09",
        "totalHours": "00:50",
        "attendanceType": "WFH",
        "timeInDescription": "vyvyvtvt",
        "timeOutDescription": null
      };

      final user = UserModel.fromJson(json);

      expect(user.id, "2020");
      expect(user.name, "Unil Gandhi");
      expect(user.role, "RM");
      expect(user.attendanceType, "WFH");
      expect(user.timeIn, "2026-09-10T11:11:44");
      expect(user.timeOut, "2026-09-10T12:02:09");
      expect(user.totalHours, "00:50");
      expect(user.timeInDescription, "vyvyvtvt");
      expect(user.timeOutDescription, isNull);

      final userJson = user.toJson();
      expect(userJson['timeInDescription'], "vyvyvtvt");
      expect(userJson['timeOutDescription'], isNull);
    });
  });
}
