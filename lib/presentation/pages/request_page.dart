import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/leave_request.dart';
import '../blocs/leave/leave_bloc.dart';
import '../blocs/leave/leave_event.dart';
import '../blocs/leave/leave_state.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  int _selectedTabIndex = 0; // 0 for Pending, 1 for Completed

  @override
  void initState() {
    super.initState();
    // Fetch pending requests on initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<LeaveBloc>()
          .add(const LoadLeaveRequestsEvent(status: 'PENDING'));
    });
  }

  void _onTabSelected(int index) {
    if (_selectedTabIndex == index) return;
    setState(() {
      _selectedTabIndex = index;
    });
    if (index == 0) {
      context
          .read<LeaveBloc>()
          .add(const LoadLeaveRequestsEvent(status: 'PENDING'));
    } else {
      context
          .read<LeaveBloc>()
          .add(const LoadLeaveRequestsEvent(status: 'APPROVED,REJECTED'));
    }
  }

  IconData _getTypeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('wfh')) {
      return Icons.other_houses_outlined;
    } else if (t.contains('adjustment') || t.contains('punch') || t.contains('reg')) {
      return Icons.access_time_outlined;
    }
    return Icons.beach_access_rounded;
  }

  String _formatDisplayDate(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return DateFormat('MMM dd, yyyy').format(start);
    }
    return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = AppColors.primaryNavy;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LeaveBloc>().add(
              LoadLeaveRequestsEvent(
                status: _selectedTabIndex == 0 ? 'PENDING' : 'APPROVED,REJECTED',
              ),
            );
      },
      color: primaryNavy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title
            const Text(
              'Requests',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'View and track your attendance and WFH requests.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Segmented Tab Toggle (Pending / Completed)
            BlocBuilder<LeaveBloc, LeaveState>(
              builder: (context, state) {
                int pendingCount = 0;
                int completedCount = 0;

                if (state is LeaveLoadedState) {
                  pendingCount = state.requests
                      .where((r) => r.status.toLowerCase() == 'pending')
                      .length;
                  completedCount = state.requests
                      .where((r) => r.status.toLowerCase() != 'pending')
                      .length;
                }

                return Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onTabSelected(0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _selectedTabIndex == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _selectedTabIndex == 0 && pendingCount > 0
                                  ? 'Pending ($pendingCount)'
                                  : 'Pending',
                              style: TextStyle(
                                color: _selectedTabIndex == 0
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                                fontWeight: _selectedTabIndex == 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onTabSelected(1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _selectedTabIndex == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _selectedTabIndex == 1 && completedCount > 0
                                  ? 'Completed ($completedCount)'
                                  : 'Completed',
                              style: TextStyle(
                                color: _selectedTabIndex == 1
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                                fontWeight: _selectedTabIndex == 1
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Tab View Content with Bloc
            BlocConsumer<LeaveBloc, LeaveState>(
              listener: (context, state) {
                if (state is LeaveLoadedState && state.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage!),
                      backgroundColor: AppColors.successEmerald,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is LeaveLoadingState) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: primaryNavy),
                          SizedBox(height: 12),
                          Text(
                            'Loading requests...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is LeaveErrorState) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            onPressed: () {
                              context.read<LeaveBloc>().add(
                                    LoadLeaveRequestsEvent(
                                      status: _selectedTabIndex == 0
                                          ? 'PENDING'
                                          : null,
                                    ),
                                  );
                            },
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
                  );
                }

                final allRequests =
                    state is LeaveLoadedState ? state.requests : <LeaveRequest>[];

                final activeRequests = _selectedTabIndex == 0
                    ? allRequests
                        .where((r) => r.status.toLowerCase() == 'pending')
                        .toList()
                    : allRequests
                        .where((r) => r.status.toLowerCase() != 'pending')
                        .toList();

                if (activeRequests.isEmpty) {
                  return Container(
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
                        Icon(
                          _selectedTabIndex == 0
                              ? Icons.pending_actions_outlined
                              : Icons.task_alt_outlined,
                          size: 48,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedTabIndex == 0
                              ? 'No pending requests'
                              : 'No completed requests',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedTabIndex == 0
                              ? 'You have no attendance or leave requests awaiting approval.'
                              : 'No completed request history available.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeRequests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = activeRequests[index];
                    return _buildRequestCard(item);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Request Item Card Builder
  Widget _buildRequestCard(LeaveRequest item) {
    final icon = _getTypeIcon(item.requestType);
    final dateStr = _formatDisplayDate(item.startDate, item.endDate);

    String? timeDetails;
    if (item.requestedTimeOut != null && item.requestedTimeOut!.isNotEmpty) {
      final parsed = DateTime.tryParse(item.requestedTimeOut!);
      if (parsed != null) {
        timeDetails = 'Requested Time: ${DateFormat('hh:mm a').format(parsed)}';
      }
    }

    final isPending = item.status.toLowerCase() == 'pending';
    final isApproved = item.status.toLowerCase() == 'approved';

    final Color badgeBg = isPending
        ? const Color(0xFFFEF3C7)
        : isApproved
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2);

    final Color badgeTextColor = isPending
        ? const Color(0xFFB45309)
        : isApproved
            ? const Color(0xFF15803D)
            : const Color(0xFFB91C1C);

    final IconData badgeIcon = isPending
        ? Icons.hourglass_top_rounded
        : isApproved
            ? Icons.check_circle_outline_rounded
            : Icons.cancel_outlined;

    String displayTitle = item.requestType;
    if (item.requestType.toUpperCase() == 'WFH') {
      displayTitle = 'Work From Home';
    } else if (item.requestType.toLowerCase().contains('adjustment') ||
        item.requestType.toLowerCase().contains('reg')) {
      displayTitle = 'Attendance Regularization';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (item.employeeName != null &&
                              item.employeeName!.isNotEmpty)
                            Text(
                              item.employeeName!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      item.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          if (timeDetails != null) ...[
            const SizedBox(height: 6),
            Text(
              timeDetails,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ],
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.reason,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (item.requestId != null || item.assignedApproverName != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.requestId != null)
                  Text(
                    'Req: ${item.requestId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (item.assignedApproverName != null)
                  Text(
                    'Approver: ${item.assignedApproverName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}