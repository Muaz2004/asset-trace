import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/registration.dart';
import '../controllers/registration_list_controller.dart';

/// Screen allowing authorized Registration Officers and Administrators to search registrations
/// across Student ID, Phone Number, Student Name, Serial Number, or 6-digit code to recover
/// lost/forgotten credentials without loading the entire database into memory.
class RegistrationSearchScreen extends ConsumerStatefulWidget {
  const RegistrationSearchScreen({super.key});

  @override
  ConsumerState<RegistrationSearchScreen> createState() =>
      _RegistrationSearchScreenState();
}

class _RegistrationSearchScreenState
    extends ConsumerState<RegistrationSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _executeSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(registrationSearchControllerProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchState = ref.watch(registrationSearchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Credential Recovery'),
      ),
      body: Column(
        children: [
          // Search Bar & Instructions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  controller: _searchController,
                  focusNode: _focusNode,
                  hintText: 'Enter Student ID, Phone, Name, Serial, or Code...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(
                                registrationSearchControllerProvider.notifier,
                              )
                              .clear();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      tooltip: 'Search Database',
                      onPressed: _executeSearch,
                    ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  onSubmitted: (_) => _executeSearch(),
                  onChanged: (text) {
                    if (text.trim().isEmpty) {
                      ref
                          .read(
                            registrationSearchControllerProvider.notifier,
                          )
                          .clear();
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Search directly across Cloud Firestore to retrieve a student\'s official QR pass and verification code.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(context, theme, colorScheme, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    RegistrationSearchState searchState,
  ) {
    // 1. Loading state
    if (searchState.isLoading) {
      return const Center(
        child: AppLoadingIndicator(
          message: 'Searching university registration database...',
        ),
      );
    }

    // 2. Error state with retry
    if (searchState.error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AppErrorView(
            message: 'Failed to search registrations: ${searchState.error}',
            onRetry: () => ref
                .read(registrationSearchControllerProvider.notifier)
                .retry(),
          ),
        ),
      );
    }

    // 3. Initial / Idle state before searching
    if (!searchState.hasSearched) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_rounded,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Student Credential Recovery',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'If a student forgot their 6-digit code or lost their QR verification pass, enter any identifying details above to retrieve their existing registered pass.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _SearchTipChip(
                    icon: Icons.badge_outlined,
                    label: 'Student ID (e.g. UGR/...)',
                    colorScheme: colorScheme,
                  ),
                  _SearchTipChip(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    colorScheme: colorScheme,
                  ),
                  _SearchTipChip(
                    icon: Icons.person_outline_rounded,
                    label: 'Student Full Name',
                    colorScheme: colorScheme,
                  ),
                  _SearchTipChip(
                    icon: Icons.laptop_chromebook_rounded,
                    label: 'Hardware Serial No.',
                    colorScheme: colorScheme,
                  ),
                  _SearchTipChip(
                    icon: Icons.pin_outlined,
                    label: '6-Digit Code',
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 4. No-results state
    if (searchState.results.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'No Registrations Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  'No computer registrations match "${searchState.query}". Double-check the student ID, phone number, or computer serial number and try again.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _focusNode.requestFocus();
                  ref
                      .read(registrationSearchControllerProvider.notifier)
                      .clear();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Another Search'),
              ),
            ],
          ),
        ),
      );
    }

    // 5. Results List
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final reg = searchState.results[index];
        return _SearchResultCard(
          registration: reg,
          onTap: () => context.push('/registration/detail/${reg.id}'),
        );
      },
    );
  }
}

class _SearchTipChip extends StatelessWidget {
  const _SearchTipChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.registration,
    required this.onTap,
  });

  final Registration registration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isStolen = registration.isReportedStolen;
    final isSuspended = registration.isSuspended;
    final isArchived = registration.isArchived;

    Color badgeBg = Colors.green.shade50;
    Color badgeColor = Colors.green.shade800;
    if (isStolen) {
      badgeBg = Colors.red.shade50;
      badgeColor = Colors.red.shade800;
    } else if (isSuspended) {
      badgeBg = Colors.amber.shade50;
      badgeColor = Colors.amber.shade900;
    } else if (isArchived) {
      badgeBg = Colors.grey.shade200;
      badgeColor = Colors.grey.shade800;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isStolen
              ? Colors.red.shade300
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration.studentName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${registration.studentId} • Phone: ${registration.phoneNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      registration.statusDisplayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.laptop_mac_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${registration.pcBrand} ${registration.pcModel}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'SN: ${registration.serialNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (registration.registrationCode != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pin_outlined,
                            size: 14,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            registration.registrationCode!,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (registration.qrIdentifier != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'QR Pass Ready',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'View Credentials →',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
