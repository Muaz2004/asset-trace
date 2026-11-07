import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../registration/domain/registration.dart';
import '../../../registration/presentation/controllers/registration_list_controller.dart';
import '../controllers/dashboard_stats_controller.dart';

/// Dashboard for Registration Officers managing student and computer registrations with live activity tracking.
class RegistrationDashboardScreen extends ConsumerWidget {
  const RegistrationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final registrationsAsync = ref.watch(allRegistrationsStreamProvider);
    final statsAsync = ref.watch(officerRegistrationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Portal'),
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
              // Staff Greeting Header
              profileAsync.maybeWhen(
                data: (profile) => Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colorScheme.primary,
                          child: Icon(
                            Icons.app_registration_rounded,
                            color: colorScheme.onPrimary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${profile?.name ?? 'Officer'}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Computer Registration Officer • ${AppConstants.institutionName}',
                                style: theme.textTheme.bodySmall?.copyWith(
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
              const SizedBox(height: 20),

              // Officer Activity Overview
              statsAsync.when(
                data: (stats) {
                  return Card(
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Registration Activity',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.insights_rounded,
                                  size: 18, color: colorScheme.primary),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _ActivityStat(
                                  label: 'Registered by Me',
                                  value: stats.myTotalRegistrations.toString(),
                                  icon: Icons.person_pin_rounded,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _ActivityStat(
                                  label: 'My Active PCs',
                                  value: stats.myActiveRegistrations.toString(),
                                  icon: Icons.check_circle_outline_rounded,
                                  valueColor: Colors.green.shade700,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _ActivityStat(
                                  label: 'Campus Total',
                                  value: stats.systemTotalRegistrations.toString(),
                                  icon: Icons.language_rounded,
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
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Quick Actions Section
              Text(
                'Registration Operations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_to_photos_rounded,
                      title: 'Register PC',
                      subtitle: 'Verify student ID & enroll computer',
                      onTap: () => context.push(RoutePaths.registrationForm),
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.folder_shared_rounded,
                      title: 'All Records',
                      subtitle: 'Browse, edit & audit registrations',
                      onTap: () => context.push(RoutePaths.registrationList),
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                  leading: Icon(Icons.person_search_rounded, color: colorScheme.primary),
                  title: const Text('Search & Credential Recovery',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Recover student 6-digit code or QR by ID, name, or phone'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => context.push(RoutePaths.registrationSearch),
                ),
              ),
              const SizedBox(height: 12),
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
                  leading: Icon(Icons.history_rounded, color: colorScheme.primary),
                  title: const Text('Verification Audit Trail',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Review campus-wide physical checkpoint inspection records'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => context.push('/verification/history'),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Registrations Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Registrations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(RoutePaths.registrationList),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              registrationsAsync.when(
                data: (registrations) {
                  if (registrations.isEmpty) {
                    return Card(
                      color: colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 44,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Computer Registrations Yet',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Click "Register PC" above to begin your first enrollment.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final recentList = registrations.take(5).toList();

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final reg = recentList[index];
                      return _RecentRegistrationTile(
                        registration: reg,
                        colorScheme: colorScheme,
                        theme: theme,
                      );
                    },
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: AppLoadingIndicator(
                      message: 'Loading recent registrations...',
                    ),
                  ),
                ),
                error: (e, _) => AppErrorView(
                  message: 'Failed to retrieve registrations: $e',
                  onRetry: () => ref.refresh(allRegistrationsStreamProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({
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
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

class _RecentRegistrationTile extends StatelessWidget {
  const _RecentRegistrationTile({
    required this.registration,
    required this.colorScheme,
    required this.theme,
  });

  final Registration registration;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeText;
    if (registration.isActive) {
      badgeBg = Colors.green.shade50;
      badgeText = Colors.green.shade800;
    } else if (registration.isReportedStolen) {
      badgeBg = Colors.red.shade50;
      badgeText = Colors.red.shade800;
    } else {
      badgeBg = Colors.amber.shade50;
      badgeText = Colors.amber.shade900;
    }

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.laptop_chromebook_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          registration.studentName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${registration.studentId} • ${registration.pcBrand} ${registration.pcModel}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            registration.statusDisplayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeText,
            ),
          ),
        ),
        onTap: () {
          context.push('/registration/detail/${registration.id}');
        },
      ),
    );
  }
}
