import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/attendance_record.dart';

class ExcelExportResult {
  final String filePath;
  final String fileName;
  final int recordCount;

  const ExcelExportResult({
    required this.filePath,
    required this.fileName,
    required this.recordCount,
  });
}

class ExcelExporter {
  /// Generates formatted Excel workbook bytes for attendance records
  static List<int> generateExcelBytes({
    required List<AttendanceRecord> records,
    required String dateRange,
    String? employeeName,
    String? employeeId,
  }) {
    if (records.isEmpty) {
      throw Exception('No attendance records available to export.');
    }

    final excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final Sheet sheet = excel[defaultSheet];

    // Header Styling
    final headerCellStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#002984'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Title Block
    sheet.appendRow([
      TextCellValue('ClientSite Attendance Report'),
    ]);
    sheet.appendRow([
      TextCellValue('Date Range: $dateRange'),
    ]);
    if (employeeName != null && employeeName.isNotEmpty) {
      sheet.appendRow([
        TextCellValue('Employee: $employeeName (${employeeId ?? "N/A"})'),
      ]);
    }
    sheet.appendRow([TextCellValue('')]); // Blank spacing row

    // Table Headers
    final headers = [
      'Date',
      'Work Type',
      'Check In',
      'Check Out',
      'Total Hours',
      'Status',
      'Location',
      'Description',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    final headerRowIndex =
        employeeName != null && employeeName.isNotEmpty ? 4 : 3;

    // Apply header style
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: headerRowIndex,
      ));
      cell.cellStyle = headerCellStyle;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    // Data Rows
    for (final record in records) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(record.date)),
        TextCellValue(record.workType),
        TextCellValue(
            record.checkInTime.isNotEmpty ? record.checkInTime : '--:--'),
        TextCellValue(
            record.checkOutTime != null && record.checkOutTime!.isNotEmpty
                ? record.checkOutTime!
                : '--:--'),
        TextCellValue('${record.totalHours.toStringAsFixed(1)} hrs'),
        TextCellValue(record.status),
        TextCellValue(record.location),
        TextCellValue(record.description),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Failed to generate Excel file bytes.');
    }
    return bytes;
  }

  /// Saves the Excel file directly to the device's public Downloads directory
  static Future<ExcelExportResult> downloadToDevice({
    required List<AttendanceRecord> records,
    required String dateRange,
    String? employeeName,
    String? employeeId,
  }) async {
    final bytes = generateExcelBytes(
      records: records,
      dateRange: dateRange,
      employeeName: employeeName,
      employeeId: employeeId,
    );

    final sanitizedRange = dateRange
        .replaceAll('/', '-')
        .replaceAll(' ', '_')
        .replaceAll(':', '-');
    final fileName = 'Attendance_Report_$sanitizedRange.xlsx';

    Directory? targetDir;

    if (Platform.isAndroid) {
      final androidDownload = Directory('/storage/emulated/0/Download');
      if (await androidDownload.exists()) {
        targetDir = androidDownload;
      } else {
        targetDir = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      targetDir = await getApplicationDocumentsDirectory();
    } else {
      targetDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }

    targetDir ??= await getApplicationDocumentsDirectory();

    final filePath = '${targetDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return ExcelExportResult(
      filePath: filePath,
      fileName: fileName,
      recordCount: records.length,
    );
  }

  /// Generates a temp file and opens the native Share sheet
  static Future<void> shareExcelReport({
    required List<AttendanceRecord> records,
    required String dateRange,
    String? employeeName,
    String? employeeId,
  }) async {
    final bytes = generateExcelBytes(
      records: records,
      dateRange: dateRange,
      employeeName: employeeName,
      employeeId: employeeId,
    );

    final tempDir = await getTemporaryDirectory();
    final sanitizedRange = dateRange
        .replaceAll('/', '-')
        .replaceAll(' ', '_')
        .replaceAll(':', '-');
    final fileName = 'Attendance_Report_$sanitizedRange.xlsx';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Attendance Report ($dateRange)',
    );
  }

  /// Opens the downloaded file in Microsoft Excel, Google Sheets, etc.
  static Future<OpenResult> openFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }
}
