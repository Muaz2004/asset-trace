import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/staff_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../registration/data/registration_repository.dart';
import '../../../registration/domain/registration.dart';
import '../../data/verification_repository.dart';
import '../../domain/verification_outcome.dart';

/// Screen enabling authorized staff to perform physical inspection of student and computer
/// against the Cloudinary-stored photographs and record an immutable verification outcome.
class OwnershipVerificationScreen extends ConsumerStatefulWidget {
  const OwnershipVerificationScreen({
    required this.registrationId,
    this.verificationMethod = 'QR',
    super.key,
  });

  final String registrationId;
  final String verificationMethod; // 'QR' or 'manual_code'

  @override
  ConsumerState<OwnershipVerificationScreen> createState() =>
      _OwnershipVerificationScreenState();
}

class _OwnershipVerificationScreenState
    extends ConsumerState<OwnershipVerificationScreen> {
  VerificationOutcome _selectedOutcome = VerificationOutcome.verified;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showImageModal(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 240,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
                          SizedBox(height: 8),
                          Text('Image could not be loaded', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordOutcome(Registration registration) async {
    final notes = _notesController.text.trim();
    if (_selectedOutcome != VerificationOutcome.verified && notes.isEmpty) {
      setState(() {
        _submissionError = 'Staff inspection notes are required for any non-verified outcome.';
      });
      return;
    }

    final authState = ref.read(appAuthStateProvider);
    final profile = authState.profile;

    if (profile == null) {
      setState(() {
        _submissionError = 'Authentication error: Active staff profile not found. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final verificationRepo = ref.read(verificationRepositoryProvider);
      await verificationRepo.recordVerificationAttempt(
        registrationId: registration.id,
        verifiedBy: profile.uid,
        verifiedByName: profile.name,
        verifiedByRole: profile.role.value,
        method: widget.verificationMethod,
        result: _selectedOutcome,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // Show outcome confirmation banner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification logged: ${_selectedOutcome.displayName}',
          ),
          backgroundColor: _selectedOutcome.color,
          duration: const Duration(seconds: 3),
        ),
      );

      // Return to appropriate staff dashboard
      final role = profile.role;
      if (role == StaffRole.libraryStaff) {
        context.go(RoutePaths.libraryDashboard);
      } else if (role == StaffRole.securityOfficer) {
        context.go(RoutePaths.securityDashboard);
      } else if (role == StaffRole.admin) {
        context.go(RoutePaths.adminDashboard);
      } else {
        context.go(RoutePaths.registrationDashboard);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionError = 'Failed to record verification: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final registrationRepo = ref.watch(registrationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Physical PC Inspection'),
      ),
      body: StreamBuilder<Registration?>(
        stream: registrationRepo.watchRegistration(widget.registrationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Loading ownership record...');
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: 'Failed to load record: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          final registration = snapshot.data;
          if (registration == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Registration Record Not Found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The specified registration reference does not exist or has been removed.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Return to Scanner'),
                    ),
                  ],
                ),
              ),
            );
          }

          final isStolenOrSuspended = !registration.isActive;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Notice if Stolen or Suspended
                      if (isStolenOrSuspended)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300, width: 2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_rounded, color: Colors.red.shade800, size: 36),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'REGISTRATION STATUS: ${registration.status.toUpperCase()}',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Alert: This computer is flagged as ${registration.status}. Campus security protocol must be initiated.',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Instruction Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.compare_rounded, color: colorScheme.primary, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Compare the physical student and computer with the registered photographs below before clearing passage.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Verification Cards Grid (Student vs Computer)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          return isNarrow
                              ? Column(
                                  children: [
                                    _buildStudentCard(context, registration),
                                    const SizedBox(height: 16),
                                    _buildComputerCard(context, registration),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildStudentCard(context, registration)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildComputerCard(context, registration)),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Registration Meta Card
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'REGISTRATION CREDENTIALS',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: registration.isActive
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      registration.status.toUpperCase(),
                                      style: TextStyle(
                                        color: registration.isActive
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('6-Digit Code', style: theme.textTheme.bodySmall),
                                        Text(
                                          registration.registrationCode ?? 'None',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Pass Reference', style: theme.textTheme.bodySmall),
                                        Text(
                                          registration.id,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 28),

                      // Verification Outcome Selection
                      Text(
                        'Physical Verification Outcome',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the outcome following your direct physical inspection.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Outcome Options
                      Card(
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: VerificationOutcome.values
                                .where((o) => o != VerificationOutcome.notFound)
                                .map((outcome) {
                              final isSelected = _selectedOutcome == outcome;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedOutcome = outcome;
                                    _submissionError = null;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: isSelected
                                            ? outcome.color
                                            : colorScheme.outline,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  outcome.icon,
                                                  size: 18,
                                                  color: outcome.color,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  outcome.displayName,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    color: isSelected ? outcome.color : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              outcome.description,
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
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Staff Notes
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: _selectedOutcome == VerificationOutcome.verified
                              ? 'Inspection Notes (Optional)'
                              : 'Inspection Notes (Required)',
                          hintText: 'Enter checkpoint observations, reason for mismatch, etc.',
                          border: const OutlineInputBorder(),
                          errorText: _submissionError,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : () => _recordOutcome(registration),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(_selectedOutcome.icon),
                        label: Text(
                          _isSubmitting
                              ? 'Recording Outcome...'
                              : 'Record ${_selectedOutcome.displayName}',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _selectedOutcome.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel & Return'),
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

  Widget _buildStudentCard(BuildContext context, Registration registration) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.person_rounded, size: 20, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'REGISTERED STUDENT',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          // Student Photo via Cloudinary HTTPS URL
          GestureDetector(
            onTap: registration.studentWithPcPhotoUrl.isNotEmpty
                ? () => _showImageModal(
                      registration.studentWithPcPhotoUrl,
                      'Student Identification Photo',
                    )
                : null,
            child: Container(
              height: 220,
              color: Colors.grey.shade100,
              child: registration.studentWithPcPhotoUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          registration.studentWithPcPhotoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Photo unavailable', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to view',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text('No student photograph recorded'),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registration.studentName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      registration.studentId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      registration.phoneNumber,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComputerCard(BuildContext context, Registration registration) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: colorScheme.secondaryContainer,
            child: Row(
              children: [
                Icon(Icons.laptop_chromebook_rounded, size: 20, color: colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  'REGISTERED COMPUTER',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          // Computer Photo via Cloudinary HTTPS URL
          GestureDetector(
            onTap: registration.pcPhotoUrl.isNotEmpty
                ? () => _showImageModal(
                      registration.pcPhotoUrl,
                      'Computer Verification Photo',
                    )
                : null,
            child: Container(
              height: 220,
              color: Colors.grey.shade100,
              child: registration.pcPhotoUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          registration.pcPhotoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Photo unavailable', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to view',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text('No computer photograph recorded'),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${registration.pcBrand} ${registration.pcModel}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Serial: ${registration.serialNumber}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.devices_rounded, size: 16, color: colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      'Brand: ${registration.pcBrand}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
