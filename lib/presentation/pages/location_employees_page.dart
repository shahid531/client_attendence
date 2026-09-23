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

  void _showUpdateEmployeeDialog(BuildContext context, CreatedEmployee employee) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return _UpdateEmployeeDialog(
          employee: employee,
          currentLocation: widget.location,
        );
      },
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
              hintText: 'Type Employee Name',
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
          onTap: () => _showUpdateEmployeeDialog(context, emp),
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
    final clientName = _clientNameController.text.trim();

    context.read<AdminBloc>().add(
          UpdateLocationSubmittedEvent(
            id: targetId,
            clientName: clientName,
            locationName: clientName,
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
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height * 0.88;

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

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: availableHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  SafeArea(
                    top: false,
                    child: Container(
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
                  ),
                ],
              ),
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

class _UpdateEmployeeDialog extends StatefulWidget {
  final CreatedEmployee employee;
  final ClientLocation currentLocation;

  const _UpdateEmployeeDialog({
    required this.employee,
    required this.currentLocation,
  });

  @override
  State<_UpdateEmployeeDialog> createState() => _UpdateEmployeeDialogState();
}

class _UpdateEmployeeDialogState extends State<_UpdateEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;

  CreatedEmployee? _selectedReportingManager;
  ClientLocation? _selectedLocation;
  late String _selectedRoleCode;
  bool _isEditing = false;
  String? _errorMessage;

  final List<Map<String, String>> _roleOptions = [
    {'label': 'RM (Relationship Manager)', 'code': 'RM'},
    {'label': 'EMPLOYEE', 'code': 'EMPLOYEE'},
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.employee.fullName);
    _employeeIdController =
        TextEditingController(text: widget.employee.employeeId);
    _emailController = TextEditingController(text: widget.employee.email);
    _contactController =
        TextEditingController(text: widget.employee.contactNumber ?? '');

    final matchingRole = _roleOptions.firstWhere(
      (r) => r['code']?.toUpperCase() == widget.employee.role.toUpperCase(),
      orElse: () => _roleOptions[1], // Default to EMPLOYEE
    );
    _selectedRoleCode = matchingRole['code']!;

    _selectedLocation = widget.currentLocation;

    final adminState = context.read<AdminBloc>().state;
    if (widget.employee.reportingManagerEmployeeId != null &&
        widget.employee.reportingManagerEmployeeId!.isNotEmpty) {
      try {
        _selectedReportingManager = adminState.employees.firstWhere(
          (e) =>
              e.employeeId.toLowerCase() ==
              widget.employee.reportingManagerEmployeeId!.toLowerCase(),
        );
      } catch (_) {
        _selectedReportingManager = null;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final nameChanged =
        _fullNameController.text.trim() != widget.employee.fullName.trim();
    final emailChanged =
        _emailController.text.trim() != widget.employee.email.trim();
    final contactChanged = _contactController.text.trim() !=
        (widget.employee.contactNumber ?? '').trim();
    final roleChanged =
        _selectedRoleCode.toUpperCase() != widget.employee.role.toUpperCase();
    final initialLocationId =
        widget.employee.locationId ?? widget.currentLocation.locationId;
    final locationChanged = _selectedLocation?.locationId != initialLocationId;
    final initialManagerId =
        widget.employee.reportingManagerEmployeeId?.trim().toLowerCase() ?? '';
    final currentManagerId =
        _selectedReportingManager?.employeeId.trim().toLowerCase() ?? '';
    final managerChanged = currentManagerId != initialManagerId;

    return nameChanged ||
        emailChanged ||
        contactChanged ||
        roleChanged ||
        locationChanged ||
        managerChanged;
  }

  void _resetToOriginalValues() {
    _errorMessage = null;
    _fullNameController.text = widget.employee.fullName;
    _emailController.text = widget.employee.email;
    _contactController.text = widget.employee.contactNumber ?? '';
    final matchingRole = _roleOptions.firstWhere(
      (r) => r['code']?.toUpperCase() == widget.employee.role.toUpperCase(),
      orElse: () => _roleOptions[1],
    );
    _selectedRoleCode = matchingRole['code']!;
    _selectedLocation = widget.currentLocation;

    final adminState = context.read<AdminBloc>().state;
    if (widget.employee.reportingManagerEmployeeId != null &&
        widget.employee.reportingManagerEmployeeId!.isNotEmpty) {
      try {
        _selectedReportingManager = adminState.employees.firstWhere(
          (e) =>
              e.employeeId.toLowerCase() ==
              widget.employee.reportingManagerEmployeeId!.toLowerCase(),
        );
      } catch (_) {
        _selectedReportingManager = null;
      }
    } else {
      _selectedReportingManager = null;
    }
  }

  void _onUpdatePressed() {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      final empId = widget.employee.id ??
          int.tryParse(widget.employee.employeeId) ??
          0;
      final selectedLocId = _selectedLocation?.locationId.isNotEmpty == true
          ? _selectedLocation!.locationId
          : (widget.employee.locationId ?? widget.currentLocation.locationId);

      context.read<AdminBloc>().add(
            UpdateEmployeeSubmittedEvent(
              id: empId,
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              contactNumber: _contactController.text.trim(),
              role: _selectedRoleCode,
              status: widget.employee.status?.isNotEmpty == true
                  ? widget.employee.status!
                  : 'ACTIVE',
              locationId: selectedLocId,
              reportingManagerEmployeeId:
                  _selectedReportingManager?.employeeId.isNotEmpty == true
                      ? _selectedReportingManager!.employeeId
                      : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: BlocConsumer<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state is UpdateEmployeeSuccessState) {
              Navigator.of(context).pop();
              SnackbarHelper.showSuccess(context, state.message);
            } else if (state is UpdateEmployeeFailureState) {
              setState(() {
                _errorMessage = state.message;
              });
              SnackbarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            final isSaving = state is UpdateEmployeeLoadingState;
            final isFieldEnabled = _isEditing && !isSaving;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppColors.primaryNavy.withValues(alpha: 0.1),
                        child: Text(
                          widget.employee.fullName.isNotEmpty
                              ? widget.employee.fullName
                                  .substring(0, 1)
                                  .toUpperCase()
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
                              _isEditing
                                  ? 'Edit Employee Details'
                                  : 'Employee Details',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${widget.employee.employeeId}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Inline Error Banner (Visible when API fails)
                if (_errorMessage != null && _errorMessage!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.dangerRose,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Scrollable Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name Field
                          _buildFieldLabel('Full Name'),
                          _buildInputField(
                            controller: _fullNameController,
                            hintText: 'Enter full name',
                            icon: Icons.person_outline,
                            showEditIcon: isFieldEnabled,
                            enabled: isFieldEnabled,
                            onChanged: (_) => setState(() {
                              _errorMessage = null;
                            }),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter full name';
                              }
                              return null;
                            },
                          ),

                          // Employee ID Field (Permanently Disabled)
                          _buildFieldLabel('Employee ID'),
                          _buildInputField(
                            controller: _employeeIdController,
                            hintText: 'Employee ID',
                            iconText: '#',
                            enabled: false,
                            suffixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 2, bottom: 14),
                            child: Text(
                              'Employee ID is unique and cannot be modified.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          // Official Email Field
                          _buildFieldLabel('Official Email'),
                          _buildInputField(
                            controller: _emailController,
                            hintText: 'Enter official email',
                            icon: Icons.email_outlined,
                            showEditIcon: isFieldEnabled,
                            keyboardType: TextInputType.emailAddress,
                            enabled: isFieldEnabled,
                            onChanged: (_) => setState(() {
                              _errorMessage = null;
                            }),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter official email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),

                          // Contact Number Field
                          _buildFieldLabel('Contact Number'),
                          _buildInputField(
                            controller: _contactController,
                            hintText: 'Enter contact number',
                            icon: Icons.phone_outlined,
                            showEditIcon: isFieldEnabled,
                            keyboardType: TextInputType.phone,
                            enabled: isFieldEnabled,
                            onChanged: (_) => setState(() {
                              _errorMessage = null;
                            }),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter contact number';
                              }
                              return null;
                            },
                          ),

                          // Role / Designation Dropdown
                          _buildFieldLabel('Role / Designation'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isFieldEnabled
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoleCode,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: isFieldEnabled
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                items: _roleOptions.map((roleMap) {
                                  return DropdownMenuItem<String>(
                                    value: roleMap['code'],
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.business_center_outlined,
                                          color: isFieldEnabled
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFFCBD5E1),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          roleMap['label']!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isFieldEnabled
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: isFieldEnabled
                                    ? (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _errorMessage = null;
                                            _selectedRoleCode = newValue;
                                          });
                                        }
                                      }
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Client Location Selector
                          _buildFieldLabel('Client Location'),
                          _buildLocationSelector(
                            context: context,
                            state: state,
                            isEnabled: isFieldEnabled,
                          ),
                          const SizedBox(height: 4),

                          // Reporting Manager Selector
                          _buildFieldLabel(
                            'Reporting Manager',
                            bottomPadding: 0,
                          ),
                          const SizedBox(height: 8),
                          _buildReportingManagerSelector(
                            context: context,
                            state: state,
                            isEnabled: isFieldEnabled,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Select a reporting manager or leave blank if none.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Dialog Action Buttons (Edit and Update in a Row)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Edit / Cancel Edit Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () {
                                    setState(() {
                                      if (_isEditing) {
                                        _resetToOriginalValues();
                                        _isEditing = false;
                                      } else {
                                        _isEditing = true;
                                      }
                                    });
                                  },
                            icon: Icon(
                              _isEditing
                                  ? Icons.close_rounded
                                  : Icons.edit_rounded,
                              size: 16,
                              color: _isEditing
                                  ? const Color(0xFF64748B)
                                  : AppColors.primaryNavy,
                            ),
                            label: Text(
                              _isEditing ? 'Cancel Edit' : 'Edit',
                              style: TextStyle(
                                color: _isEditing
                                    ? const Color(0xFF64748B)
                                    : AppColors.primaryNavy,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _isEditing
                                    ? const Color(0xFFCBD5E1)
                                    : AppColors.primaryNavy,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Update Button (Enabled only if editing and has changes)
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: (_isEditing && _hasChanges && !isSaving)
                                ? _onUpdatePressed
                                : null,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                            label: Text(
                              isSaving ? 'Updating...' : 'Update',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              disabledForegroundColor: Colors.white70,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {double bottomPadding = 8}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    IconData? icon,
    String? iconText,
    String? hintText,
    TextInputType? keyboardType,
    bool enabled = true,
    bool showEditIcon = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        validator: validator,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13.5,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: enabled
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFFCBD5E1),
                  size: 20,
                )
              : iconText != null
                  ? Container(
                      width: 44,
                      alignment: Alignment.center,
                      child: Text(
                        iconText,
                        style: TextStyle(
                          color: enabled
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFFCBD5E1),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
          suffixIcon: suffixIcon ??
              (showEditIcon
                  ? const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    )
                  : null),
          border: border,
          enabledBorder: border,
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.dangerRose, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.dangerRose, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLocationSelector({
    required BuildContext context,
    required AdminState state,
    required bool isEnabled,
  }) {
    final hasSelection = _selectedLocation != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: InkWell(
        onTap: isEnabled
            ? () => _openLocationPicker(
                  state.locations,
                  state.isLoadingLocations,
                  state.locationsError,
                )
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isEnabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (hasSelection && isEnabled)
                  ? AppColors.primaryNavy.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: isEnabled
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFFCBD5E1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasSelection
                    ? Text(
                        _selectedLocation!.clientName?.isNotEmpty == true
                            ? _selectedLocation!.clientName!
                            : _selectedLocation!.locationName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isEnabled
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : const Text(
                        'Select client location',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
              ),
              if (isEnabled)
                const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLocationPicker(
    List<ClientLocation> locations,
    bool isLoadingLocations,
    String? locationsError,
  ) async {
    if (locations.isEmpty && !isLoadingLocations) {
      context.read<AdminBloc>().add(const LoadLocationsEvent());
    }

    final result = await showModalBottomSheet<_LocationSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            return _LocationSearchModal(
              initialSelected: _selectedLocation,
              locations: state.locations,
              isLoading: state.isLoadingLocations,
              error: state.locationsError,
              onRetry: () {
                context
                    .read<AdminBloc>()
                    .add(const LoadLocationsEvent(isRefresh: true));
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result.location;
      });
    }
  }

  Widget _buildReportingManagerSelector({
    required BuildContext context,
    required AdminState state,
    required bool isEnabled,
  }) {
    final hasSelection = _selectedReportingManager != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: isEnabled
            ? () => _openReportingManagerPicker(
                  state.employees,
                  state.isLoadingEmployees,
                  state.employeesError,
                )
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isEnabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (hasSelection && isEnabled)
                  ? AppColors.primaryNavy.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.groups_outlined,
                color: isEnabled
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFFCBD5E1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasSelection
                    ? Text(
                        '${_selectedReportingManager!.fullName} (ID: ${_selectedReportingManager!.employeeId})',
                        style: TextStyle(
                          fontSize: 14,
                          color: isEnabled
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : const Text(
                        'Select reporting manager',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
              ),
              if (isEnabled)
                const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReportingManagerPicker(
    List<CreatedEmployee> employees,
    bool isLoadingEmployees,
    String? employeesError,
  ) async {
    if (employees.isEmpty && !isLoadingEmployees) {
      context.read<AdminBloc>().add(const LoadEmployeesEvent());
    }

    final result = await showModalBottomSheet<_EmployeeSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            return _ReportingManagerSearchModal(
              initialSelected: _selectedReportingManager,
              excludeEmployeeId: widget.employee.employeeId,
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
          _selectedReportingManager = null;
        } else {
          _selectedReportingManager = result.employee;
        }
      });
    }
  }
}

class _EmployeeSelectionResult {
  final bool isCleared;
  final CreatedEmployee? employee;

  const _EmployeeSelectionResult({
    this.isCleared = false,
    this.employee,
  });
}

class _ReportingManagerSearchModal extends StatefulWidget {
  final CreatedEmployee? initialSelected;
  final String? excludeEmployeeId;
  final List<CreatedEmployee> employees;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _ReportingManagerSearchModal({
    required this.initialSelected,
    this.excludeEmployeeId,
    required this.employees,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  State<_ReportingManagerSearchModal> createState() =>
      _ReportingManagerSearchModalState();
}

class _ReportingManagerSearchModalState
    extends State<_ReportingManagerSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredEmployees = widget.employees.where((emp) {
      if (widget.excludeEmployeeId != null &&
          widget.excludeEmployeeId!.trim().isNotEmpty &&
          emp.employeeId.trim().toLowerCase() ==
              widget.excludeEmployeeId!.trim().toLowerCase()) {
        return false;
      }
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Reporting Manager',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search by name, ID, or designation',
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
            const SizedBox(height: 12),
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
                    hintText: 'Search reporting manager...',
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
            Expanded(
              child: widget.isLoading && widget.employees.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
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
                              final isSelectedNone =
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
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.block_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'None (No Reporting Manager)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                subtitle: const Text(
                                  'Leave reporting manager unassigned',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                trailing: isSelectedNone
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primaryNavy,
                                        size: 22,
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.of(context).pop(
                                    const _EmployeeSelectionResult(
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
                                  employee.fullName.isNotEmpty
                                      ? employee.fullName
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : 'E',
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
                                  _EmployeeSelectionResult(
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

class _LocationSelectionResult {
  final ClientLocation? location;

  const _LocationSelectionResult({
    this.location,
  });
}

class _LocationSearchModal extends StatefulWidget {
  final ClientLocation? initialSelected;
  final List<ClientLocation> locations;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _LocationSearchModal({
    required this.initialSelected,
    required this.locations,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  State<_LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<_LocationSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredLocations = widget.locations.where((loc) {
      if (query.isEmpty) return true;
      final nameMatches = loc.locationName.toLowerCase().contains(query);
      final clientMatches =
          loc.clientName?.toLowerCase().contains(query) ?? false;
      final addressMatches =
          loc.address?.toLowerCase().contains(query) ?? false;
      final cityMatches = loc.city?.toLowerCase().contains(query) ?? false;
      return nameMatches || clientMatches || addressMatches || cityMatches;
    }).toList();

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Client Location',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search by client name, location, or city',
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
            const SizedBox(height: 12),
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
                    hintText: 'Search client location...',
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
            Expanded(
              child: widget.isLoading && widget.locations.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : widget.error != null && widget.locations.isEmpty
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
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: filteredLocations.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 64,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final loc = filteredLocations[index];
                            final isSelected = widget.initialSelected != null &&
                                ((loc.locationId.isNotEmpty &&
                                        loc.locationId ==
                                            widget
                                                .initialSelected!.locationId) ||
                                    (loc.clientName != null &&
                                        loc.clientName ==
                                            widget.initialSelected!
                                                .clientName));

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
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
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primaryNavy,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                loc.clientName?.isNotEmpty == true
                                    ? loc.clientName!
                                    : loc.locationName,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (loc.locationName.isNotEmpty &&
                                      loc.locationName != loc.clientName)
                                    Text(
                                      loc.locationName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  if (loc.city != null &&
                                      loc.city!.isNotEmpty)
                                    Text(
                                      loc.city!,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                ],
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
                                  _LocationSelectionResult(location: loc),
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

