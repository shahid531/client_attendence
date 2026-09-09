import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../domain/entities/created_employee.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _fullNameController = TextEditingController(text: 'Ashish Singh');
  final _employeeIdController = TextEditingController(text: '20179');
  final _emailController = TextEditingController(text: 'ashish3@idealake.com');
  final _contactController = TextEditingController(text: '1111111221');
  final _locationIdController = TextEditingController(text: '001');
  final _reportingManagerController = TextEditingController();

  final List<Map<String, String>> _roleOptions = [
    {'label': 'RM (Relationship Manager)', 'code': 'RM'},
    {'label': 'EMPLOYEE', 'code': 'EMPLOYEE'},
    {'label': 'Admin', 'code': 'ADMIN'},
  ];

  late String _selectedRoleCode;

  @override
  void initState() {
    super.initState();
    _selectedRoleCode = _roleOptions.first['code']!;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _locationIdController.dispose();
    _reportingManagerController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _fullNameController.clear();
    _employeeIdController.clear();
    _emailController.clear();
    _contactController.clear();
    _locationIdController.clear();
    _reportingManagerController.clear();
    setState(() {
      _selectedRoleCode = _roleOptions.first['code']!;
    });
  }

  void _onCreateEmployeePressed() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AdminBloc>().add(
            CreateEmployeeSubmittedEvent(
              fullName: _fullNameController.text.trim(),
              employeeId: _employeeIdController.text.trim(),
              email: _emailController.text.trim(),
              contactNumber: _contactController.text.trim(),
              locationId: _locationIdController.text.trim(),
              role: _selectedRoleCode,
              reportingManagerEmployeeId:
                  _reportingManagerController.text.trim().isNotEmpty
                      ? _reportingManagerController.text.trim()
                      : null,
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
                    if (employee.locationName != null || employee.locationId != null) ...[
                      const Divider(height: 16),
                      _buildDialogRow(
                        'Location',
                        employee.locationName ?? employee.locationId ?? '-',
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

                      // Location ID
                      _buildFieldLabel('Location ID'),
                      _buildInputField(
                        controller: _locationIdController,
                        hintText: 'e.g. 001',
                        icon: Icons.location_on_outlined,
                        enabled: !isLoading,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter location ID';
                          }
                          return null;
                        },
                      ),

                      // Reporting Manager ID (Optional)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel(
                            'Reporting Manager ID',
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
                      _buildInputField(
                        controller: _reportingManagerController,
                        hintText: 'e.g. EMP-1002 (Optional)',
                        icon: Icons.groups_outlined,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Leave blank if no reporting manager is assigned.',
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
