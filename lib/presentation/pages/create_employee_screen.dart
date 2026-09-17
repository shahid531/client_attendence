import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../domain/entities/client_location.dart';
import '../../domain/entities/created_employee.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
import '../widgets/location_picker_dialog.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _fullNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  CreatedEmployee? _selectedReportingManager;
  ClientLocation? _selectedLocation;

  final List<Map<String, String>> _roleOptions = [
    {'label': 'RM (Relationship Manager)', 'code': 'RM'},
    {'label': 'EMPLOYEE', 'code': 'EMPLOYEE'},
    {'label': 'ADMIN', 'code': 'ADMIN'},
  ];

  late String _selectedRoleCode;

  @override
  void initState() {
    super.initState();
    _selectedRoleCode = _roleOptions.first['code']!;
    context.read<AdminBloc>().add(const LoadEmployeesEvent());
    context.read<AdminBloc>().add(const LoadLocationsEvent());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _fullNameController.clear();
    _employeeIdController.clear();
    _emailController.clear();
    _contactController.clear();
    setState(() {
      _selectedRoleCode = _roleOptions.first['code']!;
      _selectedReportingManager = null;
      _selectedLocation = null;
    });
  }

  void _onCreateEmployeePressed() {
    FocusScope.of(context).unfocus();

    if (_selectedLocation == null) {
      SnackbarHelper.showError(
        context,
        'Please select a client location',
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AdminBloc>().add(
            CreateEmployeeSubmittedEvent(
              fullName: _fullNameController.text.trim(),
              employeeId: _employeeIdController.text.trim(),
              email: _emailController.text.trim(),
              contactNumber: _contactController.text.trim(),
              locationId: _selectedLocation!.locationId,
              locationName: _selectedLocation!.locationName,
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
              role: _selectedRoleCode,
              reportingManagerEmployeeId: _selectedReportingManager?.employeeId,
            ),
          );
    }
  }

  void _showSuccessDialog(BuildContext context, CreatedEmployee employee) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successEmerald,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Employee Created!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Account for ${employee.fullName} has been successfully generated.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // Details Summary Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('Employee ID', employee.employeeId),
                    const Divider(height: 16),
                    _buildDialogRow('Email', employee.email),
                    const Divider(height: 16),
                    _buildDialogRow('Role', employee.role),
                    if (employee.reportingManagerName != null || employee.reportingManagerEmployeeId != null) ...[
                      const Divider(height: 16),
                      _buildDialogRow(
                        'Reporting Manager',
                        employee.reportingManagerName ?? employee.reportingManagerEmployeeId ?? '-',
                      ),
                    ],
                    if (employee.locationName != null || employee.locationId != null) ...[
                      const Divider(height: 16),
                      _buildDialogRow(
                        'Location',
                        employee.locationName ?? employee.locationId ?? '-',
                      ),
                    ],
                    if (employee.latitude != null && employee.longitude != null) ...[
                      const Divider(height: 16),
                      _buildDialogRow(
                        'Coordinates',
                        '${employee.latitude!.toStringAsFixed(4)}, ${employee.longitude!.toStringAsFixed(4)}',
                      ),
                    ],
                  ],
                ),
              ),

              if (employee.temporaryPassword != null &&
                  employee.temporaryPassword!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.key_rounded,
                            size: 16,
                            color: Color(0xFF92400E),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Temporary Password',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SelectableText(
                              employee.temporaryPassword!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: Color(0xFF92400E),
                            ),
                            tooltip: 'Copy password',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: employee.temporaryPassword!,
                                ),
                              );
                              SnackbarHelper.showSuccess(
                                context,
                                'Temporary password copied!',
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  _resetForm();
                  context.read<AdminBloc>().add(ResetAdminStateEvent());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is CreateEmployeeSuccessState) {
          _showSuccessDialog(context, state.employee);
        } else if (state is AdminFailureState) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AdminLoadingState;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header with Title and Admin Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Create Employee',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enter employee details below to set up their\naccount.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      _buildFieldLabel('Full Name'),
                      _buildInputField(
                        controller: _fullNameController,
                        hintText: 'e.g. Ashish Singh',
                        icon: Icons.person_outline,
                        enabled: !isLoading,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter full name';
                          }
                          return null;
                        },
                      ),

                      // Employee ID
                      _buildFieldLabel('Employee ID'),
                      _buildInputField(
                        controller: _employeeIdController,
                        hintText: 'e.g. 20179',
                        iconText: '#',
                        enabled: !isLoading,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter employee ID';
                          }
                          return null;
                        },
                      ),

                      // Official Email
                      _buildFieldLabel('Official Email'),
                      _buildInputField(
                        controller: _emailController,
                        hintText: 'e.g. ashish3@idealake.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
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

                      // Contact Number
                      _buildFieldLabel('Contact Number'),
                      _buildInputField(
                        controller: _contactController,
                        hintText: 'e.g. 1111111221',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        enabled: !isLoading,
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
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRoleCode,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            items: _roleOptions.map((roleMap) {
                              return DropdownMenuItem<String>(
                                value: roleMap['code'],
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.business_center_outlined,
                                      color: Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      roleMap['label']!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: isLoading
                                ? null
                                : (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedRoleCode = newValue;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Client Location (Searchable Dropdown)
                      _buildFieldLabel('Client Location'),
                      _buildLocationSelector(
                        context: context,
                        state: state,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 4),
                      // Reporting Manager (Searchable Dropdown)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel(
                            'Reporting Manager',
                            bottomPadding: 0,
                          ),
                          const Text(
                            'Optional',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildReportingManagerSelector(
                        context: context,
                        state: state,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select a reporting manager or leave blank if none.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _onCreateEmployeePressed,
                          icon: isLoading
                              ? const SizedBox.shrink()
                              : const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          label: isLoading
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
                                  'Create Employee',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : _resetForm,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Client Location Searchable Dropdown Trigger Field
  Widget _buildLocationSelector({
    required BuildContext context,
    required AdminState state,
    required bool isLoading,
  }) {
    final hasSelection = _selectedLocation != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: isLoading
            ? null
            : () => _openLocationPicker(
                  state.locations,
                  state.isLoadingLocations,
                  state.locationsError,
                ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isLoading ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasSelection
                  ? AppColors.primaryNavy.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            crossAxisAlignment: hasSelection
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: hasSelection ? 2.0 : 0.0),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasSelection
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _selectedLocation!.clientName?.isNotEmpty == true
                                      ? _selectedLocation!.clientName!
                                      : _selectedLocation!.locationName,
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
                                  color: AppColors.primaryNavy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Radius: ${_selectedLocation!.allowedRadius != null ? (_selectedLocation!.allowedRadius! % 1 == 0 ? _selectedLocation!.allowedRadius!.toInt().toString() : _selectedLocation!.allowedRadius!.toString()) : '100'}m',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primaryNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedLocation!.locationName.isNotEmpty &&
                              _selectedLocation!.locationName != _selectedLocation!.clientName) ...[
                            const SizedBox(height: 2),
                            Text(
                              _selectedLocation!.locationName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (_selectedLocation!.address != null &&
                              _selectedLocation!.address!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _selectedLocation!.address!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (_selectedLocation!.latitude != null &&
                              _selectedLocation!.longitude != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.explore_outlined,
                                  size: 13,
                                  color: AppColors.primaryNavy,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedLocation!.latitude!.toStringAsFixed(4)}, ${_selectedLocation!.longitude!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primaryNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      )
                    : const Text(
                        'Search client location',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
              ),
              if (hasSelection && !isLoading)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedLocation = null;
                    });
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
                context.read<AdminBloc>().add(const LoadLocationsEvent(isRefresh: true));
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

  // Reporting Manager Searchable Dropdown Trigger Field
  Widget _buildReportingManagerSelector({
    required BuildContext context,
    required AdminState state,
    required bool isLoading,
  }) {
    final hasSelection = _selectedReportingManager != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: isLoading
            ? null
            : () => _openReportingManagerPicker(
                  state.employees,
                  state.isLoadingEmployees,
                  state.employeesError,
                ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isLoading ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasSelection
                  ? AppColors.primaryNavy.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasSelection
                    ? Row(
                        children: [
                          Flexible(
                            child: Text(
                              _selectedReportingManager!.fullName,
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
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: ${_selectedReportingManager!.employeeId}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Search reporting manager',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
              ),
              if (hasSelection && !isLoading)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedReportingManager = null;
                    });
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
      ),
    );
  }

  Future<void> _openReportingManagerPicker(
    List<CreatedEmployee> employees,
    bool isLoadingEmployees,
    String? employeesError,
  ) async {
    // If employees list is empty and not already loading, trigger load
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
              employees: state.employees,
              isLoading: state.isLoadingEmployees,
              error: state.employeesError,
              onRetry: () {
                context.read<AdminBloc>().add(const LoadEmployeesEvent(isRefresh: true));
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

  // Label Helper Widget
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

  // Text Input Field Helper Widget
  Widget _buildInputField({
    required TextEditingController controller,
    IconData? icon,
    String? iconText,
    String? hintText,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF94A3B8), size: 20)
                : iconText != null
                    ? Center(
                        widthFactor: 1.0,
                        child: Text(
                          iconText,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
            border: InputBorder.none,
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.dangerRose),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.dangerRose, width: 1.5),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
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
  final List<CreatedEmployee> employees;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _ReportingManagerSearchModal({
    required this.initialSelected,
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
                      'Select Reporting Manager',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Search by full name, ID, or designation',
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
                          'Loading managers...',
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
                                    'No managers found matching "$query"',
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

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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

  Future<void> _pickOnGoogleMap() async {
    final result = await LocationPickerDialog.show(
      context,
      initialLatitude: widget.initialSelected?.latitude,
      initialLongitude: widget.initialSelected?.longitude,
      initialLocationName: widget.initialSelected?.locationName ??
          widget.initialSelected?.address,
      initialClientName: widget.initialSelected?.clientName,
      initialRadius: widget.initialSelected?.allowedRadius,
    );

    if (result != null && mounted) {
      if (result.createdLocation != null) {
        context.read<AdminBloc>().add(const LoadLocationsEvent(isRefresh: true));
        Navigator.of(context).pop(_LocationSelectionResult(location: result.createdLocation));
      } else {
        final locName = result.address?.isNotEmpty == true
            ? result.address!
            : 'Map Pin (${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)})';
        final customLoc = ClientLocation(
          locationId: 'LOC_${(result.latitude * 1000).toInt().abs()}',
          clientName: result.clientName ?? 'Map Selected Location',
          locationName: locName,
          address: result.address,
          latitude: result.latitude,
          longitude: result.longitude,
          allowedRadius: result.allowedRadius ?? 100.0,
          status: 'Active',
        );

        Navigator.of(context).pop(_LocationSelectionResult(location: customLoc));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredLocations = widget.locations.where((loc) {
      if (query.isEmpty) return true;
      final clientMatches = loc.clientName?.toLowerCase().contains(query) ?? false;
      final locNameMatches = loc.locationName.toLowerCase().contains(query);
      final idMatches = loc.locationId.toLowerCase().contains(query);
      final addressMatches = loc.address?.toLowerCase().contains(query) ?? false;
      return clientMatches || locNameMatches || idMatches || addressMatches;
    }).toList();

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
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
                        'Select Client Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search by client name, location, address or ID',
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
            const SizedBox(height: 10),

            // Google Map Action Banner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickOnGoogleMap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryNavy.withValues(alpha: 0.08),
                          AppColors.primaryNavy.withValues(alpha: 0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryNavy.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(10),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Pick on Google Map',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Choose or pinpoint custom location on map',
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
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Body List
            Expanded(
              child: widget.isLoading && widget.locations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text(
                            'Loading client locations...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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
                      : filteredLocations.isEmpty && query.isNotEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_off_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No locations found matching "$query"',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Try searching with a different client name, ID, or city.',
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
                                vertical: 8,
                              ),
                              itemCount: filteredLocations.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 60,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (context, index) {
                                final location = filteredLocations[index];
                                final isSelected =
                                    widget.initialSelected?.locationId ==
                                        location.locationId;

                                final displayName =
                                    location.clientName?.isNotEmpty == true
                                        ? location.clientName!
                                        : location.locationName;
                                final subTitleParts = <String>[];
                                if (location.locationName.isNotEmpty &&
                                    location.locationName != location.clientName) {
                                  subTitleParts.add(location.locationName);
                                }
                                if (location.address != null &&
                                    location.address!.isNotEmpty) {
                                  subTitleParts.add(location.address!);
                                }
                                final subtitleText = subTitleParts.join(' • ');

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
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.primaryNavy,
                                      size: 22,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryNavy
                                              .withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Radius: ${location.allowedRadius != null ? (location.allowedRadius! % 1 == 0 ? location.allowedRadius!.toInt().toString() : location.allowedRadius!.toString()) : '100'}m',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryNavy,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (subtitleText.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitleText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (location.latitude != null &&
                                          location.longitude != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Lat: ${location.latitude!.toStringAsFixed(4)}, Lng: ${location.longitude!.toStringAsFixed(4)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
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
                                      _LocationSelectionResult(
                                        location: location,
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
