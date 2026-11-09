import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/staff_repository.dart';
import '../../../auth/domain/staff_profile.dart';
import '../../../auth/domain/staff_role.dart';
import '../controllers/staff_management_controller.dart';

/// Screen for viewing and managing a single staff member's profile and permissions.
class StaffDetailScreen extends ConsumerWidget {
  const StaffDetailScreen({super.key, required this.staffId});

  final String staffId;

  Future<void> _handleEditName(
    BuildContext context,
    WidgetRef ref,
    StaffProfile staff,
  ) async {
    final textController = TextEditingController(text: staff.name);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Staff Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated == true) {
      final success = await ref
          .read(staffManagementControllerProvider.notifier)
          .updateStaffProfile(staff.uid, name: textController.text);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff name updated successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleChangeRole(
    BuildContext context,
    WidgetRef ref,
    StaffProfile staff,
    bool isSelf,
  ) async {
    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Security restriction: You cannot modify your own administrator role.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    StaffRole selectedRole = staff.role;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Staff Role'),
              content: RadioGroup<StaffRole>(
                groupValue: selectedRole,
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => selectedRole = newVal);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select new role for ${staff.name}:'),
                    const SizedBox(height: 16),
                    ...StaffRole.values.map(
                      (role) => RadioListTile<StaffRole>(
                        title: Text(role.displayName),
                        value: role,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Update Role'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && selectedRole != staff.role) {
      final success = await ref
          .read(staffManagementControllerProvider.notifier)
          .assignRole(staff.uid, selectedRole);

      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role changed to ${selectedRole.displayName}.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleToggleStatus(
    BuildContext context,
    WidgetRef ref,
    StaffProfile staff,
    bool isSelf,
  ) async {
    if (isSelf && staff.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Security restriction: You cannot deactivate your own account.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newStatus = !staff.active;
    final action = newStatus ? 'Activate' : 'Deactivate';

    final confirmed = await showConfirmDialog(
      context: context,
      title: '$action Staff Account',
      message: newStatus
          ? 'Are you sure you want to activate ${staff.name}\'s account? They will regain access to their assigned portal.'
          : 'Are you sure you want to deactivate ${staff.name}\'s account? They will immediately lose access to all application portals.',
      confirmLabel: action,
      isDestructive: !newStatus,
    );

    if (confirmed) {
      final success = await ref
          .read(staffManagementControllerProvider.notifier)
          .setStaffActiveStatus(staff.uid, newStatus);

      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff account is now ${newStatus ? 'active' : 'inactive'}.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final isSelf = currentUid == staffId;

    final staffStream = ref.watch(staffRepositoryProvider).watchStaffProfile(staffId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Profile'),
      ),
      body: StreamBuilder<StaffProfile?>(
        stream: staffStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Loading staff details...');
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: 'Failed to load staff details: ${snapshot.error}',
            );
          }

          final staff = snapshot.data;
          if (staff == null) {
            return const Center(child: Text('Staff account not found.'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header card with Avatar and Status
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(
                                  staff.role.icon,
                                  color: colorScheme.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            staff.name,
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          tooltip: 'Edit Name',
                                          onPressed: () => _handleEditName(context, ref, staff),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      staff.email,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(staff.role.displayName),
                                          backgroundColor:
                                              colorScheme.primaryContainer.withValues(alpha: 0.5),
                                          side: BorderSide.none,
                                          padding: EdgeInsets.zero,
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text(staff.active ? 'Active' : 'Inactive'),
                                          backgroundColor: staff.active
                                              ? colorScheme.primaryContainer
                                              : colorScheme.errorContainer.withValues(alpha: 0.3),
                                          labelStyle: TextStyle(
                                            color: staff.active
                                                ? colorScheme.primary
                                                : colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          side: BorderSide.none,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Details Card
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Metadata',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 24),
                              _DetailRow(label: 'Staff UID', value: staff.uid),
                              const SizedBox(height: 12),
                              _DetailRow(label: 'Email', value: staff.email),
                              const SizedBox(height: 12),
                              _DetailRow(
                                label: 'Status',
                                value: staff.active ? 'Active (Permitted)' : 'Inactive (Deactivated)',
                                valueColor: staff.active
                                    ? colorScheme.primary
                                    : colorScheme.error,
                              ),
                              if (staff.createdAt != null) ...[
                                const SizedBox(height: 12),
                                _DetailRow(
                                  label: 'Created Date',
                                  value:
                                      '${staff.createdAt!.year}-${staff.createdAt!.month.toString().padLeft(2, '0')}-${staff.createdAt!.day.toString().padLeft(2, '0')}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Administrative Actions
                      Text(
                        'Administrative Controls',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Change Role Button
                      OutlinedButton.icon(
                        onPressed: () => _handleChangeRole(context, ref, staff, isSelf),
                        icon: const Icon(Icons.security_update_good_rounded),
                        label: const Text('Change Assigned Role'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Toggle Active / Deactivate Button
                      FilledButton.icon(
                        onPressed: () => _handleToggleStatus(context, ref, staff, isSelf),
                        icon: Icon(
                          staff.active ? Icons.person_off_rounded : Icons.check_circle_outline_rounded,
                        ),
                        label: Text(
                          staff.active ? 'Deactivate Staff Account' : 'Activate Staff Account',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: staff.active ? colorScheme.error : colorScheme.primary,
                          foregroundColor: staff.active ? Colors.white : colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),

                      if (isSelf) ...[
                        const SizedBox(height: 12),
                        Text(
                          'You are viewing your own administrator account. Self-deactivation and self-role changes are restricted for security.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
