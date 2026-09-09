import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../domain/entities/leave_request.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/leave/leave_bloc.dart';
import '../blocs/leave/leave_event.dart';
import '../blocs/leave/leave_state.dart';
import 'review_request_dialog.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => ApprovalsScreenState();
}

class ApprovalsScreenState extends State<ApprovalsScreen> {
  int _selectedTabIndex = 0; // 0 for Pending, 1 for Completed
  int _completedFilterIndex = 0; // 0 for All, 1 for Reject, 2 for Approve
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void refreshCurrentTab() {
    context.read<LeaveBloc>().add(
          LoadLeaveRequestsEvent(
            status: _selectedTabIndex == 0
                ? 'PENDING'
                : 'APPROVED,REJECTED',
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        refreshCurrentTab();
      }
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String title) {
    if (title.isEmpty) return 'EM';
    final parts = title.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return title.substring(0, title.length >= 2 ? 2 : 1).toUpperCase();
  }

  IconData _getTypeIcon(String type) {
    if (type.toLowerCase().contains('wfh')) {
      return Icons.home_work_outlined;
    } else if (type.toLowerCase().contains('adjustment') ||
        type.toLowerCase().contains('punch') ||
        type.toLowerCase().contains('reg')) {
      return Icons.access_time_filled_rounded;
    }
    return Icons.beach_access_rounded;
  }

  void _onTakeAction(LeaveRequest item) {
    showDialog(
      context: context,
      builder: (ctx) => ReviewRequestDialog(
        request: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocConsumer<LeaveBloc, LeaveState>(
        listener: (context, state) {
          if (state is LeaveLoadedState && state.successMessage != null) {
            SnackbarHelper.showSuccess(context, state.successMessage!);
          } else if (state is LeaveErrorState) {
            SnackbarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is LeaveLoadingState;
          final allRequests =
              state is LeaveLoadedState ? state.requests : <LeaveRequest>[];

          // Separate Pending & Completed (case-insensitive for API PENDING/APPROVED)
          final pendingList = allRequests
              .where((r) => r.status.toUpperCase() == 'PENDING')
              .toList();
          final completedList = allRequests
              .where((r) => r.status.toUpperCase() != 'PENDING')
              .toList();

          // Apply Completed sub-filter (All, Reject, Approve)
          List<LeaveRequest> filteredCompleted = completedList;
          if (_completedFilterIndex == 1) {
            filteredCompleted = completedList
                .where((r) =>
                    r.status.toUpperCase() == 'REJECTED' ||
                    r.status.toUpperCase() == 'REJECT')
                .toList();
          } else if (_completedFilterIndex == 2) {
            filteredCompleted = completedList
                .where((r) =>
                    r.status.toUpperCase() == 'APPROVED' ||
                    r.status.toUpperCase() == 'APPROVE')
                .toList();
          }

          // Apply Search Query
          List<LeaveRequest> activeList = _selectedTabIndex == 0
              ? pendingList
              : filteredCompleted;

          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.trim().toLowerCase();
            activeList = activeList.where((r) {
              return r.title.toLowerCase().contains(q) ||
                  r.reason.toLowerCase().contains(q) ||
                  r.requestType.toLowerCase().contains(q) ||
                  r.employeeName.toLowerCase().contains(q) ||
                  r.employeeId.toLowerCase().contains(q) ||
                  r.requestId.toLowerCase().contains(q);
            }).toList();
          }

          // Dynamic Metrics
          final totalPending = pendingList.length;
          final wfhPending = pendingList
              .where((r) => r.requestType.toUpperCase().contains('WFH'))
              .length;
          final regPending = pendingList
              .where((r) =>
                  r.requestType.toUpperCase().contains('ADJUSTMENT') ||
                  r.requestType.toUpperCase().contains('LEAVE'))
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              refreshCurrentTab();
            },
            color: AppColors.primaryNavy,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Approvals',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review and manage employee requests in real time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Header Card
                  _buildMetricsCard(
                    totalPending: totalPending,
                    regCount: regPending,
                    wfhCount: wfhPending,
                  ),
                  const SizedBox(height: 16),

                  // Tab Toggle (Pending / Completed)
                  _buildTabToggle(
                    pendingCount: pendingList.length,
                    completedCount: completedList.length,
                  ),
                  const SizedBox(height: 14),

                  // Sub-filter chips for Completed tab
                  if (_selectedTabIndex == 1) ...[
                    _buildFilterChips(),
                    const SizedBox(height: 14),
                  ],

                  // Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  // List / Loading / Empty State
                  if (isLoading && allRequests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    )
                  else if (activeList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 40,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedTabIndex == 0
                                ? Icons.task_alt_rounded
                                : Icons.history_rounded,
                            size: 44,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTabIndex == 0
                                ? 'No Pending Approvals'
                                : 'No Completed Records Found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          // const SizedBox(height: 4),
                          // Text(
                          //   _selectedTabIndex == 0
                          //       ? 'All employee requests have been processed.'
                          //       : 'No history matches your search filter.',
                          //   style: const TextStyle(
                          //     fontSize: 13,
                          //     color: AppColors.textMuted,
                          //   ),
                          //   textAlign: TextAlign.center,
                          // ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = activeList[index];
                        if (_selectedTabIndex == 0) {
                          print("nvhdfvhb ${item}");
                          return _buildPendingCard(item);
                        } else {
                          return _buildCompletedCard(item);
                        }
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsCard({
    required int totalPending,
    required int regCount,
    required int wfhCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PENDING REQUESTS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalPending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildStatBox('$regCount', 'Leave/Reg'),
          const SizedBox(width: 8),
          _buildStatBox('$wfhCount', 'WFH'),
        ],
      ),
    );
  }

  Widget _buildStatBox(String count, String label) {
    return Container(
      width: 72,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle({
    required int pendingCount,
    required int completedCount,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != 0) {
                  setState(() => _selectedTabIndex = 0);
                  context.read<LeaveBloc>().add(
                        const LoadLeaveRequestsEvent(
                          status: 'PENDING',
                        ),
                      );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pending ($pendingCount)',
                  style: TextStyle(
                    fontWeight: _selectedTabIndex == 0
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: _selectedTabIndex == 0
                        ? AppColors.primaryNavy
                        : AppColors.textLight,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != 1) {
                  setState(() => _selectedTabIndex = 1);
                  context.read<LeaveBloc>().add(
                        const LoadLeaveRequestsEvent(
                          status: 'APPROVED,REJECTED',
                        ),
                      );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Completed ($completedCount)',
                  style: TextStyle(
                    fontWeight: _selectedTabIndex == 1
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: _selectedTabIndex == 1
                        ? AppColors.primaryNavy
                        : AppColors.textLight,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Rejected', 'Approved'];
    return Row(
      children: List.generate(filters.length, (index) {
        final isSelected = _completedFilterIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _completedFilterIndex = index);
              }
            },
            selectedColor: AppColors.primaryNavy,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? AppColors.primaryNavy : AppColors.borderGrey,
              ),
            ),
            showCheckmark: false,
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search requests or employees...',
          hintStyle: const TextStyle(
            color: AppColors.textLight,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 14,
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '--';
    if (date is DateTime) {
      return DateFormat('MMM dd, yyyy').format(date);
    }
    final str = date.toString();
    if (str.isEmpty) return '--';
    try {
      final parsed = DateTime.parse(str);
      return DateFormat('MMM dd, yyyy').format(parsed);
    } catch (_) {
      return str;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.trim().isEmpty) {
      return '--:--';
    }
    try {
      final dateTime = DateTime.parse(time);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (_) {
      return time;
    }
  }

  Widget _buildPendingCard(LeaveRequest item) {
    final initials = _getInitials(item.title);
    final icon = _getTypeIcon(item.requestType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryNavy.withOpacity(0.08),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      item.requestType,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.employeeId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "EMP-${item.employeeId}",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(item.startDate),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),

            ],
          ),
            const SizedBox(height: 10),
         Row(
           crossAxisAlignment: CrossAxisAlignment.start ,
           children: [
           const Icon(
             Icons.access_time_rounded,
             size: 14,
             color: AppColors.textLight,
           ),
           const SizedBox(width: 6),
           Expanded(
             child: Text(
               'In: ${_formatTime(item.timeIn)}  •  Out: ${_formatTime(item.timeOut)}',
               style: const TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.w500,
                 color: AppColors.textDark,
               ),
               overflow: TextOverflow.ellipsis,
             ),
           ),
         ],),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _onTakeAction(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Take Action',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(LeaveRequest item) {
    final bool isApproved = item.status.toUpperCase() == 'APPROVED' ||
        item.status.toUpperCase() == 'APPROVE';
    final Color badgeBgColor =
        isApproved ? AppColors.successBg : AppColors.dangerBg;
    final Color badgeTextColor =
        isApproved ? AppColors.successEmerald : AppColors.dangerRose;
    final IconData badgeIcon =
        isApproved ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;

    final dateRangeStr =
        '${_formatDate(item.startDate)} - ${_formatDate(item.endDate)}';
    final initials = _getInitials(item.title);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryNavy.withOpacity(0.08),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: badgeTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.employeeId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "EMP-${item.employeeId}",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(item.startDate),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),

            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.timeIn != null || item.timeOut != null) ...[
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'In: ${_formatTime(item.timeIn)}  •  Out: ${_formatTime(item.timeOut)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

