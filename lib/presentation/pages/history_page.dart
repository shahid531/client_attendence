import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/attendance_record.dart';
import '../blocs/attendance/attendance_bloc.dart';
import '../blocs/attendance/attendance_event.dart';
import '../blocs/attendance/attendance_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedPeriod = 'This Month';
  final List<String> _periodOptions = [
    'This Month',
    'Last Month',
    'All Time',
    'Custom'
  ];

  String _selectedWorkTypeFilter = 'All';
  final List<String> _workTypeFilters = ['All', 'GPS', 'WFH', 'Half Day'];

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(LoadAttendanceHistoryEvent());
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    try {
      if (timeStr.contains('T') || timeStr.contains('-')) {
        final parsed = DateTime.parse(timeStr);
        return DateFormat('hh:mm a').format(parsed);
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);

    if (recordDate == today) return 'TODAY';
    if (recordDate == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return DateFormat('EEE').format(date).toUpperCase();
  }

  List<AttendanceRecord> _filterRecords(List<AttendanceRecord> records) {
    final now = DateTime.now();

    return records.where((record) {
      // 1. Period filter
      if (_selectedPeriod == 'This Month') {
        if (record.date.month != now.month || record.date.year != now.year) {
          return false;
        }
      } else if (_selectedPeriod == 'Last Month') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        if (record.date.month != lastMonth.month ||
            record.date.year != lastMonth.year) {
          return false;
        }
      } else if (_selectedPeriod == 'Custom') {
        final recordDay =
            DateTime(record.date.year, record.date.month, record.date.day);
        final startDay =
            DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
        final endDay = DateTime(_toDate.year, _toDate.month, _toDate.day);
        if (recordDay.isBefore(startDay) || recordDay.isAfter(endDay)) {
          return false;
        }
      }

      // 2. Work type filter
      if (_selectedWorkTypeFilter == 'GPS' && record.workType != 'GPS') {
        return false;
      }
      if (_selectedWorkTypeFilter == 'WFH' && record.workType != 'WFH') {
        return false;
      }
      if (_selectedWorkTypeFilter == 'Half Day' &&
          record.status != 'Half Day') {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final isLoading = state is AttendanceLoadingState;
          final allHistory =
              state is AttendanceLoadedState ? state.history : <AttendanceRecord>[];
          final filteredHistory = _filterRecords(allHistory);

          // Calculate summary metrics
          final presentCount = filteredHistory
              .where((r) => r.status == 'Present' || r.status == 'Half Day')
              .length;
          final wfhCount =
              filteredHistory.where((r) => r.workType == 'WFH').length;
          final totalHours = filteredHistory.fold<double>(
              0.0, (sum, r) => sum + r.totalHours);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AttendanceBloc>().add(LoadAttendanceHistoryEvent());
            },
            color: AppColors.primaryNavy,
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
                          color: AppColors.textDark,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Attendance log exported successfully!'),
                              backgroundColor: AppColors.successEmerald,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.download_rounded,
                          size: 16,
                          color: AppColors.primaryNavy,
                        ),
                        label: const Text(
                          'Export',
                          style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Period Dropdown and Work Type Filter Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedPeriod = newValue;
                                });
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _workTypeFilters.map((filter) {
                              final isSelected =
                                  _selectedWorkTypeFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: ChoiceChip(
                                  label: Text(filter),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedWorkTypeFilter = filter;
                                      });
                                    }
                                  },
                                  selectedColor: AppColors.primaryNavy,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primaryNavy
                                          : AppColors.borderGrey,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Conditional Custom Date Range Picker Card
                  if (_selectedPeriod == 'Custom') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
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
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPeriod = 'This Month';
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Color(0xFFCBD5E1),
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'FROM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => _selectDate(context, true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEDF2F7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDate(_fromDate),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.calendar_month_outlined,
                                              size: 14,
                                              color: AppColors.primaryNavy,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => _selectDate(context, false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEDF2F7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDate(_toDate),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.calendar_month_outlined,
                                              size: 14,
                                              color: AppColors.primaryNavy,
                                            ),
                                          ],
                                        ),
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
                    const SizedBox(height: 14),
                  ],

                  // Dynamic Summary Stats Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      children: [
                        _buildStatItem(
                          '$presentCount',
                          'Present',
                          AppColors.primaryBlue,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          '$wfhCount',
                          'WFH',
                          AppColors.textDark,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          '${totalHours.toStringAsFixed(1)}h',
                          'Total Hours',
                          AppColors.successEmerald,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // History Records List / Empty State / Loading
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    )
                  else if (filteredHistory.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 48,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No Attendance Records Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try changing the period or filter criteria above.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredHistory.length,
                      itemBuilder: (context, index) {
                        final record = filteredHistory[index];
                        return _buildAttendanceCard(record);
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
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

  // Dynamic Card Item Builder
  Widget _buildAttendanceCard(AttendanceRecord record) {
    Color accentColor = AppColors.primaryBlue;
    Color badgeBg = AppColors.successBg;
    Color badgeTextColor = AppColors.successEmerald;
    IconData badgeIcon = Icons.check_circle_outline_rounded;
    String badgeLabel = record.status;

    if (record.workType == 'WFH') {
      accentColor = AppColors.warningAmber;
      badgeBg = AppColors.warningBg;
      badgeTextColor = AppColors.warningAmber;
      badgeIcon = Icons.home_rounded;
      badgeLabel = 'WFH';
    } else if (record.status == 'Half Day') {
      accentColor = const Color(0xFF8B5CF6);
      badgeBg = const Color(0xFFF3E8FF);
      badgeTextColor = const Color(0xFF7C3AED);
      badgeIcon = Icons.timelapse_rounded;
      badgeLabel = 'Half Day';
    } else if (record.status == 'Absent') {
      accentColor = AppColors.dangerRose;
      badgeBg = AppColors.dangerBg;
      badgeTextColor = AppColors.dangerRose;
      badgeIcon = Icons.cancel_outlined;
      badgeLabel = 'Absent';
    }

    final dateStr = DateFormat('MMM dd, yyyy').format(record.date);
    final dayLabel = _getDayLabel(record.date);
    final isClockOutMissing = record.checkOutTime == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
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
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badgeIcon,
                                size: 13,
                                color: badgeTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badgeLabel,
                                style: TextStyle(
                                  color: badgeTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          record.workType == 'GPS'
                              ? Icons.location_on_outlined
                              : Icons.home_work_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            record.location.isNotEmpty
                                ? record.location
                                : 'Client Site',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (record.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        record.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          size: 15,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(record.checkInTime),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          height: 12,
                          width: 1,
                          color: AppColors.borderGrey,
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.logout_rounded,
                          size: 15,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        if (isClockOutMissing)
                          const Text(
                            'Active / Missing',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warningAmber,
                            ),
                          )
                        else
                          Text(
                            _formatTime(record.checkOutTime),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        const Spacer(),
                        if (record.totalHours > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${record.totalHours.toStringAsFixed(1)} hrs',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
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
    );
  }
}
