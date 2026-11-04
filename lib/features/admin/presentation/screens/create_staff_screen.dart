import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../auth/domain/staff_role.dart';
import '../controllers/staff_management_controller.dart';

/// Screen allowing administrators to provision new staff accounts.
class CreateStaffScreen extends ConsumerStatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  ConsumerState<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends ConsumerState<CreateStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StaffRole _selectedRole = StaffRole.registrationOfficer;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateStaff() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final createdProfile =
        await ref.read(staffManagementControllerProvider.notifier).createStaff(
              name: _nameController.text,
              email: _emailController.text,
              role: _selectedRole,
              temporaryPassword: _passwordController.text,
            );

    if (mounted) {
      if (createdProfile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Staff account for ${createdProfile.name} created successfully.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      } else {
        final state = ref.read(staffManagementControllerProvider);
        if (state.hasError) {
          setState(() {
            _errorMessage = state.error.toString();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controllerState = ref.watch(staffManagementControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provision Staff Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Staff Member Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create a university staff account with authorized role permissions.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 20,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Abebe Bikila',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 16),

                    // Staff Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Staff Email Address',
                        hintText: 'staff@aau.edu.et',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Role Dropdown
                    DropdownButtonFormField<StaffRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Role',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: StaffRole.values.map((role) {
                        return DropdownMenuItem<StaffRole>(
                          value: role,
                          child: Row(
                            children: [
                              Icon(role.icon, size: 18, color: colorScheme.primary),
                              const SizedBox(width: 10),
                              Text(role.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (role) {
                              if (role != null) {
                                setState(() => _selectedRole = role);
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Temporary Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      onFieldSubmitted: (_) => _handleCreateStaff(),
                      decoration: InputDecoration(
                        labelText: 'Temporary Password',
                        helperText: 'Minimum 6 characters. Provide this to the staff member.',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: Validators.validateTemporaryPassword,
                    ),
                    const SizedBox(height: 32),

                    FilledButton(
                      onPressed: isLoading ? null : _handleCreateStaff,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Staff Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
