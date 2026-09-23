import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/excel_exporter.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/created_employee.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
import '../blocs/attendance/attendance_bloc.dart';
import '../blocs/attendance/attendance_event.dart';
import '../blocs/attendance/attendance_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Dropdown State
  String _selectedPeriod = 'Today';
  final List<String> _periodOptions = ['Today', 'This Month', 'Last Month', 'Custom'];

  // Date Pickers State
  DateTime? _customFromDate;
  DateTime? _customToDate;
  String _displayRangeStr = '';

  // Pagination State
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  // Selected Employee filter (Admin only)
  CreatedEmployee? _selectedEmployee;

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
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAdmin) {
        context.read<AdminBloc>().add(const LoadEmployeesEvent());
      }
      _applyPeriod('Today');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final state = context.read<AttendanceBloc>().state;
    if (state is AttendanceLoadedState &&
        !state.isLoadingMore &&
        state.hasNext) {
      _applyPeriod(_selectedPeriod, page: state.page + 1, isLoadMore: true);
    }
  }

  void _applyPeriod(String period, {int page = 0, bool isLoadMore = false}) {
    final now = DateTime.now();
    String? startParam;
    String? endParam;

    if (period == 'Today') {
      final today = DateTime(now.year, now.month, now.day);
      startParam = DateFormat('yyyy-MM-dd').format(today);
      endParam = DateFormat('yyyy-MM-dd').format(today);
      if (!isLoadMore) {
        setState(() {
          _displayRangeStr = DateFormat('dd/MM/yyyy').format(today);
        });
      }
    } else if (period == 'This Month') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      startParam = DateFormat('yyyy-MM-dd').format(start);
      endParam = DateFormat('yyyy-MM-dd').format(end);
      if (!isLoadMore) {
        setState(() {
          _displayRangeStr =
              "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}";
        });
      }
    } else if (period == 'Last Month') {
      final start = DateTime(now.year, now.month - 1, 1);
      final end = DateTime(now.year, now.month, 0);
      startParam = DateFormat('yyyy-MM-dd').format(start);
      endParam = DateFormat('yyyy-MM-dd').format(end);
      if (!isLoadMore) {
        setState(() {
          _displayRangeStr =
              "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}";
        });
      }
    } else {
      // Custom Range - only pass dates if explicitly selected by user
      if (_customFromDate != null) {
        startParam = DateFormat('yyyy-MM-dd').format(_customFromDate!);
      }
      if (_customToDate != null) {
        endParam = DateFormat('yyyy-MM-dd').format(_customToDate!);
      }
      if (!isLoadMore) {
        setState(() {
          if (_customFromDate != null && _customToDate != null) {
            _displayRangeStr =
                "${DateFormat('dd/MM/yyyy').format(_customFromDate!)} - ${DateFormat('dd/MM/yyyy').format(_customToDate!)}";
          } else if (_customFromDate != null) {
            _displayRangeStr =
                "From ${DateFormat('dd/MM/yyyy').format(_customFromDate!)}";
          } else if (_customToDate != null) {
            _displayRangeStr =
                "To ${DateFormat('dd/MM/yyyy').format(_customToDate!)}";
          } else {
            _displayRangeStr = '';
          }
        });
      }
    }

    String? employeeId;
    String? employeeName;
    if (_isAdmin) {
      if (_selectedEmployee != null) {
        employeeId = _selectedEmployee!.employeeId;
        employeeName = _selectedEmployee!.fullName;
      }
    }

    context.read<AttendanceBloc>().add(
          LoadAttendanceHistoryEvent(
            startDate: startParam,
            endDate: endParam,
            page: page,
            size: _pageSize,
            employeeId: employeeId,
            employeeName: employeeName,
            isLoadMore: isLoadMore,
          ),
        );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Admin has no restriction; RM and Employee cannot select current date (last selectable date is yesterday)
    final DateTime maxSelectableDate = _isAdmin ? DateTime(2035) : yesterday;

    DateTime initialDate = isFromDate
        ? (_customFromDate ?? (_customToDate ?? (_isAdmin ? now : yesterday)))
        : (_customToDate ?? (_customFromDate ?? (_isAdmin ? now : yesterday)));
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
          _customFromDate = picked;
          if (_customToDate != null && _customToDate!.isBefore(_customFromDate!)) {
            _customToDate = _customFromDate;
          }
        } else {
          _customToDate = picked;
          if (_customFromDate != null && _customFromDate!.isAfter(_customToDate!)) {
            _customFromDate = _customToDate;
          }
        }
      });
      _applyPeriod('Custom', page: 0);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  (String, String) _getExportDateParams() {
    final now = DateTime.now();
    if (_selectedPeriod == 'Today') {
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      return (todayStr, todayStr);
    } else if (_selectedPeriod == 'This Month') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return (
        DateFormat('yyyy-MM-dd').format(start),
        DateFormat('yyyy-MM-dd').format(end),
      );
    } else if (_selectedPeriod == 'Last Month') {
      final start = DateTime(now.year, now.month - 1, 1);
      final end = DateTime(now.year, now.month, 0);
      return (
        DateFormat('yyyy-MM-dd').format(start),
        DateFormat('yyyy-MM-dd').format(end),
      );
    } else {
      final fromStr = _customFromDate != null
          ? DateFormat('yyyy-MM-dd').format(_customFromDate!)
          : '';
      final toStr = _customToDate != null
          ? DateFormat('yyyy-MM-dd').format(_customToDate!)
          : '';
      return (fromStr, toStr);
    }
  }

  (String?, String?) _getExportSearchParams() {
    if (_isAdmin) {
      if (_selectedEmployee != null) {
        return (_selectedEmployee!.employeeId, _selectedEmployee!.fullName);
      }
      return (null, null);
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return (authState.user.id, null);
    }
    return (null, null);
  }

  void _onExportPressed() {
    _showExportModal(context);
  }

  void _showExportModal(BuildContext context) {
    final dateRange =
        _displayRangeStr.isNotEmpty ? _displayRangeStr : _selectedPeriod;
    final (fromDate, toDate) = _getExportDateParams();
    final (employeeId, search) = _getExportSearchParams();

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
                  'Exporting attendance records for $dateRange',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Option 1: Download directly to device
                InkWell(
                  onTap: () {
                    Navigator.of(modalCtx).pop();
                    _handleDirectDownload(
                      employeeId: employeeId,
                      search: search,
                      fromDate: fromDate,
                      toDate: toDate,
                      dateRange: dateRange,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                  onTap: () {
                    Navigator.of(modalCtx).pop();
                    _handleShareReport(
                      employeeId: employeeId,
                      search: search,
                      fromDate: fromDate,
                      toDate: toDate,
                      dateRange: dateRange,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                            color:
                                AppColors.successEmerald.withValues(alpha: 0.1),
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

  void _handleDirectDownload({
    String? employeeId,
    String? search,
    required String fromDate,
    required String toDate,
    required String dateRange,
  }) {
    context.read<AttendanceBloc>().add(
          ExportAttendanceEvent(
            employeeId: employeeId,
            search: search,
            fromDate: fromDate,
            toDate: toDate,
            dateRange: dateRange,
            action: ExportAction.download,
          ),
        );
  }

  void _handleShareReport({
    String? employeeId,
    String? search,
    required String fromDate,
    required String toDate,
    required String dateRange,
  }) {
    context.read<AttendanceBloc>().add(
          ExportAttendanceEvent(
            employeeId: employeeId,
            search: search,
            fromDate: fromDate,
            toDate: toDate,
            dateRange: dateRange,
            action: ExportAction.share,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = AppColors.primaryNavy;
    final attendanceState = context.watch<AttendanceBloc>().state;
    final isExporting =
        attendanceState is AttendanceLoadedState && attendanceState.isExporting;

    return RefreshIndicator(
      onRefresh: () async {
        _applyPeriod(_selectedPeriod);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
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
                _buildExportButton(
                  isExporting: isExporting,
                  primaryNavy: primaryNavy,
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
                            if (newValue == 'Custom') {
                              _customFromDate = null;
                              _customToDate = null;
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
                      color: Colors.black.withValues(alpha: 0.04),
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
                              _customFromDate = null;
                              _customToDate = null;
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
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 16, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _customFromDate != null
                                              ? _formatDate(_customFromDate!)
                                              : 'Select Date',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _customFromDate != null
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFF94A3B8),
                                            fontWeight: _customFromDate != null
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (_customFromDate != null)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _customFromDate = null;
                                            });
                                            _applyPeriod('Custom', page: 0);
                                          },
                                          child: const Icon(Icons.close_rounded,
                                              size: 16, color: Color(0xFF64748B)),
                                        )
                                      else
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
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 16, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _customToDate != null
                                              ? _formatDate(_customToDate!)
                                              : 'Select Date',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _customToDate != null
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFF94A3B8),
                                            fontWeight: _customToDate != null
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (_customToDate != null)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _customToDate = null;
                                            });
                                            _applyPeriod('Custom', page: 0);
                                          },
                                          child: const Icon(Icons.close_rounded,
                                              size: 16, color: Color(0xFF64748B)),
                                        )
                                      else
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
                    if (_isAdmin) ...[
                      const SizedBox(height: 14),
                      _buildEmployeeSelector(context),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Employee Selector (Only visible to admin when NOT in Custom period)
            if (_isAdmin && _selectedPeriod != 'Custom') ...[
              _buildEmployeeSelector(context),
              const SizedBox(height: 16),
            ],

            // Bloc Consumer for Stats and Attendance List
            BlocConsumer<AttendanceBloc, AttendanceState>(
              listener: (context, state) {
                if (state is AttendanceLoadedState) {
                  if (state.exportResult != null) {
                    SnackbarHelper.showSuccess(
                      context,
                      'Downloaded: ${state.exportResult!.fileName}',
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'OPEN',
                        textColor: Colors.white,
                        onPressed: () {
                          ExcelExporter.openFile(state.exportResult!.filePath);
                        },
                      ),
                    );
                  } else if (state.exportErrorMessage != null &&
                      state.exportErrorMessage!.isNotEmpty) {
                    SnackbarHelper.showError(context, state.exportErrorMessage!);
                  } else if (state.successMessage != null &&
                      state.successMessage!.isNotEmpty) {
                    SnackbarHelper.showSuccess(context, state.successMessage!);
                    _applyPeriod(_selectedPeriod);
                  } else if (state.errorMessage != null &&
                      state.errorMessage!.isNotEmpty) {
                    SnackbarHelper.showError(context, state.errorMessage!);
                  }
                } else if (state is AttendanceErrorState) {
                  SnackbarHelper.showError(context, state.message);
                }
              },
              builder: (context, state) {
                int presentCount = 0;
                int wfhCount = 0;
                int officeCount = 0;
                final displayedRecords = state is AttendanceLoadedState
                    ? state.history
                    : const <AttendanceRecord>[];

                if (state is AttendanceLoadedState) {
                  presentCount = state.totalPresent;
                  wfhCount = state.totalWFH;
                  officeCount = state.totalOffice;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Stats Card (Visible ONLY when 'Today' is selected)
                    if (_selectedPeriod == 'Today') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _buildStatItem('$presentCount', 'Present',
                                const Color(0xFF2563EB)),
                            _buildDivider(),
                            _buildStatItem(
                                '$wfhCount', 'WFH', const Color(0xFF1E293B)),
                            _buildDivider(),
                            _buildStatItem('$officeCount', 'Office',
                                const Color(0xFF16A34A)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                    ] else if (displayedRecords.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 48, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_busy_outlined,
                                size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              _selectedEmployee != null
                                  ? 'No records found for ${_selectedEmployee!.fullName}'
                                  : 'No attendance records found',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Attendance Logs List
                      ...displayedRecords.map(
                          (record) => _buildRecordCard(record, primaryNavy)),

                      // Scroll Pagination Footer
                      if (state is AttendanceLoadedState)
                        _buildScrollPaginationFooter(state),
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

  Widget _buildEmployeeSelector(BuildContext context) {
    final adminState = context.watch<AdminBloc>().state;
    final hasSelection = _selectedEmployee != null;

    return InkWell(
      onTap: () => _openEmployeePicker(
        adminState.employees,
        adminState.isLoadingEmployees,
        adminState.employeesError,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSelection
                ? AppColors.primaryNavy.withValues(alpha: 0.5)
                : AppColors.borderGrey,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.groups_outlined,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasSelection
                  ? Row(
                      children: [
                        Flexible(
                          child: Text(
                            _selectedEmployee!.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ID: ${_selectedEmployee!.employeeId}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryNavy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Search / Select Employee',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
            ),
            if (hasSelection)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedEmployee = null;
                  });
                  _applyPeriod(_selectedPeriod, page: 0);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ),
              )
            else
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEmployeePicker(
    List<CreatedEmployee> employees,
    bool isLoadingEmployees,
    String? employeesError,
  ) async {
    if (employees.isEmpty && !isLoadingEmployees) {
      context.read<AdminBloc>().add(const LoadEmployeesEvent());
    }

    final result = await showModalBottomSheet<_HistoryEmployeeSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            return _HistoryEmployeeSearchModal(
              initialSelected: _selectedEmployee,
              employees: state.employees,
              isLoading: state.isLoadingEmployees,
              error: state.employeesError,
              onRetry: () {
                context
                    .read<AdminBloc>()
                    .add(const LoadEmployeesEvent(isRefresh: true));
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        if (result.isCleared) {
          _selectedEmployee = null;
        } else {
          _selectedEmployee = result.employee;
        }
      });
      _applyPeriod(_selectedPeriod, page: 0);
    }
  }

  Widget _buildExportButton({
    required bool isExporting,
    required Color primaryNavy,
  }) {
    return ElevatedButton.icon(
      onPressed: isExporting ? null : _onExportPressed,
      icon: isExporting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
              ),
            )
          : const Icon(Icons.download, size: 16, color: AppColors.primaryNavy),
      label: Text(
        isExporting ? 'Exporting...' : 'Export',
        style: const TextStyle(
          color: AppColors.primaryNavy,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildScrollPaginationFooter(AttendanceLoadedState state) {
    if (state.isLoadingMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Loading more records...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!state.hasNext && state.history.isNotEmpty) {
      final total =
          state.totalElements > 0 ? state.totalElements : state.history.length;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Text(
          'Showing all $total records',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return const SizedBox(height: 12);
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
    final isAbsent =
        statusLower.contains('absent') || statusLower.contains('leave');
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
      } else if (_isAdmin) {
        // For Admin viewing employee records, regularization is disabled
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
                'LWP',
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
      employeeName: record.employeeName,
      employeeId: record.employeeId,
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
    String? employeeName,
    String? employeeId,
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
            color: Colors.black.withValues(alpha: 0.02),
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
                        if (employeeName != null &&
                            employeeName.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  size: 14, color: Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$employeeName${employeeId != null && employeeId.trim().isNotEmpty ? " ($employeeId)" : ""}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
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
                                      isWFH
                                          ? Icons.home_work_outlined
                                          : Icons.business_rounded,
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
    if (_isAdmin) return false;

    final now = DateTime.now();
    // If record date is today or in future, no regularization needed
    final today = DateTime(now.year, now.month, now.day);
    final recDay = DateTime(recordDate.year, recordDate.month, recordDate.day);
    if (!recDay.isBefore(today)) return false;

    // Calculate elapsed working hours (skipping Saturday and Sunday)
    int workingHours = 0;
    DateTime current =
        DateTime(recordDate.year, recordDate.month, recordDate.day, 23, 59, 59);

    while (current.isBefore(now)) {
      current = current.add(const Duration(hours: 1));
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        workingHours++;
      }
    }

    return workingHours <= 48;
  }

  String _formatTimeOfDay12Hour(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _showRegularizationModal(
      BuildContext parentContext, AttendanceRecord record) {
    if (_isAdmin) return;

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
                ? _formatTimeOfDay12Hour(selectedOutTime!)
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
                            color: AppColors.primaryNavy.withValues(alpha: 0.08),
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
                                const Text('Date',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(dateStr,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark)),
                              ],
                            ),
                          ),
                          Container(
                              height: 24,
                              width: 1,
                              color: const Color(0xFFE2E8F0)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Time In',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(record.checkInTime,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark)),
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
                          initialTime: selectedOutTime ??
                              const TimeOfDay(hour: 18, minute: 0),
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context)
                                  .copyWith(alwaysUse24HourFormat: false),
                              child: child ?? const SizedBox(),
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedOutTime = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedTime ??
                                  'Choose Time Out (e.g. 06:00 PM)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: formattedTime != null
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: formattedTime != null
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                            const Icon(Icons.access_time_rounded,
                                size: 18, color: AppColors.primaryNavy),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
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
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.primaryNavy),
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
                          hintStyle: const TextStyle(
                              fontSize: 13, color: AppColors.textLight),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.borderGrey),
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
                              side:
                                  const BorderSide(color: AppColors.borderGrey),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w600)),
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
                                final customReason =
                                    reasonController.text.trim();
                                if (customReason.isEmpty) {
                                  SnackbarHelper.showWarning(
                                    parentContext,
                                    'Please enter reason for regularization',
                                  );
                                  return;
                                }
                                finalReason = 'Others: $customReason';
                              }

                              // Validate that Time Out is strictly after Time In
                              DateTime? checkInDateTime;
                              if (record.checkInTime.isNotEmpty &&
                                  record.checkInTime != '--:--') {
                                try {
                                  if (record.checkInTime.contains('T') ||
                                      (record.checkInTime.contains('-') &&
                                          record.checkInTime.contains(':'))) {
                                    checkInDateTime =
                                        DateTime.tryParse(record.checkInTime);
                                  }
                                  if (checkInDateTime == null) {
                                    final parsed = DateFormat('hh:mm a')
                                        .parse(record.checkInTime);
                                    checkInDateTime = DateTime(
                                      record.date.year,
                                      record.date.month,
                                      record.date.day,
                                      parsed.hour,
                                      parsed.minute,
                                    );
                                  }
                                } catch (_) {}
                              }

                              final selectedDateTime = DateTime(
                                record.date.year,
                                record.date.month,
                                record.date.day,
                                selectedOutTime!.hour,
                                selectedOutTime!.minute,
                              );

                              if (checkInDateTime != null &&
                                  !selectedDateTime.isAfter(checkInDateTime)) {
                                SnackbarHelper.showWarning(
                                  parentContext,
                                  'Requested Time-Out cannot be earlier than or equal to Time-In (${record.checkInTime})',
                                );
                                return;
                              }

                              final requestedTimeOut =
                                  "${DateFormat('yyyy-MM-dd').format(record.date)}T${selectedOutTime!.hour.toString().padLeft(2, '0')}:${selectedOutTime!.minute.toString().padLeft(2, '0')}:00";

                              Navigator.of(modalCtx).pop();

                              // Submit Attendance Regularization API Request
                              parentContext.read<AttendanceBloc>().add(
                                    RegularizeAttendanceRequestedEvent(
                                      attendanceId: record.id,
                                      requestedTimeOut: requestedTimeOut,
                                      reason: finalReason,
                                    ),
                                  );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text(
                              'Submit Request',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
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

class _HistoryEmployeeSelectionResult {
  final bool isCleared;
  final CreatedEmployee? employee;

  const _HistoryEmployeeSelectionResult({
    this.isCleared = false,
    this.employee,
  });
}

class _HistoryEmployeeSearchModal extends StatefulWidget {
  final CreatedEmployee? initialSelected;
  final List<CreatedEmployee> employees;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _HistoryEmployeeSearchModal({
    required this.initialSelected,
    required this.employees,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  State<_HistoryEmployeeSearchModal> createState() =>
      _HistoryEmployeeSearchModalState();
}

class _HistoryEmployeeSearchModalState
    extends State<_HistoryEmployeeSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'EM';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredEmployees = widget.employees.where((emp) {
      if (query.isEmpty) return true;
      final nameMatches = emp.fullName.toLowerCase().contains(query);
      final idMatches = emp.employeeId.toLowerCase().contains(query);
      final emailMatches = emp.email.toLowerCase().contains(query);
      final roleMatches = emp.role.toLowerCase().contains(query);
      return nameMatches || idMatches || emailMatches || roleMatches;
    }).toList();

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Employee',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      // const SizedBox(height: 2),
                      // Text(
                      //   'Search by full name, ID, or designation',
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color: Colors.grey.shade600,
                      //   ),
                      // ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Type Employee Name or ID',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryNavy,
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel_rounded,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Body List
            Expanded(
              child: widget.isLoading && widget.employees.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text(
                            'Loading employees...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : widget.error != null && widget.employees.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.dangerRose,
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: widget.onRetry,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryNavy,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredEmployees.isEmpty && query.isNotEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_search_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No employees found matching "$query"',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Try searching with a different name or ID.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: filteredEmployees.length + 1,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 64,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  final isSelectedAll =
                                      widget.initialSelected == null;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.people_alt_outlined,
                                        color: AppColors.primaryNavy,
                                        size: 20,
                                      ),
                                    ),
                                    title: const Text(
                                      'All Employees',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'View attendance records for all employees',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    trailing: isSelectedAll
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primaryNavy,
                                            size: 22,
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.of(context).pop(
                                        const _HistoryEmployeeSelectionResult(
                                          isCleared: true,
                                        ),
                                      );
                                    },
                                  );
                                }

                                final employee = filteredEmployees[index - 1];
                                final isSelected =
                                    widget.initialSelected?.employeeId ==
                                        employee.employeeId;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryNavy
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _getInitials(employee.fullName),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    employee.fullName,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Text(
                                    'ID: ${employee.employeeId}  •  ${employee.role}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primaryNavy,
                                          size: 22,
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.of(context).pop(
                                      _HistoryEmployeeSelectionResult(
                                        employee: employee,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
