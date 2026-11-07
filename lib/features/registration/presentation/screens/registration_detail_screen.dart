import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/staff_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../verification/data/verification_repository.dart';
import '../../data/registration_repository.dart';
import '../../domain/registration.dart';

/// Screen displaying the complete verified ownership record, photographs, and status management for a registered PC.
class RegistrationDetailScreen extends ConsumerWidget {
  const RegistrationDetailScreen({super.key, required this.registrationId});

  final String registrationId;

  void _showImageZoom(BuildContext context, String imageUrl, String title) {
    if (imageUrl.trim().isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 300,
                        color: Colors.black87,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      height: 300,
                      color: Colors.black87,
                      child: const Center(
                        child: Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  void _showStatusDialog(BuildContext context, WidgetRef ref, Registration reg) {
    final authState = ref.read(appAuthStateProvider);
    final profile = authState.profile;
    if (profile == null) return;

    final isSuspendedOrStolen = reg.isSuspended || reg.isReportedStolen;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final reasonController = TextEditingController();
        String selectedStatus = isSuspendedOrStolen ? 'active' : 'suspended';
        bool isSubmitting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isSuspendedOrStolen
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    color: isSuspendedOrStolen ? Colors.green : Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Text(isSuspendedOrStolen
                      ? 'Reactivate Registration'
                      : 'Change Registration Status'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isSuspendedOrStolen) ...[
                      const Text(
                        'Select action to apply to this computer registration:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'suspended',
                            label: Text('Suspend'),
                            icon: Icon(Icons.pause_circle_outline),
                          ),
                          ButtonSegment(
                            value: 'reported_stolen',
                            label: Text('Report Stolen'),
                            icon: Icon(Icons.warning_amber_rounded),
                          ),
                        ],
                        selected: {selectedStatus},
                        onSelectionChanged: (newSelection) {
                          setState(() => selectedStatus = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedStatus == 'suspended'
                            ? 'Temporarily blocks verification access at library & checkpoints.'
                            : 'Flags computer as stolen. Checkpoints will immediately alert security officers.',
                        style: TextStyle(
                          fontSize: 12,
                          color: selectedStatus == 'reported_stolen'
                              ? Colors.red.shade800
                              : Colors.amber.shade900,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Reactivating this registration will restore verified status and allow access at campus checkpoints.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isSuspendedOrStolen
                            ? 'Resolution Reason / Notes *'
                            : 'Reason for Status Change *',
                        hintText: isSuspendedOrStolen
                            ? 'e.g. Computer recovered or investigation resolved'
                            : 'e.g. Student reported stolen at library on Nov 7',
                        border: const OutlineInputBorder(),
                        errorText: errorMessage,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedStatus == 'reported_stolen'
                        ? Colors.red
                        : (selectedStatus == 'suspended' ? Colors.amber.shade800 : Colors.green),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            setState(() {
                              errorMessage = 'A specific reason is mandatory.';
                            });
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });

                          try {
                            final repo = ref.read(registrationRepositoryProvider);
                            await repo.updateRegistrationStatus(
                              registrationId: reg.id,
                              newStatus: selectedStatus,
                              reason: reason,
                              changedBy: profile.uid,
                              changedByName: profile.name,
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    selectedStatus == 'active'
                                        ? 'Registration reactivated successfully.'
                                        : 'Registration marked as ${selectedStatus.replaceAll('_', ' ')}.',
                                  ),
                                  backgroundColor: selectedStatus == 'active'
                                      ? Colors.green
                                      : Colors.orange.shade800,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isSubmitting = false;
                              errorMessage = 'Failed to update status: $e';
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isSuspendedOrStolen
                          ? 'Confirm Reactivation'
                          : 'Confirm Status Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final registrationStream =
        ref.watch(registrationRepositoryProvider).watchRegistration(registrationId);
    final currentRole = ref.watch(appAuthStateProvider).profile?.role;
    final canManage =
        currentRole == StaffRole.admin || currentRole == StaffRole.registrationOfficer;

    return StreamBuilder<Registration?>(
      stream: registrationStream,
      builder: (context, snapshot) {
        final reg = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Registration Details'),
            actions: [
              if (reg != null && canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'Management Options',
                  onSelected: (val) {
                    if (val == 'edit') {
                      context.push('/registration/edit/${reg.id}');
                    } else if (val == 'status') {
                      _showStatusDialog(context, ref, reg);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit Registration'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: ListTile(
                        leading: Icon(
                          reg.isActive
                              ? Icons.block_flipped
                              : Icons.check_circle_outline,
                          color: reg.isActive ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          reg.isActive
                              ? 'Suspend / Report Stolen'
                              : 'Reactivate Registration',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: () {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingIndicator(
                message: 'Loading registration record...',
              );
            }

            if (snapshot.hasError) {
              return AppErrorView(
                message: 'Failed to retrieve record: ${snapshot.error}',
              );
            }

            if (reg == null) {
              return const Center(
                child: Text('Registration record not found.'),
              );
            }

            final registeredDateStr = reg.registeredAt != null
                ? '${reg.registeredAt!.year}-${reg.registeredAt!.month.toString().padLeft(2, '0')}-${reg.registeredAt!.day.toString().padLeft(2, '0')} ${reg.registeredAt!.hour.toString().padLeft(2, '0')}:${reg.registeredAt!.minute.toString().padLeft(2, '0')}'
                : 'Unknown';

            return SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sensitive Status Warning Banners
                        if (reg.isReportedStolen) ...[
                          Card(
                            color: Colors.red.shade900,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.white, size: 36),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'REPORTED STOLEN COMPUTER',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        if (reg.statusReason != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Reason: ${reg.statusReason}',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13),
                                          ),
                                        ],
                                        if (reg.statusChangedByName != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Reported by: ${reg.statusChangedByName}',
                                            style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (reg.isSuspended) ...[
                          Card(
                            color: Colors.amber.shade900,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.pause_circle_filled_rounded,
                                      color: Colors.white, size: 36),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'REGISTRATION SUSPENDED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        if (reg.statusReason != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Reason: ${reg.statusReason}',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13),
                                          ),
                                        ],
                                        if (reg.statusChangedByName != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Suspended by: ${reg.statusChangedByName}',
                                            style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Header Summary Card
                        Card(
                          color: colorScheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.verified_user_rounded,
                                    color: colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reg.studentName,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: reg.isActive
                                                  ? Colors.green.shade50
                                                  : (reg.isReportedStolen
                                                      ? Colors.red.shade50
                                                      : Colors.amber.shade50),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              reg.statusDisplayName,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: reg.isActive
                                                    ? Colors.green.shade800
                                                    : (reg.isReportedStolen
                                                        ? Colors.red.shade800
                                                        : Colors.amber.shade900),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${reg.studentId} • ${reg.phoneNumber}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${reg.pcBrand} ${reg.pcModel}',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
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

                        // Photographs Card (Using existing Cloudinary URLs)
                        Card(
                          color: colorScheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verification Photographs',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap any photograph to view in full resolution.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _PhotoPreviewBox(
                                        title: 'Computer Photo',
                                        imageUrl: reg.pcPhotoUrl,
                                        onTap: () => _showImageZoom(
                                          context,
                                          reg.pcPhotoUrl,
                                          'Computer Photo',
                                        ),
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _PhotoPreviewBox(
                                        title: 'Student with Computer',
                                        imageUrl: reg.studentWithPcPhotoUrl,
                                        onTap: () => _showImageZoom(
                                          context,
                                          reg.studentWithPcPhotoUrl,
                                          'Student with Computer',
                                        ),
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Hardware Specifications Card
                        Card(
                          color: colorScheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hardware Specifications',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 20),
                                _DetailRow(
                                  label: 'Brand',
                                  value: reg.pcBrand,
                                ),
                                const SizedBox(height: 10),
                                _DetailRow(
                                  label: 'Model',
                                  value: reg.pcModel,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 130,
                                      child: Text(
                                        'Serial Number',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            reg.serialNumber,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => _copyToClipboard(
                                              context,
                                              reg.serialNumber,
                                              'Serial number',
                                            ),
                                            child: Icon(
                                              Icons.copy_rounded,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Audit & Registration Record Card
                        Card(
                          color: colorScheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audit & Registration Metadata',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 130,
                                      child: Text(
                                        'Registration ID',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reg.id,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _copyToClipboard(
                                              context,
                                              reg.id,
                                              'Registration ID',
                                            ),
                                            child: Icon(
                                              Icons.copy_rounded,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (reg.registrationCode != null) ...[
                                  const SizedBox(height: 10),
                                  _DetailRow(
                                    label: '6-Digit Code',
                                    value: reg.registrationCode!,
                                  ),
                                ],
                                const SizedBox(height: 10),
                                _DetailRow(
                                  label: 'Registered On',
                                  value: registeredDateStr,
                                ),
                                const SizedBox(height: 10),
                                _DetailRow(
                                  label: 'Registered By',
                                  value: reg.registeredByName ?? reg.registeredBy,
                                ),
                                if (reg.registeredByEmail != null) ...[
                                  const SizedBox(height: 10),
                                  _DetailRow(
                                    label: 'Officer Email',
                                    value: reg.registeredByEmail!,
                                  ),
                                ],
                                if (reg.updatedByName != null) ...[
                                  const SizedBox(height: 10),
                                  _DetailRow(
                                    label: 'Last Updated By',
                                    value: reg.updatedByName!,
                                  ),
                                ],
                                if (reg.statusReason != null) ...[
                                  const SizedBox(height: 10),
                                  _DetailRow(
                                    label: 'Status Note',
                                    value: reg.statusReason!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Verification Logs for this Registration
                        _RegistrationVerificationHistorySection(
                          registrationId: reg.id,
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }(),
        );
      },
    );
  }
}

class _RegistrationVerificationHistorySection extends ConsumerWidget {
  const _RegistrationVerificationHistorySection({
    required this.registrationId,
    required this.colorScheme,
    required this.theme,
  });

  final String registrationId;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync =
        ref.watch(registrationVerificationLogsStreamProvider(registrationId));

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Physical Verification Audit Trail',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.history_rounded, size: 20, color: colorScheme.primary),
              ],
            ),
            const Divider(height: 20),
            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'No physical inspection events recorded yet for this computer.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 5 ? 5 : logs.length,
                  separatorBuilder: (context, index) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final dateStr = log.timestamp != null
                        ? '${log.timestamp!.year}-${log.timestamp!.month.toString().padLeft(2, '0')}-${log.timestamp!.day.toString().padLeft(2, '0')} ${log.timestamp!.hour.toString().padLeft(2, '0')}:${log.timestamp!.minute.toString().padLeft(2, '0')}'
                        : 'Unknown';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          log.result.icon,
                          color: log.result.color,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${log.result.displayName} via ${log.isQrMethod ? 'QR Pass' : '6-Digit Code'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'By: ${log.verifiedByName ?? log.verifiedBy} • $dateStr',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (log.notes != null && log.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Note: ${log.notes}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(
                'Failed to load verification logs: $e',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
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
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoPreviewBox extends StatelessWidget {
  const _PhotoPreviewBox({
    required this.title,
    required this.imageUrl,
    required this.onTap,
    required this.colorScheme,
  });

  final String title;
  final String imageUrl;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = imageUrl.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: hasValidUrl ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 140,
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest,
              child: hasValidUrl
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: colorScheme.outline),
                            const SizedBox(height: 4),
                            Text(
                              'Unable to load',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined,
                              color: colorScheme.outline),
                          const SizedBox(height: 4),
                          Text(
                            'No photo available',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
