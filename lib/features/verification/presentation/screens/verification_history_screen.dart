import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../data/verification_repository.dart';
import '../../domain/verification_log.dart';
import '../controllers/verification_history_controller.dart';

/// Screen providing a complete searchable, filterable history of physical computer ownership verifications.
class VerificationHistoryScreen extends ConsumerWidget {
  const VerificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final logsAsync = ref.watch(filteredVerificationLogsProvider);
    final filterState = ref.watch(verificationFilterProvider);
    final filterNotifier = ref.read(verificationFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification History'),
      ),
      body: Column(
        children: [
          // Filter Header
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
                  hintText: 'Search by registration ID, officer, notes...',
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
                // Outcome Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Outcome: ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: filterState.outcomeFilter == 'all',
                        onSelected: (_) => filterNotifier.setOutcomeFilter('all'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Verified'),
                        selected: filterState.outcomeFilter == 'verified',
                        onSelected: (_) =>
                            filterNotifier.setOutcomeFilter('verified'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Flagged / Stolen'),
                        selected: filterState.outcomeFilter == 'flagged',
                        onSelected: (_) =>
                            filterNotifier.setOutcomeFilter('flagged'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Failed'),
                        selected: filterState.outcomeFilter == 'failed',
                        onSelected: (_) =>
                            filterNotifier.setOutcomeFilter('failed'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Method & Date Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Method: ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All Methods'),
                        selected: filterState.methodFilter == 'all',
                        onSelected: (_) => filterNotifier.setMethodFilter('all'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('QR Pass'),
                        selected: filterState.methodFilter == 'QR',
                        onSelected: (_) => filterNotifier.setMethodFilter('QR'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('6-Digit Code'),
                        selected: filterState.methodFilter == 'manual_code',
                        onSelected: (_) =>
                            filterNotifier.setMethodFilter('manual_code'),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Date: ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All Time'),
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
                        onSelected: (_) =>
                            filterNotifier.setDateFilter('this_week'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            size: 56,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filterState.searchQuery.isNotEmpty ||
                                    filterState.outcomeFilter != 'all' ||
                                    filterState.methodFilter != 'all'
                                ? 'No verification records match your filters'
                                : 'No computer verifications recorded yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Verification events will automatically appear here once security or library staff scan passes or verify codes.',
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
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _VerificationLogCard(log: log);
                  },
                );
              },
              loading: () => const AppLoadingIndicator(
                message: 'Loading verification history...',
              ),
              error: (e, _) => AppErrorView(
                message: 'Failed to retrieve logs: $e',
                onRetry: () => ref.refresh(allVerificationLogsStreamProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationLogCard extends StatelessWidget {
  const _VerificationLogCard({required this.log});

  final VerificationLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateStr = log.timestamp != null
        ? '${log.timestamp!.year}-${log.timestamp!.month.toString().padLeft(2, '0')}-${log.timestamp!.day.toString().padLeft(2, '0')} ${log.timestamp!.hour.toString().padLeft(2, '0')}:${log.timestamp!.minute.toString().padLeft(2, '0')}'
        : 'Unknown';

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: log.result.color.withValues(alpha: 0.15),
          child: Icon(log.result.icon, color: log.result.color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                log.result.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: log.result.color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    log.isQrMethod
                        ? Icons.qr_code_rounded
                        : Icons.pin_outlined,
                    size: 12,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.isQrMethod ? 'QR Pass' : '6-Digit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              'Reg ID: ${log.registrationId}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Verified by: ${log.verifiedByName ?? log.verifiedBy} (${log.verifiedByRole.replaceAll('_', ' ')}) • $dateStr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${log.notes}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          context.push('/verification/detail/${log.id}');
        },
      ),
    );
  }
}
