import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../data/verification_repository.dart';
import '../../domain/verification_log.dart';

/// Screen displaying the immutable audit details of a physical verification event.
class VerificationDetailScreen extends ConsumerWidget {
  const VerificationDetailScreen({super.key, required this.logId});

  final String logId;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.watch(verificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Audit Record'),
      ),
      body: FutureBuilder<VerificationLog?>(
        future: repo.getVerificationLog(logId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(
              message: 'Loading verification record...',
            );
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: 'Failed to retrieve record: ${snapshot.error}',
            );
          }

          final log = snapshot.data;
          if (log == null) {
            return const Center(
              child: Text('Verification audit record not found.'),
            );
          }

          final dateStr = log.timestamp != null
              ? '${log.timestamp!.year}-${log.timestamp!.month.toString().padLeft(2, '0')}-${log.timestamp!.day.toString().padLeft(2, '0')} ${log.timestamp!.hour.toString().padLeft(2, '0')}:${log.timestamp!.minute.toString().padLeft(2, '0')}:${log.timestamp!.second.toString().padLeft(2, '0')}'
              : 'Unknown';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Outcome Card
                      Card(
                        color: log.result.color.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: log.result.color.withValues(alpha: 0.2),
                                child: Icon(log.result.icon,
                                    color: log.result.color, size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.result.displayName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: log.result.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Method: ${log.isQrMethod ? 'QR Code Pass Scanner' : '6-Digit Manual Code'}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Audit Metadata
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inspection Event Details',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 20),
                              _AuditRow(
                                label: 'Log Reference ID',
                                value: log.id,
                                isMonospace: true,
                                onCopy: () => _copyToClipboard(
                                    context, log.id, 'Log ID'),
                              ),
                              const SizedBox(height: 12),
                              _AuditRow(
                                label: 'Computer Reg ID',
                                value: log.registrationId,
                                isMonospace: true,
                                onCopy: () => _copyToClipboard(
                                    context, log.registrationId, 'Registration ID'),
                              ),
                              const SizedBox(height: 12),
                              _AuditRow(
                                label: 'Timestamp',
                                value: dateStr,
                              ),
                              const SizedBox(height: 12),
                              _AuditRow(
                                label: 'Verifying Officer',
                                value:
                                    '${log.verifiedByName ?? 'Officer'} (${log.verifiedByRole.replaceAll('_', ' ')})',
                              ),
                              const SizedBox(height: 12),
                              _AuditRow(
                                label: 'Officer Staff UID',
                                value: log.verifiedBy,
                                isMonospace: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Staff Inspection Remarks
                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                        Card(
                          color: colorScheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Officer Inspection Notes',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 20),
                                Text(
                                  log.notes!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Immutability Notice
                      Card(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  color: colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This audit log is strictly immutable in Cloud Firestore to guarantee evidentiary accountability.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Button to jump to registration
                      FilledButton.icon(
                        onPressed: () {
                          context.push('/registration/detail/${log.registrationId}');
                        },
                        icon: const Icon(Icons.laptop_chromebook_rounded),
                        label: const Text('View Associated Computer Registration'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
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

class _AuditRow extends StatelessWidget {
  const _AuditRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool isMonospace;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onCopy,
                  child: Icon(Icons.copy_rounded,
                      size: 16, color: colorScheme.primary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
