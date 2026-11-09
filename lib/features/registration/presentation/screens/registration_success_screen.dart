import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/registration.dart';
import '../controllers/registration_controller.dart';

/// Screen displayed after a successful computer registration displaying the opaque QR code
/// and unique 6-digit numeric registration code.
class RegistrationSuccessScreen extends ConsumerWidget {
  const RegistrationSuccessScreen({super.key});

  void _showPrintShareDialog(BuildContext context, Registration registration) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final qrData = registration.qrIdentifier ?? registration.id;
    final code = registration.registrationCode ?? '------';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: colorScheme.primary),
            const SizedBox(width: 10),
            const Text('PC Verification Pass'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.institutionName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Official PC Ownership Credential',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '6-DIGIT VERIFICATION CODE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code.split('').join('  '),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Keep this QR credential or numeric code with your computer. Security checkpoints and campus libraries scan this pass for authorization.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Code: $code\nRef: ${registration.id}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registration code copied to clipboard')),
              );
              Navigator.of(dialogContext).pop();
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Code'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formState = ref.watch(registrationControllerProvider);
    final registration = formState.createdRegistration;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ref.read(registrationControllerProvider.notifier).resetForm();
          context.go(RoutePaths.registrationDashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registration Confirmed'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Badge
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 46,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Registration Completed',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ownership verified and official credentials allocated.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // QR and 6-Digit Code Card
                    if (registration != null) ...[
                      Card(
                        elevation: 2,
                        color: colorScheme.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(
                                'OFFICIAL QR VERIFICATION PASS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Real QR code from opaque identifier
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: registration.qrIdentifier ?? registration.id,
                                  version: QrVersions.auto,
                                  size: 160,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 6-Digit Code
                              Text(
                                'SIX-DIGIT REGISTRATION CODE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  (registration.registrationCode ?? '------')
                                      .split('')
                                      .join('  '),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Share/Print Button
                              OutlinedButton.icon(
                                onPressed: () => _showPrintShareDialog(context, registration),
                                icon: const Icon(Icons.share_outlined, size: 18),
                                label: const Text('Share / Print Pass'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Registration Details Summary Card
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoItem(
                                label: 'Reference ID',
                                value: registration.id,
                                isMonospace: true,
                              ),
                              const Divider(height: 18),
                              _InfoItem(
                                label: 'Student',
                                value: '${registration.studentName} (${registration.studentId})',
                              ),
                              const SizedBox(height: 8),
                              _InfoItem(
                                label: 'Computer',
                                value: '${registration.pcBrand} ${registration.pcModel}',
                              ),
                              const SizedBox(height: 8),
                              _InfoItem(
                                label: 'Serial Number',
                                value: registration.serialNumber,
                                isMonospace: true,
                              ),
                              const SizedBox(height: 8),
                              _InfoItem(
                                label: 'Status',
                                value: 'Active Ownership Record',
                                valueColor: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Navigation actions
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(registrationControllerProvider.notifier).resetForm();
                        context.go(RoutePaths.registrationForm);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Register Another Computer'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (registration != null) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(registrationControllerProvider.notifier).resetForm();
                          context.go('/registration/detail/${registration.id}');
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('View Registration Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextButton(
                      onPressed: () {
                        ref.read(registrationControllerProvider.notifier).resetForm();
                        context.go(RoutePaths.registrationDashboard);
                      },
                      child: const Text('Return to Portal Dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}
