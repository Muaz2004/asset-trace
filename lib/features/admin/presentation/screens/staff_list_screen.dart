import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/staff_profile.dart';
import '../../../auth/domain/staff_role.dart';
import '../controllers/staff_management_controller.dart';

/// Screen displaying the searchable, filterable list of university staff members.
class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final staffAsync = ref.watch(filteredStaffListProvider);
    final filterState = ref.watch(staffFilterProvider);
    final filterNotifier = ref.read(staffFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Staff Member',
            onPressed: () => context.push(RoutePaths.createStaff),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.createStaff),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Staff'),
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
                // Search Field
                SearchBar(
                  hintText: 'Search staff by name or email...',
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
                const SizedBox(height: 12),

                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Roles'),
                        selected: filterState.roleFilter == null,
                        onSelected: (_) => filterNotifier.setRoleFilter(null),
                      ),
                      const SizedBox(width: 8),
                      ...StaffRole.values.map(
                        (role) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(role.displayName),
                            selected: filterState.roleFilter == role,
                            onSelected: (selected) {
                              filterNotifier.setRoleFilter(selected ? role : null);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Status Filter Chips
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: filterState.statusFilter == null,
                      onSelected: (_) => filterNotifier.setStatusFilter(null),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Active'),
                      selected: filterState.statusFilter == true,
                      onSelected: (_) => filterNotifier.setStatusFilter(true),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Inactive'),
                      selected: filterState.statusFilter == false,
                      onSelected: (_) => filterNotifier.setStatusFilter(false),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Staff List Results
          Expanded(
            child: staffAsync.when(
              data: (staffList) {
                if (staffList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 56,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filterState.searchQuery.isNotEmpty ||
                                    filterState.roleFilter != null ||
                                    filterState.statusFilter != null
                                ? 'No staff match the selected filters'
                                : 'No staff accounts registered yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Use the "+ New Staff" button to register authorized staff members.',
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
                  itemCount: staffList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return _StaffCard(staff: staff);
                  },
                );
              },
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading staff directory...'),
              error: (e, _) => AppErrorView(
                message: 'Failed to load staff list: $e',
                onRetry: () => ref.refresh(allStaffStreamProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff});

  final StaffProfile staff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            staff.role.icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          staff.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              staff.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    staff.role.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: staff.active
                        ? Colors.green.shade50
                        : colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    staff.active ? 'Active' : 'Inactive',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: staff.active
                          ? Colors.green.shade800
                          : colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          context.push('/admin/staff/${staff.uid}');
        },
      ),
    );
  }
}
