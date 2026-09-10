import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/excel_exporter.dart';
import '../../domain/entities/attendance_record.dart';
import '../blocs/attendance/attendance_bloc.dart';
import '../blocs/attendance/attendance_event.dart';
import '../blocs/attendance/attendance_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/leave/leave_bloc.dart';
import '../blocs/leave/leave_event.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Dropdown State
  String _selectedPeriod = 'This Month';
  final List<String> _periodOptions = ['This Month', 'Last Month', 'Custom'];

  // Date Pickers State
  late DateTime _fromDate;
  late DateTime _toDate;
  String _displayRangeStr = '';
  bool _isExporting = false;

  bool get _isAdmin {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return authState.user.role.trim().toUpperCase() == 'ADMIN';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    // For non-admin, default to yesterday if today is 1st or past yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    _toDate = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isAdmin && _toDate.year == now.year && _toDate.month == now.month && _toDate.day == now.day) {
        if (yesterday.isBefore(_fromDate)) {
          _fromDate = yesterday;
        }
        _toDate = yesterday;
      }
      _applyPeriod('This Month');
    });
  }

  void _applyPeriod(String period) {
    final now = DateTime.now();
    String startParam;
    String endParam;

    if (period == 'This Month') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      startParam = DateFormat('yyyy-MM-dd').format(start);
      endParam = DateFormat('yyyy-MM-dd').format(end);
      setState(() {
        _displayRangeStr =
            "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}";
      });
    } else if (period == 'Last Month') {
      final start = DateTime(now.year, now.month - 1, 1);
      final end = DateTime(now.year, now.month, 0);
      startParam = DateFormat('yyyy-MM-dd').format(start);
      endParam = DateFormat('yyyy-MM-dd').format(end);
      setState(() {
        _displayRangeStr =
            "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}";
      });
    } else {
      // Custom Range
      startParam = DateFormat('yyyy-MM-dd').format(_fromDate);
      endParam = DateFormat('yyyy-MM-dd').format(_toDate);
      setState(() {
        _displayRangeStr =
            "${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}";
      });
    }

    context.read<AttendanceBloc>().add(
          LoadAttendanceHistoryEvent(
            startDate: startParam,
            endDate: endParam,
          ),
        );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Admin has no restriction; RM and Employee cannot select current date (last selectable date is yesterday)
    final DateTime maxSelectableDate = _isAdmin ? DateTime(2035) : yesterday;

    DateTime initialDate = isFromDate ? _fromDate : _toDate;
    if (initialDate.isAfter(maxSelectableDate)) {
      initialDate = maxSelectableDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: maxSelectableDate,
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
          if (_fromDate.isAfter(_toDate)) {
            _fromDate = _toDate;
          }
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _onExportPressed() {
    final attendanceState = context.read<AttendanceBloc>().state;
    final records = attendanceState is AttendanceLoadedState
        ? attendanceState.history
        : <AttendanceRecord>[];

    if (records.isEmpty) {
      SnackbarHelper.showWarning(
        context,
        'No attendance records available to export for this period.',
      );
      return;
    }

    _showExportModal(context, records);
  }

  void _showExportModal(BuildContext context, List<AttendanceRecord> records) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthenticatedState ? authState.user : null;
    final dateRange = _displayRangeStr.isNotEmpty ? _displayRangeStr : _selectedPeriod;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Export Attendance Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Includes ${records.length} record(s) for $dateRange',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Option 1: Download directly to device
                InkWell(
                  onTap: () async {
                    Navigator.of(modalCtx).pop();
                    await _handleDirectDownload(records, dateRange, user?.name, user?.id);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            color: AppColors.primaryNavy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Download to Device',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Save .xlsx file to Downloads folder',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: Share file via system share
                InkWell(
                  onTap: () async {
                    Navigator.of(modalCtx).pop();
                    await _handleShareReport(records, dateRange, user?.name, user?.id);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.successEmerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: AppColors.successEmerald,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Excel File',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Send via WhatsApp, Email, Google Drive, etc.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDirectDownload(
    List<AttendanceRecord> records,
    String dateRange,
    String? employeeName,
    String? employeeId,
  ) async {
    setState(() => _isExporting = true);
    try {
      final result = await ExcelExporter.downloadToDevice(
        records: records,
        dateRange: dateRange,
        employeeName: employeeName,
        employeeId: employeeId,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Downloaded: ${result.fileName}',
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () {
              ExcelExporter.openFile(result.filePath);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to download file: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleShareReport(
    List<AttendanceRecord> records,
    String dateRange,
    String? employeeName,
    String? employeeId,
  ) async {
    setState(() => _isExporting = true);
    try {
      await ExcelExporter.shareExcelReport(
        records: records,
        dateRange: dateRange,
        employeeName: employeeName,
        employeeId: employeeId,
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to share file: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = AppColors.primaryNavy;

    return RefreshIndicator(
      onRefresh: () async {
        _applyPeriod(_selectedPeriod);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Export Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Log',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : _onExportPressed,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryNavy),
                          ),
                        )
                      : const Icon(Icons.download, size: 16, color: primaryNavy),
                  label: Text(
                    _isExporting ? 'Exporting...' : 'Export',
                    style: const TextStyle(
                      color: primaryNavy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF2FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Dropdown and Date Range Info
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF475569)),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPeriod = newValue;
                            if (newValue == 'Custom' && !_isAdmin) {
                              final now = DateTime.now();
                              final yesterday = now.subtract(const Duration(days: 1));
                              if (!_toDate.isBefore(now)) {
                                _toDate = yesterday;
                              }
                              if (_fromDate.isAfter(_toDate)) {
                                _fromDate = _toDate;
                              }
                            }
                          });
                          _applyPeriod(newValue);
                        }
                      },
                      items: _periodOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_displayRangeStr.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _displayRangeStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Conditional Date Range Card (Displayed ONLY when 'Custom' is selected)
            if (_selectedPeriod == 'Custom') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Date Range',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = 'This Month';
                            });
                            _applyPeriod('This Month');
                          },
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Color(0xFFCBD5E1),
                            child: Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FROM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectDate(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDF2F7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: Color(0xFF64748B)),
                                      Text(
                                        _formatDate(_fromDate),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1E293B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_month,
                                          size: 16, color: Color(0xFF1E293B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectDate(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDF2F7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: Color(0xFF64748B)),
                                      Text(
                                        _formatDate(_toDate),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1E293B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_month,
                                          size: 16, color: Color(0xFF1E293B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () => _applyPeriod('Custom'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bloc Consumer for Stats and Attendance List
            BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                List<AttendanceRecord> records = [];
                if (state is AttendanceLoadedState) {
                  records = state.history;
                }

                int presentCount = records.where((r) {
                  final s = r.status.toLowerCase();
                  return s == 'present' || s == 'half day' || (!s.contains('absent') && !s.contains('leave'));
                }).length;

                int wfhCount = records.where((r) {
                  return r.workType.toUpperCase() == 'WFH';
                }).length;

                int absentCount = records.where((r) {
                  final s = r.status.toLowerCase();
                  return s.contains('absent') || s.contains('leave');
                }).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Stats Card
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildStatItem(
                              '$presentCount', 'Present', const Color(0xFF2563EB)),
                          _buildDivider(),
                          _buildStatItem(
                              '$wfhCount', 'WFH', const Color(0xFF1E293B)),
                          _buildDivider(),
                          _buildStatItem(
                              '$absentCount', 'Absent', const Color(0xFFDC2626)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (state is AttendanceLoadingState) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: primaryNavy),
                              SizedBox(height: 12),
                              Text(
                                'Loading attendance history...',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (state is AttendanceErrorState) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.message,
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _applyPeriod(_selectedPeriod),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (records.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 48, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_outlined,
                                size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'No attendance records found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            // SizedBox(height: 6),
                            // Text(
                            //   'No attendance data found for the selected date range.',
                            //   textAlign: TextAlign.center,
                            //   style: TextStyle(
                            //     fontSize: 13,
                            //     color: Color(0xFF64748B),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Attendance Logs List
                      ...records.map((record) => _buildRecordCard(record, primaryNavy)),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(AttendanceRecord record, Color primaryNavy) {
    final now = DateTime.now();
    final isToday = now.year == record.date.year &&
        now.month == record.date.month &&
        now.day == record.date.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == record.date.year &&
        yesterday.month == record.date.month &&
        yesterday.day == record.date.day;

    final dayLabel = isToday
        ? 'TODAY'
        : isYesterday
            ? 'YESTERDAY'
            : DateFormat('EEE').format(record.date).toUpperCase();
    final dateStr = DateFormat('MMM dd, yyyy').format(record.date);

    final statusLower = record.status.toLowerCase();
    final isAbsent = statusLower.contains('absent') || statusLower.contains('leave');
    final isWFH = record.workType.toUpperCase() == 'WFH';
    final isHalfDay = statusLower.contains('half');
    final isIncomplete = statusLower.contains('incomplete');

    Color accentColor = const Color(0xFF2563EB); // Present
    Widget statusBadge;

    if (isAbsent) {
      accentColor = const Color(0xFFDC2626);
      statusBadge = _buildStatusBadge(
        label: 'Absent',
        icon: Icons.cancel_outlined,
        bgColor: const Color(0xFFFEE2E2),
        textColor: const Color(0xFFB91C1C),
      );
    } else if (isIncomplete) {
      accentColor = const Color(0xFFD97706);
      statusBadge = _buildStatusBadge(
        label: 'Incomplete',
        icon: Icons.pending_outlined,
        bgColor: const Color(0xFFFEF3C7),
        textColor: const Color(0xFFB45309),
      );
    } else if (isHalfDay) {
      accentColor = const Color(0xFF475569);
      statusBadge = _buildStatusBadge(
        label: 'Half Day',
        icon: Icons.timelapse,
        bgColor: const Color(0xFFE0E7FF),
        textColor: primaryNavy,
      );
    } else {
      // Both Office and WFH show "Present" status badge when complete
      accentColor = const Color(0xFF2563EB);
      statusBadge = _buildStatusBadge(
        label: 'Present',
        icon: Icons.check_circle_outline,
        bgColor: const Color(0xFFDCFCE7),
        textColor: const Color(0xFF15803D),
      );
    }

    final locationStr = record.location.isNotEmpty
        ? record.location
        : (isWFH ? 'Remote Setup (Home Office)' : 'HQ Office');

    final hasNoOutTime = (record.checkOutTime == null ||
        record.checkOutTime!.isEmpty ||
        record.checkOutTime == '--:--');

    Widget? customOutWidget;
    VoidCallback? onCardTap;

    if (hasNoOutTime && !isAbsent) {
      if (isToday) {
        // For current date, show standard '-' icon & dash
        customOutWidget = const Row(
          children: [
            Icon(Icons.logout_rounded, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text(
              '--:--',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        );
      } else {
        // Check if within 48 working hours (excluding Sat & Sun)
        final isEligible = _isEligibleForRegularization(record.date);
        if (isEligible) {
          onCardTap = () => _showRegularizationModal(context, record);
          customOutWidget = const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 16,
                color: AppColors.dangerRose,
              ),
              SizedBox(width: 4),
              Text(
                '--:--',
                style: TextStyle(
                  color: AppColors.dangerRose,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          );
        } else {
          // For past dates beyond 48 business hours
          customOutWidget = const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFFDC2626)),
              SizedBox(width: 4),
              Text(
                'Missing Out',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          );
        }
      }
    }

    return _buildAttendanceCard(
      accentColor: accentColor,
      dayLabel: dayLabel,
      dateStr: dateStr,
      clientStr: locationStr,
      statusBadge: statusBadge,
      inTime: record.checkInTime,
      outTime: record.checkOutTime,
      isNoRecord: isAbsent,
      isWFH: isWFH,
      customOutWidget: customOutWidget,
      onTap: onCardTap,
    );
  }

  // Summary Stat Helper
  Widget _buildStatItem(String count, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFCBD5E1),
    );
  }

  // Status Badge Builder
  Widget _buildStatusBadge({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Card Item Builder
  Widget _buildAttendanceCard({
    required Color accentColor,
    required String dayLabel,
    required String dateStr,
    required String clientStr,
    required Widget statusBadge,
    String? inTime,
    String? outTime,
    Widget? customOutWidget,
    bool isNoRecord = false,
    bool isWFH = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dayLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            statusBadge,
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          clientStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isNoRecord)
                          const Row(
                            children: [
                              Text(
                                '—  ',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                              Text(
                                'No Record',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.login_rounded,
                                      size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    inTime ?? '--:--',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Container(
                                      height: 12,
                                      width: 1,
                                      color: const Color(0xFFCBD5E1)),
                                  const SizedBox(width: 14),
                                  if (customOutWidget != null)
                                    customOutWidget
                                  else ...[
                                    const Icon(Icons.logout_rounded,
                                        size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      outTime ?? '--:--',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // Bottom-right Office or WFH badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isWFH
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isWFH
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFFC7D2FE),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isWFH ? Icons.home_work_outlined : Icons.business_rounded,
                                      size: 13,
                                      color: isWFH
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF1E40AF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isWFH ? 'WFH' : 'Office',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isWFH
                                            ? const Color(0xFFB45309)
                                            : const Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isEligibleForRegularization(DateTime recordDate) {
    final now = DateTime.now();
    // If record date is today or in future, no regularization needed
    final today = DateTime(now.year, now.month, now.day);
    final recDay = DateTime(recordDate.year, recordDate.month, recordDate.day);
    if (!recDay.isBefore(today)) return false;

    // Calculate elapsed working hours (skipping Saturday and Sunday)
    int workingHours = 0;
    DateTime current = DateTime(recordDate.year, recordDate.month, recordDate.day, 23, 59, 59);

    while (current.isBefore(now)) {
      current = current.add(const Duration(hours: 1));
      if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
        workingHours++;
      }
    }

    return workingHours <= 48;
  }

  void _showRegularizationModal(BuildContext parentContext, AttendanceRecord record) {
    final dateStr = DateFormat('MMM dd, yyyy').format(record.date);
    TimeOfDay? selectedOutTime;
    String? selectedReasonOption;
    final List<String> reasonOptions = [
      'Forget To PunchIn',
      'Forget To PunchOut',
      'Out-of-office',
      'Medical Emergency',
      'Others',
    ];
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedTime = selectedOutTime != null
                ? selectedOutTime!.format(context)
                : null;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: AppColors.primaryNavy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Regularization',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Submit clock-out for missing attendance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Attendance Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                          Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Time In', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(record.checkInTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Out Selector
                    const Text(
                      'Select Time Out *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedOutTime ?? const TimeOfDay(hour: 18, minute: 0),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedOutTime = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedTime ?? 'Choose Time Out (e.g. 06:00 PM)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: formattedTime != null ? FontWeight.bold : FontWeight.w500,
                                color: formattedTime != null ? AppColors.textDark : AppColors.textLight,
                              ),
                            ),
                            const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primaryNavy),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason Category Dropdown
                    const Text(
                      'Select Reason *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedReasonOption,
                          isExpanded: true,
                          hint: const Text(
                            'Select reason for regularizing',
                            style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w500),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryNavy),
                          items: reasonOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? val) {
                            setModalState(() {
                              selectedReasonOption = val;
                            });
                          },
                        ),
                      ),
                    ),

                    // Reason Field (Visible only when 'Others' is selected)
                    if (selectedReasonOption == 'Others') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Reason for Regularization *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: 'Please specify the reason...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.borderGrey),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Action Buttons (Equal width)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(modalCtx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.borderGrey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedOutTime == null) {
                                SnackbarHelper.showWarning(
                                  parentContext,
                                  'Please select your Time Out',
                                );
                                return;
                              }

                              if (selectedReasonOption == null) {
                                SnackbarHelper.showWarning(
                                  parentContext,
                                  'Please select a reason',
                                );
                                return;
                              }

                              String finalReason = selectedReasonOption!;
                              if (selectedReasonOption == 'Others') {
                                final customReason = reasonController.text.trim();
                                if (customReason.isEmpty) {
                                  SnackbarHelper.showWarning(
                                    parentContext,
                                    'Please enter reason for regularization',
                                  );
                                  return;
                                }
                                finalReason = 'Others: $customReason';
                              }

                              Navigator.of(modalCtx).pop();

                              // Submit Regularization Leave Request
                              parentContext.read<LeaveBloc>().add(
                                    SubmitLeaveRequestEvent(
                                      title: 'Regularization - $dateStr',
                                      requestType: 'ADJUSTMENT',
                                      startDate: record.date,
                                      endDate: record.date,
                                      reason: 'Time Out: $formattedTime | $finalReason',
                                    ),
                                  );
                            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text(
              'Submit Request',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    ),
  ],
),
              ),
            );
          },
        );
      },
    );
  }
}
