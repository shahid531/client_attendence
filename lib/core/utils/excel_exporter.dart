import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportResult {
  final String filePath;
  final String fileName;

  const ExcelExportResult({
    required this.filePath,
    required this.fileName,
  });
}

class ExcelExporter {
  /// Saves Excel binary bytes directly to the device's Downloads directory
  static Future<ExcelExportResult> saveBytesToDownloads({
    required List<int> bytes,
    String? employeeId,
    String? dateRange,
    String? fromDate,
    String? toDate,
  }) async {
    final rangeText = dateRange ?? '${fromDate ?? "start"}_to_${toDate ?? "end"}';
    final sanitizedRange = rangeText
        .replaceAll('/', '-')
        .replaceAll(' ', '_')
        .replaceAll(':', '-');
    final empPrefix = (employeeId != null && employeeId.isNotEmpty) ? '${employeeId}_' : '';
    final fileName = 'Attendance_Report_$empPrefix$sanitizedRange.xlsx';

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
    );
  }

  /// Generates a temp file from bytes and opens the native Share sheet
  static Future<void> shareBytes({
    required List<int> bytes,
    String? employeeId,
    String? dateRange,
    String? fromDate,
    String? toDate,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final rangeText = dateRange ?? '${fromDate ?? "start"}_to_${toDate ?? "end"}';
    final sanitizedRange = rangeText
        .replaceAll('/', '-')
        .replaceAll(' ', '_')
        .replaceAll(':', '-');
    final empPrefix = (employeeId != null && employeeId.isNotEmpty) ? '${employeeId}_' : '';
    final fileName = 'Attendance_Report_$empPrefix$sanitizedRange.xlsx';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Attendance Report (${dateRange ?? "$fromDate - $toDate"})',
    );
  }

  /// Opens the downloaded file in Microsoft Excel, Google Sheets, etc.
  static Future<OpenResult> openFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }
}
