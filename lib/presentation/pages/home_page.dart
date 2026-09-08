import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/attendance_record_model.dart';
import '../blocs/attendance/attendance_bloc.dart';
import '../blocs/attendance/attendance_event.dart';
import '../blocs/attendance/attendance_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedWorkTypeIndex = 0; // 0 for GPS, 1 for WFH
  bool _isLocalClockedIn = false;
  String? _localInTime;
  String? _localOutTime;
  double _localTotalHours = 0.0;
  String? _localRecordId;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    context.read<AttendanceBloc>().add(LoadTodayAttendanceEvent());
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString('today_attendance_date');
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (savedDate == todayStr) {
        final isClockedIn = prefs.getBool('today_attendance_is_clocked_in') ?? false;
        final workType = prefs.getString('today_attendance_work_type') ?? 'GPS';
        final savedIndex = prefs.getInt('selected_work_type_index');

        final savedJsonStr = prefs.getString('today_attendance_record_data');
        if (savedJsonStr != null && savedJsonStr.isNotEmpty) {
          try {
            final decoded = jsonDecode(savedJsonStr);
            if (decoded is Map<String, dynamic>) {
              final model = AttendanceRecordModel.fromJson(decoded);
              _localInTime = model.checkInTime;
              _localOutTime = model.checkOutTime;
              _localTotalHours = model.totalHours;
              _localRecordId = model.id;
            }
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _isLocalClockedIn = isClockedIn;
            if (workType.toUpperCase() == 'WFH') {
              _selectedWorkTypeIndex = 1;
            } else if (savedIndex != null) {
              _selectedWorkTypeIndex = savedIndex;
            }
          });
        }
      } else {
        // New day: Reset all today attendance data for HomePage
        await prefs.remove('today_attendance_record_data');
        await prefs.remove('today_attendance_date');
        await prefs.remove('today_attendance_work_type');
        await prefs.remove('today_attendance_is_clocked_in');
        await prefs.remove('selected_work_type_index');

        if (mounted) {
          setState(() {
            _isLocalClockedIn = false;
            _localInTime = null;
            _localOutTime = null;
            _localTotalHours = 0.0;
            _localRecordId = null;
            _selectedWorkTypeIndex = 0;
            _descriptionController.clear();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSelectedWorkType(int index) async {
    setState(() {
      _selectedWorkTypeIndex = index;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_work_type_index', index);
    } catch (_) {}
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '--:--';
    try {
      if (dateTimeStr.contains('T') || dateTimeStr.contains('-')) {
        final parsed = DateTime.parse(dateTimeStr);
        return DateFormat('hh:mm a').format(parsed);
      }
      return dateTimeStr;
    } catch (_) {
      return dateTimeStr;
    }
  }

  Widget _buildBurstAccent({required bool isLeft}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: isLeft ? -0.5 : 0.5,
          child: Container(
            width: 8,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF1D72F2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF1D72F2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Transform.rotate(
          angle: isLeft ? 0.5 : -0.5,
          child: Container(
            width: 8,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF1D72F2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  void _onConfirmPressed({
    required bool isClockedIn,
    required String? recordId,
  }) {
    FocusScope.of(context).unfocus();
    final description = _descriptionController.text.trim();

    if (isClockedIn) {
      context.read<AttendanceBloc>().add(
            CheckOutRequestedEvent(
              recordId: recordId ?? _localRecordId ?? 'att_${DateTime.now().millisecondsSinceEpoch}',
              description: description,
            ),
          );
      _descriptionController.clear();
    } else {
      if (description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a daily work description.'),
            backgroundColor: AppColors.dangerRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final workType = _selectedWorkTypeIndex == 0 ? 'GPS' : 'WFH';
      final location = _selectedWorkTypeIndex == 0
          ? 'HQ Building, 5th Floor'
          : 'Home Office';

      context.read<AttendanceBloc>().add(
            CheckInRequestedEvent(
              workType: workType,
              location: location,
              description: description,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceLoadedState) {
          if (state.todayRecord != null) {
            final isRecordClockedIn = state.todayRecord!.checkOutTime == null ||
                state.todayRecord!.checkOutTime!.isEmpty ||
                state.todayRecord!.checkOutTime == '--:--';
            _isLocalClockedIn = isRecordClockedIn;
            _localInTime = state.todayRecord!.checkInTime;
            _localOutTime = state.todayRecord!.checkOutTime;
            _localTotalHours = state.todayRecord!.totalHours;
            _localRecordId = state.todayRecord!.id;
            if (state.todayRecord!.workType.toUpperCase() == 'WFH') {
              _selectedWorkTypeIndex = 1;
              _saveSelectedWorkType(1);
            } else if (state.todayRecord!.workType.toUpperCase() != 'WFH') {
              _selectedWorkTypeIndex = 0;
              _saveSelectedWorkType(0);
            }
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.successEmerald,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (state is AttendanceErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.dangerRose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AttendanceLoadingState;
        final todayRecord =
            state is AttendanceLoadedState ? state.todayRecord : null;
        final isClockedIn = todayRecord != null
            ? (todayRecord.checkOutTime == null ||
                todayRecord.checkOutTime!.isEmpty ||
                todayRecord.checkOutTime == '--:--')
            : _isLocalClockedIn;

        final displayInTime = todayRecord?.checkInTime ?? _localInTime;
        final displayOutTime = todayRecord?.checkOutTime ?? _localOutTime;
        final displayTotalHours = todayRecord?.totalHours ?? _localTotalHours;
        final activeRecordId = todayRecord?.id ?? _localRecordId;

        final isCompletedToday = !isClockedIn &&
            (displayOutTime != null &&
                displayOutTime != '--:--' &&
                displayOutTime.isNotEmpty);

        final hasMarkedToday = isClockedIn || isCompletedToday;

        // Auto sync work type if already checked in or recorded for today
        if (todayRecord != null) {
          final isWfh = todayRecord.workType.toUpperCase() == 'WFH';
          if (isWfh && _selectedWorkTypeIndex != 1) {
            _selectedWorkTypeIndex = 1;
            _saveSelectedWorkType(1);
          } else if (!isWfh && _selectedWorkTypeIndex != 0) {
            _selectedWorkTypeIndex = 0;
            _saveSelectedWorkType(0);
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title & Subtitle
              Text(
                isCompletedToday
                    ? (_selectedWorkTypeIndex == 1
                        ? 'Day Completed (WFH)'
                        : 'Day Completed (GPS)')
                    : (isClockedIn
                        ? (_selectedWorkTypeIndex == 1 ? 'Time Out' : 'Clock Out')
                        : (_selectedWorkTypeIndex == 1 ? 'Time In' : 'Clock In')),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isCompletedToday
                    ? 'Your attendance has been fully recorded for today.'
                    : (isClockedIn
                        ? 'Submit your end-of-day summary to complete ${_selectedWorkTypeIndex == 1 ? "time-out" : "clock-out"}.'
                        : 'Review your location and submit your work description to ${_selectedWorkTypeIndex == 1 ? "time-in" : "clock-in"}.'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Total Hours Worked Card (Modern Design matching attachment)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEFF5FF),
                      Color(0xFFF7FAFF),
                      Color(0xFFEBF3FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2EDFC),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D72F2).withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Row with Timer Icon, Title, and Decorative Dot Grid
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Color(0xFF1D72F2),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'TOTAL ',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'HOURS',
                                  style: TextStyle(
                                    color: Color(0xFF1D72F2),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  height: 2,
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D72F2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              ' WORKED',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              2,
                              (row) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: row == 0 ? 3.0 : 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    3,
                                    (col) => Container(
                                      width: 4,
                                      height: 4,
                                      margin: EdgeInsets.only(
                                        right: col < 2 ? 4.0 : 0,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF93C5FD),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Floating Pill with Time Display & Burst Accent Marks
                    Builder(
                      builder: (context) {
                        final totalMinutes = displayTotalHours > 0
                            ? (displayTotalHours * 60).round()
                            : 0;
                        final hoursStr =
                            (totalMinutes ~/ 60).toString().padLeft(2, '0');
                        final minsStr =
                            (totalMinutes % 60).toString().padLeft(2, '0');

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Left Burst Accents
                            _buildBurstAccent(isLeft: true),
                            const SizedBox(width: 12),

                            // White Pill Container
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D72F2)
                                        .withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    hoursStr,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'h',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1D72F2),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    minsStr,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1D72F2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Right Burst Accents
                            _buildBurstAccent(isLeft: false),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // In and Out Time Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1D72F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.login_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'In',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTime(displayInTime),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1D72F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Out',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTime(displayOutTime),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Segmented Control (GPS / WFH) - allowed only before marking attendance
              if (!hasMarkedToday) ...[
                Center(
                  child: Container(
                    height: 48,
                    width: 260,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _saveSelectedWorkType(0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedWorkTypeIndex == 0
                                    ? const Color(0xFFF1F5F9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'GPS Office',
                                style: TextStyle(
                                  color: _selectedWorkTypeIndex == 0
                                      ? AppColors.primaryNavy
                                      : AppColors.textLight,
                                  fontWeight: _selectedWorkTypeIndex == 0
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _saveSelectedWorkType(1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedWorkTypeIndex == 1
                                    ? const Color(0xFFF1F5F9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'WFH Remote',
                                style: TextStyle(
                                  color: _selectedWorkTypeIndex == 1
                                      ? AppColors.primaryNavy
                                      : AppColors.textLight,
                                  fontWeight: _selectedWorkTypeIndex == 1
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Location Verified Card with Gradient (shown for GPS)
              if (_selectedWorkTypeIndex == 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEEF2FF),
                        Color(0xFFF8FAFC),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primaryNavy,
                              size: 24,
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.successEmerald,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Location Verified',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'HQ Building, 5th Floor',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          'In Range',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.successEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Daily Work Description Box
              RichText(
                text: const TextSpan(
                  text: 'Daily Work Description ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: AppColors.dangerRose),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child:Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _descriptionController,

                      maxLines: 4,
                      maxLength: 500,
                      enabled: !isLoading && !isCompletedToday,
                      onChanged: (_) => setState(() {}),
                      buildCounter: (
                          context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) =>
                      null,
                      decoration: const InputDecoration(
                        hintText:
                        'Briefly describe the tasks you completed or plan to work on today...',
                        hintStyle: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Text(
                      '${_descriptionController.text.length} / 500',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (isLoading || isCompletedToday)
                      ? null
                      : () => _onConfirmPressed(
                            isClockedIn: isClockedIn,
                            recordId: activeRecordId,
                          ),
                  icon: Icon(
                    isCompletedToday
                        ? Icons.check_circle_rounded
                        : (isClockedIn ? Icons.logout_rounded : Icons.login_rounded),
                    color: Colors.white,
                    size: 20,
                  ),
                  label: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isCompletedToday
                              ? 'Attendance Marked for Today'
                              : (isClockedIn
                                  ? (_selectedWorkTypeIndex == 1
                                      ? 'Confirm Time Out'
                                      : 'Confirm Clock Out')
                                  : (_selectedWorkTypeIndex == 1
                                      ? 'Confirm Time In'
                                      : 'Confirm Clock In')),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompletedToday
                        ? AppColors.successEmerald
                        : (isClockedIn
                            ? AppColors.warningAmber
                            : AppColors.primaryNavy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
