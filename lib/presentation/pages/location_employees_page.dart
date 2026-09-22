import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/client_location.dart';
import '../../domain/entities/created_employee.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class LocationEmployeesPage extends StatefulWidget {
  final ClientLocation location;

  const LocationEmployeesPage({
    super.key,
    required this.location,
  });

  @override
  State<LocationEmployeesPage> createState() => _LocationEmployeesPageState();
}

class _LocationEmployeesPageState extends State<LocationEmployeesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBloc>().add(const LoadEmployeesEvent());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    FocusScope.of(context).unfocus();
    final query = _searchController.text.trim();
    context.read<AdminBloc>().add(
          LoadEmployeesEvent(
            name: query.isNotEmpty ? query : null,
          ),
        );
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
    context.read<AdminBloc>().add(const LoadEmployeesEvent());
  }

  List<CreatedEmployee> _getFilteredEmployees(List<CreatedEmployee> allEmployees) {
    final location = widget.location;

    // Filter employees assigned to this location
    return allEmployees.where((emp) {
      if (emp.locationId != null &&
          emp.locationId!.isNotEmpty &&
          emp.locationId == location.locationId) {
        return true;
      }
      if (emp.clientName != null &&
          location.clientName != null &&
          emp.clientName!.trim().toLowerCase() ==
              location.clientName!.trim().toLowerCase()) {
        return true;
      }
      if (emp.locationName != null &&
          location.locationName.isNotEmpty &&
          emp.locationName!.trim().toLowerCase() ==
              location.locationName.trim().toLowerCase()) {
        return true;
      }
      return false;
    }).toList();
  }

  void _showEmployeeDetailsDialog(BuildContext context, CreatedEmployee employee) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                child: Text(
                  employee.fullName.isNotEmpty
                      ? employee.fullName.substring(0, 1).toUpperCase()
                      : 'E',
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${employee.employeeId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 16, color: Color(0xFFE2E8F0)),
              _buildDetailItem(
                label: 'Employee ID',
                value: employee.employeeId,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                label: 'Full Name',
                value: employee.fullName,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                label: 'Email',
                value: employee.email,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                label: 'Contact Number',
                value: (employee.contactNumber != null && employee.contactNumber!.isNotEmpty)
                    ? employee.contactNumber!
                    : '-',
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                label: 'Reporting Manager',
                value: (employee.reportingManagerName != null && employee.reportingManagerName!.isNotEmpty)
                    ? employee.reportingManagerName!
                    : (employee.reportingManagerEmployeeId != null && employee.reportingManagerEmployeeId!.isNotEmpty
                        ? 'ID: ${employee.reportingManagerEmployeeId}'
                        : 'Not Assigned'),
                icon: Icons.supervisor_account_outlined,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = AppColors.primaryNavy;
    final locationTitle = widget.location.clientName?.isNotEmpty == true
        ? widget.location.clientName!
        : widget.location.locationName;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/idealake_logo.png',
          height: 28,
          fit: BoxFit.contain,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) => current is AuthenticatedState,
            builder: (context, authState) {
              final user =
                  (authState is AuthenticatedState) ? authState.user : null;
              final userName = user?.name.trim() ?? 'User';
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    'Hi, $userName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final query = _searchController.text.trim();
          context.read<AdminBloc>().add(
                LoadEmployeesEvent(
                  isRefresh: true,
                  name: query.isNotEmpty ? query : null,
                ),
              );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Info Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: primaryNavy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locationTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (widget.location.city != null && widget.location.city!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.location.city!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar & Search Button
              _buildSearchBar(primaryNavy),
              const SizedBox(height: 16),

              // BlocBuilder for Employees List
              BlocBuilder<AdminBloc, AdminState>(
                builder: (context, state) {
                  if (state.isLoadingEmployees && state.employees.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: primaryNavy),
                            SizedBox(height: 14),
                            Text(
                              'Loading employees...',
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

                  final filteredEmployees = _getFilteredEmployees(state.employees);

                  if (filteredEmployees.isEmpty) {
                    final searchQuery = _searchController.text.trim();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 48,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'No employees matching "$searchQuery"'
                                : 'No employees assigned to this location',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Employees (${filteredEmployees.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      ...filteredEmployees.map((emp) => _buildEmployeeCard(emp, primaryNavy)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color primaryNavy) {
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
            onSubmitted: (_) => _performSearch(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search employee name...',
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
                      onPressed: _clearSearch,
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: _performSearch,
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
              backgroundColor: primaryNavy,
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

  Widget _buildEmployeeCard(CreatedEmployee emp, Color primaryNavy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEmployeeDetailsDialog(context, emp),
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 4px Accent Stripe
                Container(
                  width: 4,
                  color: primaryNavy,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            emp.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
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
}
