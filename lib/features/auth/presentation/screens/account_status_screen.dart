import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

/// Screen displayed when an authenticated Firebase user lacks valid staff authorization.
class AccountStatusScreen extends ConsumerWidget {
  const AccountStatusScreen({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
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
    final authState = ref.watch(appAuthStateProvider);

    final IconData statusIcon;
    final String statusTitle;
    final String statusDescription;

    switch (authState.status) {
      case AccountStatusType.deactivated:
        statusIcon = Icons.person_off_rounded;
        statusTitle = 'Account Deactivated';
        statusDescription =
            'Your staff account has been deactivated by an administrator. You do not currently have access to system features. Please contact the ICT / Security administration.';
      case AccountStatusType.invalidRole:
        statusIcon = Icons.policy_rounded;
        statusTitle = 'Role Configuration Issue';
        statusDescription =
            'Your account does not have a recognized staff role assigned. Please ask a system administrator to verify your staff record.';
      case AccountStatusType.notRegistered:
      default:
        statusIcon = Icons.no_accounts_rounded;
        statusTitle = 'Not Registered as Staff';
        statusDescription =
            'This authenticated account is not registered in the university staff registry. Student accounts and unauthorized accounts are not permitted to use this portal.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statusIcon,
                          size: 38,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        statusTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (authState.email != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authState.email!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        statusDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () => _handleSignOut(context, ref),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Sign Out'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
