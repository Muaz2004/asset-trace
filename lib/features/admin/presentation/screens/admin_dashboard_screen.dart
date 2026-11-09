import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboards/presentation/controllers/dashboard_stats_controller.dart';
import '../controllers/staff_management_controller.dart';

/// Administrator dashboard providing comprehensive operational overview, staff management,
/// and live system metrics from Cloud Firestore.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Account Profile',
            onPressed: () => context.push(RoutePaths.profile),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              profileAsync.maybeWhen(
                data: (profile) => Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colorScheme.primary,
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${profile?.name ?? 'Administrator'}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'System Administrator • ${AppConstants.institutionName}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Staff Management Section
              Text(
                'Staff Management & Accountability',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.people_alt_rounded,
                      title: 'Staff Directory',
                      subtitle: 'View, search, and manage university staff',
                      onTap: () => context.push(RoutePaths.staffList),
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Add Staff Member',
                      subtitle: 'Provision new staff account and role',
                      onTap: () => context.push(RoutePaths.createStaff),
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  leading: Icon(Icons.insights_rounded, color: colorScheme.primary),
                  title: const Text('Staff Activity & Accountability',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Audit individual registrations, verifications & accountability logs'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => context.push('/admin/staff-activity'),
                ),
              ),
              const SizedBox(height: 24),

              // Staff Accounts Summary (Driven by allStaffStreamProvider)
              ref.watch(allStaffStreamProvider).when(
                data: (staffList) {
                  final totalStaff = staffList.length;
                  final activeStaff = staffList.where((s) => s.active).length;
                  final inactiveStaff = totalStaff - activeStaff;

                  return Card(
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Staff Accounts Summary',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$totalStaff registered',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: 'Total Accounts',
                                  value: totalStaff.toString(),
                                  icon: Icons.badge_outlined,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Active Staff',
                                  value: activeStaff.toString(),
                                  icon: Icons.check_circle_outline_rounded,
                                  valueColor: colorScheme.primary,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Inactive',
                                  value: inactiveStaff.toString(),
                                  icon: Icons.pause_circle_outline_rounded,
                                  valueColor: inactiveStaff > 0
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                  colorScheme: colorScheme,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => AppErrorView(
                  message: 'Failed to retrieve staff statistics: $e',
                ),
              ),
              const SizedBox(height: 28),

              // Live System Statistics Section
              statsAsync.when(
                data: (stats) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Computer Registrations Overview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Computer Registrations',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push(RoutePaths.registrationList),
                            child: const Text('Manage Registrations'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatItem(
                                      label: 'Total Registered',
                                      value: stats.totalRegistrations.toString(),
                                      icon: Icons.laptop_chromebook_rounded,
                                      colorScheme: colorScheme,
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      label: 'Active',
                                      value: stats.activeRegistrations.toString(),
                                      icon: Icons.check_circle_outline_rounded,
                                      valueColor: colorScheme.primary,
                                      colorScheme: colorScheme,
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      label: 'Suspended',
                                      value: stats.suspendedRegistrations.toString(),
                                      icon: Icons.pause_circle_outline_rounded,
                                      valueColor: stats.suspendedRegistrations > 0
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                      colorScheme: colorScheme,
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      label: 'Reported Stolen',
                                      value: stats.reportedStolenRegistrations.toString(),
                                      icon: Icons.warning_amber_rounded,
                                      valueColor: stats.reportedStolenRegistrations > 0
                                          ? colorScheme.error
                                          : colorScheme.onSurfaceVariant,
                                      colorScheme: colorScheme,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Verification Activity Overview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Verification Activity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push('/verification/history'),
                            child: const Text('Audit History'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: 'Total Verifications',
                                  value: stats.totalVerifications.toString(),
                                  icon: Icons.verified_user_outlined,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Verified Normal',
                                  value: stats.verifiedVerifications.toString(),
                                  icon: Icons.task_alt_rounded,
                                  valueColor: colorScheme.primary,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Flagged / Stolen',
                                  value: stats.flaggedVerifications.toString(),
                                  icon: Icons.report_problem_outlined,
                                  valueColor: stats.flaggedVerifications > 0
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                  colorScheme: colorScheme,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Staff Accounts Summary
                      Text(
                        'Staff Overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: 'Total Accounts',
                                  value: stats.totalStaff.toString(),
                                  icon: Icons.badge_outlined,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Active Staff',
                                  value: stats.activeStaff.toString(),
                                  icon: Icons.person_outline_rounded,
                                  valueColor: colorScheme.primary,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Inactive',
                                  value: stats.inactiveStaff.toString(),
                                  icon: Icons.person_off_outlined,
                                  valueColor: stats.inactiveStaff > 0
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                  colorScheme: colorScheme,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: AppLoadingIndicator(
                      message: 'Retrieving system statistics...',
                    ),
                  ),
                ),
                error: (e, _) => AppErrorView(
                  message: 'Failed to retrieve operational metrics: $e',
                  onRetry: () => ref.refresh(adminDashboardStatsProvider),
                ),
              ),
              const SizedBox(height: 28),

              // Operational Portals (Admin Direct Access)
              Text(
                'University Operations (Admin Access)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _OperationTile(
                icon: Icons.person_search_rounded,
                title: 'Search & Credential Recovery',
                subtitle: 'Look up registrations and recover lost codes/QRs',
                onTap: () => context.push(RoutePaths.registrationSearch),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _OperationTile(
                icon: Icons.app_registration_rounded,
                title: 'Computer Registration Portal',
                subtitle: 'Register student laptops and assign identifiers',
                onTap: () => context.push(RoutePaths.registrationDashboard),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _OperationTile(
                icon: Icons.local_library_rounded,
                title: 'Library Verification Portal',
                subtitle: 'Verify laptop ownership at university libraries',
                onTap: () => context.push(RoutePaths.libraryDashboard),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _OperationTile(
                icon: Icons.security_rounded,
                title: 'Security Checkpoint Portal',
                subtitle: 'Gate security computer ownership verification',
                onTap: () => context.push(RoutePaths.securityDashboard),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _OperationTile(
                icon: Icons.history_edu_rounded,
                title: 'Verification History Portal',
                subtitle: 'Browse complete historical inspection audit logs',
                onTap: () => context.push('/verification/history'),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 22, color: colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      ),
    );
  }
}
