import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../verification/presentation/widgets/verification_activity_list.dart';
import '../controllers/dashboard_stats_controller.dart';

/// Dashboard for Campus Security Officers performing gate and checkpoint computer verifications.
class SecurityDashboardScreen extends ConsumerWidget {
  const SecurityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final statsAsync = ref.watch(checkpointVerificationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Checkpoint'),
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
              // Staff Greeting
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
                            Icons.security_rounded,
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
                                'Welcome, Officer ${profile?.name ?? ''}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Campus Security Officer • ${AppConstants.institutionName}',
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

              // Checkpoint Activity Statistics
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
                                'Checkpoint Activity Overview',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.shield_outlined,
                                  size: 18, color: colorScheme.primary),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: 'Inspected Today',
                                  value: stats.todayCount.toString(),
                                  icon: Icons.today_rounded,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Verified Normal',
                                  value: stats.verifiedCount.toString(),
                                  icon: Icons.check_circle_outline_rounded,
                                  valueColor: Colors.green.shade700,
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Flagged / Stolen',
                                  value: stats.flaggedCount.toString(),
                                  icon: Icons.warning_amber_rounded,
                                  valueColor: stats.flaggedCount > 0
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
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Verification Entry Points Section
              Text(
                'Ownership Verification Entry Points',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: colorScheme.surfaceContainerLow,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push(RoutePaths.qrScanner),
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
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'QR Code Scanner',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fast camera scanner for gate passes and checkpoint barcodes.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: colorScheme.surfaceContainerLow,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push(RoutePaths.manualLookup),
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
                                child: Icon(
                                  Icons.pin_outlined,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Registration Lookup',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manual search by unique 6-digit numeric registration code.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Security Activity Logs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Checkpoint Activity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/verification/history'),
                    child: const Text('View All Logs'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const VerificationActivityList(
                limit: 8,
                emptyMessage: 'No checkpoint passage activity logged yet.',
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
