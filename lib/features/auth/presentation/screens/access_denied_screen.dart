import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../domain/staff_role.dart';
import '../controllers/auth_controller.dart';

/// Screen displayed when an authenticated staff member attempts to access an unauthorized route.
class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});

  void _returnToDashboard(BuildContext context, WidgetRef ref) {
    final profile = ref.read(currentStaffProfileStreamProvider).value;
    if (profile == null) {
      context.go(RoutePaths.login);
      return;
    }

    switch (profile.role) {
      case StaffRole.admin:
        context.go(RoutePaths.adminDashboard);
      case StaffRole.registrationOfficer:
        context.go(RoutePaths.registrationDashboard);
      case StaffRole.libraryStaff:
        context.go(RoutePaths.libraryDashboard);
      case StaffRole.securityOfficer:
        context.go(RoutePaths.securityDashboard);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      size: 40,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unauthorized Area',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your account role does not have authorization to access this section of the system.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _returnToDashboard(context, ref),
                    icon: const Icon(Icons.dashboard_rounded, size: 18),
                    label: const Text('Return to My Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
