import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../controllers/staff_activity_controller.dart';

/// Screen providing administrators with operational accountability metrics for university staff.
class StaffActivityScreen extends ConsumerWidget {
  const StaffActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activityAsync = ref.watch(staffActivityListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Activity & Accountability'),
      ),
      body: activityAsync.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return const Center(
              child: Text('No staff activity records found.'),
            );
          }

          final totalRegistrations =
              summaries.fold<int>(0, (sum, s) => sum + s.registrationCount);
          final totalVerifications =
              summaries.fold<int>(0, (sum, s) => sum + s.verificationCount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Aggregate Banner
                Card(
                  color: colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operational Accountability Overview',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Derived directly from Firestore registration and verification logs.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryMetric(
                                label: 'Total Staff',
                                value: summaries.length.toString(),
                                icon: Icons.badge_outlined,
                                colorScheme: colorScheme,
                              ),
                            ),
                            Expanded(
                              child: _SummaryMetric(
                                label: 'Registrations',
                                value: totalRegistrations.toString(),
                                icon: Icons.laptop_chromebook_rounded,
                                colorScheme: colorScheme,
                              ),
                            ),
                            Expanded(
                              child: _SummaryMetric(
                                label: 'Verifications',
                                value: totalVerifications.toString(),
                                icon: Icons.verified_outlined,
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Staff Member Performance Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summaries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = summaries[index];
                    return _StaffActivityCard(summary: item);
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingIndicator(
          message: 'Aggregating staff activity records...',
        ),
        error: (e, _) => AppErrorView(
          message: 'Failed to compute staff activity: $e',
          onRetry: () => ref.refresh(staffActivityListProvider),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StaffActivityCard extends StatelessWidget {
  const _StaffActivityCard({required this.summary});

  final StaffActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = summary.profile;

    final lastActiveStr = summary.lastActiveDate != null
        ? '${summary.lastActiveDate!.year}-${summary.lastActiveDate!.month.toString().padLeft(2, '0')}-${summary.lastActiveDate!.day.toString().padLeft(2, '0')}'
        : 'Never';

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/admin/staff/${profile.uid}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: profile.active
                          ? colorScheme.primaryContainer
                          : colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      profile.active ? 'Active' : 'Inactive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: profile.active
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ActivityBadge(
                      label: 'Role',
                      value: profile.role.displayName,
                      icon: Icons.badge_outlined,
                      colorScheme: colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _ActivityBadge(
                      label: 'Registrations',
                      value: summary.registrationCount.toString(),
                      icon: Icons.laptop_mac_rounded,
                      colorScheme: colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _ActivityBadge(
                      label: 'Verifications',
                      value: summary.verificationCount.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Last active: $lastActiveStr',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
