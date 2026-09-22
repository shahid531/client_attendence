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

    if (Platform.isAndroid) {
      // 1. Try public Download directory
      try {
        final androidDownload = Directory('/storage/emulated/0/Download');
        if (await androidDownload.exists()) {
          final file = File('${androidDownload.path}/$fileName');
          await file.writeAsBytes(bytes, flush: true);
          return ExcelExportResult(filePath: file.path, fileName: fileName);
        }
      } catch (_) {
        // Scoped storage permission restricted, fallback below
      }

      // 2. Try App external downloads directory
      try {
        final extDirs =
            await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          final file = File('${extDirs.first.path}/$fileName');
          await file.writeAsBytes(bytes, flush: true);
          return ExcelExportResult(filePath: file.path, fileName: fileName);
        }
      } catch (_) {}

      // 3. Try App external files directory
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final file = File('${extDir.path}/$fileName');
          await file.writeAsBytes(bytes, flush: true);
          return ExcelExportResult(filePath: file.path, fileName: fileName);
        }
      } catch (_) {}
    }

    final Directory targetDir;

    if (Platform.isIOS) {
      targetDir = await getApplicationDocumentsDirectory();
    } else {
      targetDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }

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
