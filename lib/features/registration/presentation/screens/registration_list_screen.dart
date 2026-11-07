import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/registration.dart';
import '../controllers/registration_list_controller.dart';

/// Screen displaying the searchable, filterable list of student computer registrations.
class RegistrationListScreen extends ConsumerWidget {
  const RegistrationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final registrationsAsync = ref.watch(filteredRegistrationsProvider);
    final filterState = ref.watch(registrationFilterProvider);
    final filterNotifier = ref.read(registrationFilterProvider.notifier);
    final isAdmin =
        ref.watch(appAuthStateProvider).profile?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded),
            tooltip: 'Search & Recover Credentials',
            onPressed: () => context.push(RoutePaths.registrationSearch),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Register Computer',
            onPressed: () => context.push(RoutePaths.registrationForm),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.registrationForm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Register PC'),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchBar(
                  hintText: 'Search student, ID, serial, or code...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (filterState.searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => filterNotifier.setSearchQuery(''),
                      ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  ),
                  onChanged: filterNotifier.setSearchQuery,
                ),
                const SizedBox(height: 10),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Status: ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: filterState.statusFilter == 'all',
                        onSelected: (_) => filterNotifier.setStatusFilter('all'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Active'),
                        selected: filterState.statusFilter == 'active',
                        onSelected: (_) => filterNotifier.setStatusFilter('active'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Suspended'),
                        selected: filterState.statusFilter == 'suspended',
                        onSelected: (_) => filterNotifier.setStatusFilter('suspended'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Reported Stolen'),
                        selected: filterState.statusFilter == 'reported_stolen',
                        onSelected: (_) => filterNotifier.setStatusFilter('reported_stolen'),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Archived'),
                          selected: filterState.statusFilter == 'archived',
                          onSelected: (_) =>
                              filterNotifier.setStatusFilter('archived'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Date Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Date: ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All Dates'),
                        selected: filterState.dateFilter == 'all',
                        onSelected: (_) => filterNotifier.setDateFilter('all'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Today'),
                        selected: filterState.dateFilter == 'today',
                        onSelected: (_) => filterNotifier.setDateFilter('today'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Last 7 Days'),
                        selected: filterState.dateFilter == 'this_week',
                        onSelected: (_) => filterNotifier.setDateFilter('this_week'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('This Month'),
                        selected: filterState.dateFilter == 'this_month',
                        onSelected: (_) => filterNotifier.setDateFilter('this_month'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: registrationsAsync.when(
              data: (registrations) {
                if (registrations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.laptop_chromebook_rounded,
                            size: 56,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filterState.searchQuery.isNotEmpty ||
                                    filterState.statusFilter != 'all' ||
                                    filterState.dateFilter != 'all'
                                ? 'No registrations match your search criteria'
                                : 'No computer registrations recorded yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Click "+ Register PC" to record a student computer ownership.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: registrations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final reg = registrations[index];
                    return _RegistrationCard(registration: reg);
                  },
                );
              },
              loading: () => const AppLoadingIndicator(
                message: 'Loading computer registration records...',
              ),
              error: (e, _) => AppErrorView(
                message: 'Failed to retrieve registrations: $e',
                onRetry: () => ref.refresh(allRegistrationsStreamProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.registration});

  final Registration registration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color badgeBgColor;
    Color badgeTextColor;
    if (registration.isActive) {
      badgeBgColor = Colors.green.shade50;
      badgeTextColor = Colors.green.shade800;
    } else if (registration.isReportedStolen) {
      badgeBgColor = Colors.red.shade50;
      badgeTextColor = Colors.red.shade800;
    } else if (registration.isArchived) {
      badgeBgColor = Colors.grey.shade200;
      badgeTextColor = Colors.grey.shade800;
    } else {
      badgeBgColor = Colors.amber.shade50;
      badgeTextColor = Colors.amber.shade900;
    }

    final hasPhoto = registration.pcPhotoUrl.trim().isNotEmpty;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Image.network(
                    registration.pcPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.laptop_mac_rounded,
                          color: colorScheme.primary, size: 20),
                    ),
                  ),
                ),
              )
            : CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.laptop_mac_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                registration.studentName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                registration.studentId,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${registration.pcBrand} ${registration.pcModel}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.pin_outlined, size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  registration.serialNumber,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (registration.registrationCode != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• Code: ${registration.registrationCode}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    registration.statusDisplayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          context.push('/registration/detail/${registration.id}');
        },
      ),
    );
  }
}
