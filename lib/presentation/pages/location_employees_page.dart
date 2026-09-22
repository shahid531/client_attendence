import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../domain/entities/client_location.dart';
import '../../domain/entities/created_employee.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../widgets/location_picker_dialog.dart';

class LocationEmployeesPage extends StatefulWidget {
  final ClientLocation location;
  final VoidCallback? onBack;

  const LocationEmployeesPage({
    super.key,
    required this.location,
    this.onBack,
  });

  @override
  State<LocationEmployeesPage> createState() => _LocationEmployeesPageState();
}

class _LocationEmployeesPageState extends State<LocationEmployeesPage> {
  final TextEditingController _searchController = TextEditingController();
  late ClientLocation _currentLocation;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBloc>().add(const LoadEmployeesEvent());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openUpdateLocationModal() async {
    final updated = await showModalBottomSheet<ClientLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => _UpdateLocationSheet(
        location: _currentLocation,
        onLocationUpdated: (newLoc) {
          Navigator.of(modalCtx).pop(newLoc);
        },
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentLocation = updated;
      });
      context.read<AdminBloc>().add(const LoadLocationsEvent(isRefresh: true));
    }
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
    final location = _currentLocation;

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

    Widget content = RefreshIndicator(
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
            // Back Button Row (when embedded inside tab)
            if (widget.onBack != null) ...[
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 13,
                        color: AppColors.primaryNavy,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Back to Locations',
                        style: TextStyle(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Location Info Card (Map Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Location Pin Icon Container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: primaryNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Client Name & City
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentLocation.clientName?.isNotEmpty == true
                              ? _currentLocation.clientName!
                              : _currentLocation.locationName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_currentLocation.city != null &&
                            _currentLocation.city!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _currentLocation.city!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Status Badge & Edit Icon Button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (_currentLocation.status?.toUpperCase() ==
                                      'ACTIVE' ||
                                  _currentLocation.status == null)
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _currentLocation.status?.toUpperCase() ?? 'ACTIVE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: (_currentLocation.status?.toUpperCase() ==
                                        'ACTIVE' ||
                                    _currentLocation.status == null)
                                ? const Color(0xFF15803D)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Edit Icon Button
                      InkWell(
                        onTap: _openUpdateLocationModal,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: primaryNavy,
                          ),
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
      );

    if (widget.onBack != null) {
      return content;
    }

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
      body: content,
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

class _UpdateLocationSheet extends StatefulWidget {
  final ClientLocation location;
  final ValueChanged<ClientLocation> onLocationUpdated;

  const _UpdateLocationSheet({
    required this.location,
    required this.onLocationUpdated,
  });

  @override
  State<_UpdateLocationSheet> createState() => _UpdateLocationSheetState();
}

class _UpdateLocationSheetState extends State<_UpdateLocationSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _clientNameController;
  late final TextEditingController _locationNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _radiusController;
  late final TextEditingController _halfDayController;
  late final TextEditingController _fullDayController;

  late String _status;

  @override
  void initState() {
    super.initState();
    _clientNameController =
        TextEditingController(text: widget.location.clientName ?? '');
    _locationNameController =
        TextEditingController(text: widget.location.locationName);
    _addressController =
        TextEditingController(text: widget.location.address ?? '');
    _cityController = TextEditingController(text: widget.location.city ?? '');
    _latController = TextEditingController(
      text: widget.location.latitude != null
          ? widget.location.latitude!.toString()
          : '',
    );
    _lngController = TextEditingController(
      text: widget.location.longitude != null
          ? widget.location.longitude!.toString()
          : '',
    );
    _radiusController = TextEditingController(
      text: widget.location.allowedRadius != null
          ? (widget.location.allowedRadius! % 1 == 0
              ? widget.location.allowedRadius!.toInt().toString()
              : widget.location.allowedRadius!.toString())
          : '120.0',
    );
    _halfDayController = TextEditingController(
      text: widget.location.halfDayHrs != null
          ? (widget.location.halfDayHrs! % 1 == 0
              ? widget.location.halfDayHrs!.toInt().toString()
              : widget.location.halfDayHrs!.toString())
          : '5.0',
    );
    _fullDayController = TextEditingController(
      text: widget.location.fullDayHrs != null
          ? (widget.location.fullDayHrs! % 1 == 0
              ? widget.location.fullDayHrs!.toInt().toString()
              : widget.location.fullDayHrs!.toString())
          : '9.0',
    );
    _status = (widget.location.status != null &&
            widget.location.status!.trim().isNotEmpty)
        ? widget.location.status!.toUpperCase()
        : 'ACTIVE';
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _halfDayController.dispose();
    _fullDayController.dispose();
    super.dispose();
  }

  Future<void> _pickOnGoogleMap() async {
    final curLat = double.tryParse(_latController.text.trim()) ??
        widget.location.latitude;
    final curLng = double.tryParse(_lngController.text.trim()) ??
        widget.location.longitude;
    final curRadius = double.tryParse(_radiusController.text.trim()) ??
        widget.location.allowedRadius;

    final result = await LocationPickerDialog.show(
      context,
      initialLatitude: curLat,
      initialLongitude: curLng,
      initialLocationName: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : widget.location.address,
      initialClientName: _clientNameController.text.trim().isNotEmpty
          ? _clientNameController.text.trim()
          : widget.location.clientName,
      initialRadius: curRadius,
      enableCreateLocation: false,
    );

    if (result != null && mounted) {
      setState(() {
        _latController.text = result.latitude.toString();
        _lngController.text = result.longitude.toString();
        if (result.address != null && result.address!.isNotEmpty) {
          _addressController.text = result.address!;
        }
        if (result.city != null && result.city!.isNotEmpty) {
          _cityController.text = result.city!;
        }
      });
    }
  }

  void _onSavePressed() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim()) ?? 120.0;
    final halfDay = double.tryParse(_halfDayController.text.trim()) ?? 5.0;
    final fullDay = double.tryParse(_fullDayController.text.trim()) ?? 9.0;

    if (lat == null || lng == null) {
      SnackbarHelper.showError(
        context,
        'Please enter valid latitude and longitude coordinates',
      );
      return;
    }

    final targetId = widget.location.id ?? widget.location.locationId;

    context.read<AdminBloc>().add(
          UpdateLocationSubmittedEvent(
            id: targetId,
            clientName: _clientNameController.text.trim(),
            locationName: _locationNameController.text.trim().isNotEmpty
                ? _locationNameController.text.trim()
                : (_clientNameController.text.trim().isNotEmpty
                    ? _clientNameController.text.trim()
                    : widget.location.locationName),
            address: _addressController.text.trim(),
            city: _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : null,
            latitude: lat,
            longitude: lng,
            allowedRadius: radius,
            halfDayHrs: halfDay,
            fullDayHrs: fullDay,
            status: _status,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is UpdateLocationSuccessState) {
          SnackbarHelper.showSuccess(context, state.message);
          widget.onLocationUpdated(state.updatedLocation);
        } else if (state is UpdateLocationFailureState) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is UpdateLocationLoadingState;

        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.88,
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
                            'Update Location & Coordinates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Edit site info or pick on map',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
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
                const Divider(height: 16, color: Color(0xFFE2E8F0)),

                // Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pick on Google Map Action Banner
                          InkWell(
                            onTap: isLoading ? null : _pickOnGoogleMap,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryNavy
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryNavy,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.map_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Pick / Adjust on Google Map',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryNavy,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Update coordinates & address via interactive map',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.primaryNavy,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Client Name
                          _buildFieldLabel('Client Name'),
                          _buildTextInputField(
                            controller: _clientNameController,
                            hint: 'e.g. Global Enterprise Corp',
                            icon: Icons.business_outlined,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Client name is required';
                              }
                              return null;
                            },
                          ),

                          // Address
                          _buildFieldLabel('Address'),
                          _buildTextInputField(
                            controller: _addressController,
                            hint: 'e.g. Building 3, Sector 5, Mindspace, Mumbai',
                            icon: Icons.place_outlined,
                            enabled: false,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Address is required';
                              }
                              return null;
                            },
                          ),

                          // City
                          _buildFieldLabel('City'),
                          _buildTextInputField(
                            controller: _cityController,
                            hint: 'e.g. Mumbai',
                            icon: Icons.location_on_outlined,
                            enabled: false,
                          ),

                          // Latitude & Longitude
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Latitude'),
                                    _buildTextInputField(
                                      controller: _latController,
                                      hint: '19.0760',
                                      enabled: false,
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                      icon: Icons.explore_outlined,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(val) == null) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Longitude'),
                                    _buildTextInputField(
                                      controller: _lngController,
                                      hint: '72.8777',
                                      enabled: false,
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                      icon: Icons.explore_outlined,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(val) == null) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Allowed Radius & Status
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Allowed Radius (m)'),
                                    _buildTextInputField(
                                      controller: _radiusController,
                                      hint: '120.0',
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      icon: Icons.radar_rounded,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(val) == null) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Status'),
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _status,
                                          isExpanded: true,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF64748B),
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'ACTIVE',
                                              child: Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF15803D),
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'INACTIVE',
                                              child: Text(
                                                'INACTIVE',
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _status = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Half-Day & Full-Day Hours
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Half Day Hrs'),
                                    _buildTextInputField(
                                      controller: _halfDayController,
                                      hint: '5.0',
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      icon: Icons.timelapse_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Full Day Hrs'),
                                    _buildTextInputField(
                                      controller: _fullDayController,
                                      hint: '9.0',
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      icon: Icons.access_time_filled_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Action Button
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Update Location and Coordinates',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 13.5,
          color: enabled ? const Color(0xFF0F172A) : const Color(0xFF475569),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: const Color(0xFF94A3B8),
                  size: 18,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.primaryNavy, width: 1.5),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.dangerRose, width: 1),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.dangerRose, width: 1.5),
          ),
        ),
      ),
    );
  }
}
