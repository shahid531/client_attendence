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

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => RequestPageState();
}

class RequestPageState extends State<RequestPage> {
  int _selectedTabIndex = 0; // 0 for Pending (or Rejected for Admin), 1 for Completed

  // Pagination State
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  // Search State
  final TextEditingController _searchController = TextEditingController();

  // Tab Count Cache
  int _cachedPendingCount = 0;
  int _cachedCompletedCount = 0;

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
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      if (RegExp(r'^[0-9]+$').hasMatch(query)) {
        employeeId = query;
      } else {
        employeeName = query;
      }
    }

    final statusParam = _selectedTabIndex == 0
        ? (_isAdmin ? 'REJECTED' : 'PENDING')
        : 'APPROVED,REJECTED';

    context.read<LeaveBloc>().add(
          LoadLeaveRequestsEvent(
            status: statusParam,
            page: page,
            pageSize: _pageSize,
            employeeId: employeeId,
            employeeName: employeeName,
            isLoadMore: isLoadMore,
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Fetch requests on initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshCurrentTab();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedTabIndex == index) return;
    setState(() {
      _selectedTabIndex = index;
    });
    refreshCurrentTab(page: 0, isLoadMore: false);
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
        refreshCurrentTab(page: 0, isLoadMore: false);
      },
      color: primaryNavy,
      child: SingleChildScrollView(
        controller: _scrollController,
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
                if (state is LeaveLoadedState) {
                  if (state.pendingCount != null) {
                    _cachedPendingCount = state.pendingCount!;
                  } else {
                    _cachedPendingCount = state.requests
                        .where((r) => r.status.toLowerCase() == (_isAdmin ? 'rejected' : 'pending'))
                        .length;
                  }

                  if (state.completedCount != null) {
                    _cachedCompletedCount = state.completedCount!;
                  } else {
                    _cachedCompletedCount = state.requests
                        .where((r) => r.status.toLowerCase() != (_isAdmin ? 'rejected' : 'pending'))
                        .length;
                  }
                }

                final firstTabCount = _cachedPendingCount;
                final completedCount = _cachedCompletedCount;

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
                          onTap: () => _onTabSelected(0),
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
                              _isAdmin
                                  ? 'Rejected ($firstTabCount)'
                                  : 'Pending ($firstTabCount)',
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
                          onTap: () => _onTabSelected(1),
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
              },
            ),
            const SizedBox(height: 16),

            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: 16),

            // Tab View Content with Bloc
            BlocConsumer<LeaveBloc, LeaveState>(
              listener: (context, state) {
                if (state is LeaveLoadedState && state.successMessage != null) {
                  SnackbarHelper.showSuccess(context, state.successMessage!);
                } else if (state is LeaveErrorState) {
                  SnackbarHelper.showError(context, state.message);
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
                              refreshCurrentTab(page: 0, isLoadMore: false);
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
                    ? (_isAdmin
                        ? allRequests
                            .where((r) => r.status.toLowerCase() == 'rejected')
                            .toList()
                        : allRequests
                            .where((r) => r.status.toLowerCase() == 'pending')
                            .toList())
                    : (_isAdmin
                        ? allRequests
                            .where((r) => r.status.toLowerCase() != 'rejected')
                            .toList()
                        : allRequests
                            .where((r) => r.status.toLowerCase() != 'pending')
                            .toList());

                final displayedRequests = activeRequests;

                if (displayedRequests.isEmpty) {
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
                          _searchController.text.trim().isNotEmpty
                              ? 'No matching requests found'
                              : (_selectedTabIndex == 0
                                  ? (_isAdmin ? 'No rejected requests' : 'No pending requests')
                                  : 'No completed requests'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ...displayedRequests.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildRequestCard(item),
                      ),
                    ),
                    if (state is LeaveLoadedState)
                      _buildScrollPaginationFooter(state),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              refreshCurrentTab(page: 0, isLoadMore: false);
            },
            decoration: InputDecoration(
              hintText: 'Type Employee name or ID',
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {});
                        refreshCurrentTab(page: 0, isLoadMore: false);
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
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: () {
              FocusScope.of(context).unfocus();
              refreshCurrentTab(page: 0, isLoadMore: false);
            },
            icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Search',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollPaginationFooter(LeaveLoadedState state) {
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
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
      final total = state.totalElements > 0 ? state.totalElements : state.requests.length;
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