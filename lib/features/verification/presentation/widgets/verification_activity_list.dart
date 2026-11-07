import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/verification_repository.dart';
import '../../domain/verification_log.dart';

/// Live activity list displaying recent verification attempts across campus checkpoints and libraries.
class VerificationActivityList extends ConsumerWidget {
  const VerificationActivityList({
    this.limit = 10,
    this.emptyMessage = 'Library computer check-in and ownership verification history will be displayed here.',
    super.key,
  });

  final int limit;
  final String emptyMessage;

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(recentVerificationLogsStreamProvider);

    return logsAsync.maybeWhen(
      data: (logs) {
        if (logs.isNotEmpty) {
          final displayLogs = logs.take(limit).toList();
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayLogs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = displayLogs[index];
              return _VerificationLogCard(
                log: log,
                timeFormatted: _formatTimestamp(log.timestamp),
              );
            },
          );
        }
        return _buildEmptyCard(context, emptyMessage);
      },
      orElse: () => _buildEmptyCard(context, emptyMessage),
    );
  }

  Widget _buildEmptyCard(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_edu_rounded,
                size: 44,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'No Verification Logs Recorded',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
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
}

class _VerificationLogCard extends StatelessWidget {
  const _VerificationLogCard({
    required this.log,
    required this.timeFormatted,
  });

  final VerificationLog log;
  final String timeFormatted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outcome = log.result;

    return Card(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: outcome.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(outcome.icon, color: outcome.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        outcome.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: outcome.color,
                        ),
                      ),
                      Text(
                        timeFormatted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Pass: ${log.registrationId}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.method == 'QR' ? 'QR Pass' : '6-Digit',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${log.notes}',
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
            ),
          ],
        ),
      ),
    );
  }
}
