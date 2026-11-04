import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../controllers/auth_controller.dart';

/// Screen displaying the authenticated staff member's profile and account settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Sign Out Confirmation',
      message: 'Are you sure you want to end your current staff session and sign out?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Account'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile data available.'));
          }

          final initials = profile.name.isNotEmpty
              ? profile.name
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase()
              : 'S';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            initials,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Chip(
                          avatar: Icon(
                            profile.role.icon,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            profile.role.displayName,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          side: BorderSide.none,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Details',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 24),
                              _ProfileRow(
                                label: 'Account Status',
                                value: profile.active ? 'Active' : 'Inactive',
                                valueColor: profile.active
                                    ? Colors.green.shade700
                                    : colorScheme.error,
                              ),
                              const SizedBox(height: 12),
                              _ProfileRow(
                                label: 'Assigned Role',
                                value: profile.role.displayName,
                              ),
                              const SizedBox(height: 12),
                              _ProfileRow(
                                label: 'Staff UID',
                                value: profile.uid,
                              ),
                              if (profile.createdAt != null) ...[
                                const SizedBox(height: 12),
                                _ProfileRow(
                                  label: 'Registration Date',
                                  value:
                                      '${profile.createdAt!.year}-${profile.createdAt!.month.toString().padLeft(2, '0')}-${profile.createdAt!.day.toString().padLeft(2, '0')}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () => _handleSignOut(context, ref),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Sign Out of Portal'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
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
        loading: () => const AppLoadingIndicator(message: 'Loading profile...'),
        error: (error, _) => Center(
          child: Text('Failed to load profile: $error'),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
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
            ),
          ),
        ),
      ],
    );
  }
}
