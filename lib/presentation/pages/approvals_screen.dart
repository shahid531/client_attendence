import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../domain/entities/created_employee.dart';
import '../../domain/entities/leave_request.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
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

  // Selected Employee filter
  CreatedEmployee? _selectedEmployee;

  // Pagination State
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  bool get _isAdmin {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return authState.user.role.trim().toUpperCase() == 'ADMIN';
    }
    return false;
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final state = context.read<LeaveBloc>().state;
    if (state is LeaveLoadedState && !state.isLoadingMore && state.hasNext) {
      refreshCurrentTab(page: state.page + 1, isLoadMore: true);
    }
  }

  void refreshCurrentTab({int page = 0, bool isLoadMore = false}) {
    String? employeeId;
    String? employeeName;
    if (_selectedEmployee != null) {
      employeeId = _selectedEmployee!.employeeId;
      employeeName = _selectedEmployee!.fullName;
    }

    context.read<LeaveBloc>().add(
          LoadLeaveRequestsEvent(
            status: _selectedTabIndex == 0
                ? 'PENDING'
                : 'APPROVED,REJECTED',
            page: page,
            pageSize: _pageSize,
            employeeId: employeeId,
            employeeName: employeeName,
            isLoadMore: isLoadMore,
            isApprovals: true,
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reportingManagerId = _isAdmin ? 'admin' : '';
        context.read<AdminBloc>().add(
              LoadEmployeesEvent(reportingManagerId: reportingManagerId),
            );
        refreshCurrentTab();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getDisplayName(LeaveRequest item) {
    if (item.employeeName.trim().isNotEmpty) return item.employeeName.trim();
    if (item.title.trim().isNotEmpty) {
      if (item.title.contains(' - ')) {
        return item.title.split(' - ').first.trim();
      }
      return item.title.trim();
    }
    return 'Employee';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'EM';
    final clean = name.contains(' - ') ? name.split(' - ').first.trim() : name.trim();
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
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

          final List<LeaveRequest> activeList = _selectedTabIndex == 0
              ? pendingList
              : filteredCompleted;

          // Dynamic Metrics
          // Dynamic Metrics
          final int totalPending = (state is LeaveLoadedState && state.pendingCount != null)
              ? state.pendingCount!
              : pendingList.length;
          final int totalCompleted = (state is LeaveLoadedState && state.completedCount != null)
              ? state.completedCount!
              : completedList.length;

          return RefreshIndicator(
            onRefresh: () async {
              refreshCurrentTab();
            },
            color: AppColors.primaryNavy,
            child: SingleChildScrollView(
              controller: _scrollController,
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
                  // _buildMetricsCard(
                  //   totalPending: totalPending,
                  //   regCount: regPending,
                  //   wfhCount: wfhPending,
                  // ),
                  // const SizedBox(height: 16),

                  // Tab Toggle (Pending / Completed)
                  _buildTabToggle(
                    pendingCount: totalPending,
                    completedCount: totalCompleted,
                  ),
                  const SizedBox(height: 14),

                  // Sub-filter chips for Completed tab
                  if (_selectedTabIndex == 1) ...[
                    _buildFilterChips(),
                    const SizedBox(height: 14),
                  ],

                  // Search Bar / Employee Selector
                  _buildEmployeeSelector(context),
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
                            _selectedEmployee != null
                                ? 'No matching requests found for ${_selectedEmployee!.fullName}'
                                : (_selectedTabIndex == 0
                                    ? 'No Pending Approvals'
                                    : 'No Completed Records Found'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = activeList[index];
                        if (_selectedTabIndex == 0) {
                          return _buildPendingCard(item);
                        } else {
                          return _buildCompletedCard(item);
                        }
                      },
                    ),

                    // Scroll Pagination Footer
                    if (state is LeaveLoadedState)
                      _buildScrollPaginationFooter(state, activeList.length),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
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
                  refreshCurrentTab();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
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
                  refreshCurrentTab();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
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
                  refreshCurrentTab(page: 0, isLoadMore: false);
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
      final reportingManagerId = _isAdmin ? 'admin' : '';
      context.read<AdminBloc>().add(
            LoadEmployeesEvent(reportingManagerId: reportingManagerId),
          );
    }

    final result = await showModalBottomSheet<_ApprovalsEmployeeSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            return _ApprovalsEmployeeSearchModal(
              initialSelected: _selectedEmployee,
              employees: state.employees,
              isLoading: state.isLoadingEmployees,
              error: state.employeesError,
              onRetry: () {
                final reportingManagerId = _isAdmin ? 'admin' : '';
                context.read<AdminBloc>().add(
                      LoadEmployeesEvent(
                        isRefresh: true,
                        reportingManagerId: reportingManagerId,
                      ),
                    );
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
      refreshCurrentTab(page: 0, isLoadMore: false);
    }
  }

  Widget _buildScrollPaginationFooter(LeaveLoadedState state, int displayedCount) {
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
              'Loading more requests...',
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

    if (!state.hasNext && state.requests.isNotEmpty) {
      final total = state.totalElements > 0 ? state.totalElements : displayedCount;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Text(
          'Showing all $total requests',
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
    final displayName = _getDisplayName(item);
    final initials = _getInitials(displayName);
    final icon = _getTypeIcon(item.requestType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
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
                  displayName,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
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

    final displayName = _getDisplayName(item);
    final initials = _getInitials(displayName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
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
                  displayName,
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
        ],
      ),
    );
  }
}

class _ApprovalsEmployeeSelectionResult {
  final bool isCleared;
  final CreatedEmployee? employee;

  const _ApprovalsEmployeeSelectionResult({
    this.isCleared = false,
    this.employee,
  });
}

class _ApprovalsEmployeeSearchModal extends StatefulWidget {
  final CreatedEmployee? initialSelected;
  final List<CreatedEmployee> employees;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _ApprovalsEmployeeSearchModal({
    required this.initialSelected,
    required this.employees,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  State<_ApprovalsEmployeeSearchModal> createState() =>
      _ApprovalsEmployeeSearchModalState();
}

class _ApprovalsEmployeeSearchModalState
    extends State<_ApprovalsEmployeeSearchModal> {
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
                                      'View requests for all employees',
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
                                        const _ApprovalsEmployeeSelectionResult(
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
                                      _ApprovalsEmployeeSelectionResult(
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

