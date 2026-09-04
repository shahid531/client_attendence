import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
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
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(LoadTodayAttendanceEvent());
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

  String _formatTotalHours(double? hours) {
    if (hours == null || hours == 0.0) return '-- h --';
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    if (wholeHours > 0 && minutes > 0) {
      return '${wholeHours}h ${minutes}m';
    } else if (wholeHours > 0) {
      return '${wholeHours}h 00m';
    } else {
      return '${minutes}m';
    }
  }

  void _onConfirmPressed({
    required bool isClockedIn,
    required String? recordId,
  }) {
    FocusScope.of(context).unfocus();
    final description = _descriptionController.text.trim();

    if (isClockedIn) {
      if (recordId != null) {
        context.read<AttendanceBloc>().add(
              CheckOutRequestedEvent(
                recordId: recordId,
                description: description,
              ),
            );
        _descriptionController.clear();
      }
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
        if (state is AttendanceLoadedState && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.successEmerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
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
        final isClockedIn =
            todayRecord != null && todayRecord.checkOutTime == null;

        // Auto sync work type if already checked in
        if (todayRecord != null) {
          if (todayRecord.workType == 'WFH' && _selectedWorkTypeIndex != 1) {
            _selectedWorkTypeIndex = 1;
          } else if (todayRecord.workType == 'GPS' &&
              _selectedWorkTypeIndex != 0) {
            _selectedWorkTypeIndex = 0;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title & Subtitle
              Text(
                isClockedIn ? 'Clock Out' : 'Clock In',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isClockedIn
                    ? 'Submit your end-of-day summary to complete clock-out.'
                    : 'Review your location and submit your work description to clock in.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Total Hours Worked Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.timer_outlined,
                          color: AppColors.primaryNavy,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'TOTAL HOURS WORKED',
                          style: TextStyle(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _formatTotalHours(todayRecord?.totalHours),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'In',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(todayRecord?.checkInTime),
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: AppColors.borderGrey,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Out',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(todayRecord?.checkOutTime),
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 20),

              // Segmented Control (GPS / WFH)
              if (!isClockedIn)
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
                            onTap: () =>
                                setState(() => _selectedWorkTypeIndex = 0),
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
                            onTap: () =>
                                setState(() => _selectedWorkTypeIndex = 1),
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
              if (!isClockedIn) const SizedBox(height: 20),

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      enabled: !isLoading,
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
                  onPressed: isLoading
                      ? null
                      : () => _onConfirmPressed(
                            isClockedIn: isClockedIn,
                            recordId: todayRecord?.id,
                          ),
                  icon: Icon(
                    isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
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
                          isClockedIn
                              ? 'Confirm Clock Out'
                              : 'Confirm Clock In',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClockedIn
                        ? AppColors.warningAmber
                        : AppColors.primaryNavy,
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
