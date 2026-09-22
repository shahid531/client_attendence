import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
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

  // Tab Index: 0 for Add Employee, 1 for Bulk Upload
  int _selectedTabIndex = 0;
  PlatformFile? _selectedBulkFile;
  String? _downloadedSamplePath;

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
        } else if (state is BulkSampleDownloadSuccessState) {
          setState(() {
            _downloadedSamplePath = state.filePath;
          });
          final fileName = state.filePath.split('/').last.split('\\').last;
          SnackbarHelper.showSuccess(
            context,
            'Template saved to Downloads: $fileName',
          );
          _openOrShareDownloadedFile(state.filePath);
        } else if (state is BulkSampleDownloadFailureState) {
          SnackbarHelper.showError(context, state.message);
        } else if (state is BulkUploadSuccessState) {
          _showBulkUploadSuccessDialog(context, state.message, state.data);
        } else if (state is BulkUploadFailureState) {
          SnackbarHelper.showError(context, state.message);
        } else if (state is AdminFailureState) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AdminLoadingState;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                    children: [
                      Text(
                        _selectedTabIndex == 0
                            ? 'Create Employee'
                            : 'Bulk Upload',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTabIndex == 0
                            ? 'Enter employee details below to set up their\naccount.'
                            : 'Upload an Excel or CSV file to add multiple\nemployees at once.',
                        style: const TextStyle(
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

              // Tab Toggle (Add Employee / Bulk Upload)
              _buildTabToggle(),
              const SizedBox(height: 16),

              // Tab Content
              if (_selectedTabIndex == 0)
                _buildAddEmployeeForm(context, state, isLoading)
              else
                _buildBulkUploadView(context, state),
            ],
          ),
        );
      },
    );
  }

  // Segmented Tab Toggle (similar to ApprovalsScreen)
  Widget _buildTabToggle() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != 0) {
                  setState(() => _selectedTabIndex = 0);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? Colors.white
                      : Colors.transparent,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 16,
                      color: _selectedTabIndex == 0
                          ? AppColors.primaryNavy
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add Employee',
                      style: TextStyle(
                        fontWeight: _selectedTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedTabIndex == 0
                            ? AppColors.primaryNavy
                            : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != 1) {
                  setState(() => _selectedTabIndex = 1);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? Colors.white
                      : Colors.transparent,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 16,
                      color: _selectedTabIndex == 1
                          ? AppColors.primaryNavy
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Bulk Upload',
                      style: TextStyle(
                        fontWeight: _selectedTabIndex == 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedTabIndex == 1
                            ? AppColors.primaryNavy
                            : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Single Employee Form View
  Widget _buildAddEmployeeForm(
    BuildContext context,
    AdminState state,
    bool isLoading,
  ) {
    return Form(
      key: _formKey,
      child: Container(
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
              hintText: 'Enter name',
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
              hintText: 'Enter Employee ID',
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
              hintText: 'Enter Email ID',
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
              hintText: 'Enter Contact Number',
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
    );
  }

  // Bulk Upload View
  Widget _buildBulkUploadView(BuildContext context, AdminState state) {
    final isDownloadingSample = state is BulkSampleDownloadLoadingState;
    final isUploadingBulk = state is BulkUploadLoadingState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Download Sample Template Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.table_chart_rounded,
                      color: AppColors.primaryNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Step 1: Download Template',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Get the sample Excel spreadsheet with required columns.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: (isDownloadingSample || isUploadingBulk)
                      ? null
                      : () {
                          context
                              .read<AdminBloc>()
                              .add(const DownloadBulkSampleEvent());
                        },
                  icon: isDownloadingSample
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryNavy,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.download_rounded,
                          size: 18,
                          color: AppColors.primaryNavy,
                        ),
                  label: Text(
                    isDownloadingSample
                        ? 'Downloading Sample Template...'
                        : 'Download Sample Excel Template',
                    style: const TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primaryNavy,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor:
                        AppColors.primaryNavy.withValues(alpha: 0.04),
                  ),
                ),
              ),
              if (_downloadedSamplePath != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saved: ${_downloadedSamplePath!.split('/').last.split('\\').last}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () => _openOrShareDownloadedFile(
                          _downloadedSamplePath!,
                        ),
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        label: const Text(
                          'Open',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card 2: Upload File Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: Color(0xFF059669),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Step 2: Upload Employee File',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Upload the completed Excel (.xlsx) or CSV file.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Dropzone / File Selector Container
              InkWell(
                onTap: isUploadingBulk ? null : _pickBulkFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedBulkFile != null
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedBulkFile != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFFCBD5E1),
                      width: _selectedBulkFile != null ? 1.5 : 1,
                    ),
                  ),
                  child: _selectedBulkFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy
                                    .withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.folder_open_rounded,
                                color: AppColors.primaryNavy,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Click to Browse & Select File',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Supports .xlsx, .xls, and .csv files',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_rounded,
                                color: Color(0xFF047857),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedBulkFile!.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatFileSize(_selectedBulkFile!.size),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: Color(0xFF94A3B8),
                                size: 22,
                              ),
                              tooltip: 'Remove file',
                              onPressed: isUploadingBulk
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedBulkFile = null;
                                      });
                                    },
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Upload Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_selectedBulkFile == null || isUploadingBulk)
                      ? null
                      : _onUploadBulkPressed,
                  icon: isUploadingBulk
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.upload_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: isUploadingBulk
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
                          'Upload & Create Employees',
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
                    disabledBackgroundColor:
                        AppColors.primaryNavy.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card 3: Instructions & Tips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.primaryNavy,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Bulk Upload Guidelines',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildGuidelineItem(
                '1',
                'Download the sample template file to ensure column headers match exactly.',
              ),
              const SizedBox(height: 6),
              _buildGuidelineItem(
                '2',
                'Required fields include Full Name, Employee ID, Official Email, Role, and Location ID.',
              ),
              const SizedBox(height: 6),
              _buildGuidelineItem(
                '3',
                'Temporary credentials will be generated for all successfully uploaded accounts.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelineItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickBulkFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedBulkFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to select file: $e');
      }
    }
  }

  void _onUploadBulkPressed() {
    if (_selectedBulkFile == null) {
      SnackbarHelper.showError(context, 'Please select an Excel or CSV file');
      return;
    }

    final path = _selectedBulkFile!.path ?? '';
    final name = _selectedBulkFile!.name;
    final bytes = _selectedBulkFile!.bytes;

    context.read<AdminBloc>().add(
          BulkUploadEmployeesEvent(
            filePath: path,
            fileName: name,
            fileBytes: bytes,
          ),
        );
  }

  Future<void> _openOrShareDownloadedFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Employee Bulk Upload Sample Template',
        );
      }
    } catch (_) {
      try {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Employee Bulk Upload Sample Template',
        );
      } catch (_) {}
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showBulkUploadSuccessDialog(
    BuildContext context,
    String message,
    Map<String, dynamic>? data,
  ) {
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
                'Bulk Upload Completed!',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
              if (data != null && data.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: data.entries.map((e) {
                      if (e.value is Map || e.value is List) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.key.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              e.value.toString(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
                  setState(() {
                    _selectedBulkFile = null;
                  });
                  context
                      .read<AdminBloc>()
                      .add(const ResetBulkUploadStateEvent());
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
          city: result.city,
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
