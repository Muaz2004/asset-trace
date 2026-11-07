import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../controllers/registration_controller.dart';

/// Screen displayed after a successful computer registration.
class RegistrationSuccessScreen extends ConsumerWidget {
  const RegistrationSuccessScreen({super.key});

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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 52,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Registration Successful',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The student computer ownership record has been verified and permanently registered in the university database.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Registration Details Card
                    if (registration != null) ...[
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'REGISTRATION REFERENCE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  registration.id,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Divider(height: 24),
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
                                valueColor: Colors.green.shade800,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Actions
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
                    const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
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
          width: 110,
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
