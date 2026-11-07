import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/staff_profile.dart';
import '../../../registration/presentation/controllers/registration_list_controller.dart';
import '../../../verification/data/verification_repository.dart';
import '../../../verification/domain/verification_outcome.dart';
import 'staff_management_controller.dart';

/// Aggregated activity metrics for an individual staff member derived from real Firestore records.
class StaffActivitySummary {
  const StaffActivitySummary({
    required this.profile,
    required this.registrationCount,
    required this.activeRegistrationCount,
    required this.verificationCount,
    required this.verifiedCount,
    required this.flaggedCount,
    this.lastActiveDate,
  });

  final StaffProfile profile;
  final int registrationCount;
  final int activeRegistrationCount;
  final int verificationCount;
  final int verifiedCount;
  final int flaggedCount;
  final DateTime? lastActiveDate;

  int get totalActivity => registrationCount + verificationCount;
}

/// Provider computing real-time staff activity and accountability statistics for administrators.
final staffActivityListProvider =
    Provider<AsyncValue<List<StaffActivitySummary>>>((ref) {
  final staffAsync = ref.watch(allStaffStreamProvider);
  final registrationsAsync = ref.watch(allRegistrationsStreamProvider);
  final logsAsync = ref.watch(allVerificationLogsStreamProvider);

  if (staffAsync.hasError) return AsyncValue.error(staffAsync.error!, staffAsync.stackTrace!);
  if (registrationsAsync.hasError) return AsyncValue.error(registrationsAsync.error!, registrationsAsync.stackTrace!);
  if (logsAsync.hasError) return AsyncValue.error(logsAsync.error!, logsAsync.stackTrace!);

  if (staffAsync.isLoading || registrationsAsync.isLoading || logsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final staffList = staffAsync.value ?? [];
  final registrations = registrationsAsync.value ?? [];
  final logs = logsAsync.value ?? [];

  final summaries = staffList.map((staff) {
    final staffRegistrations =
        registrations.where((r) => r.registeredBy == staff.uid).toList();
    final staffLogs = logs.where((l) => l.verifiedBy == staff.uid).toList();

    final regCount = staffRegistrations.length;
    final activeRegCount = staffRegistrations.where((r) => r.isActive).length;

    final verCount = staffLogs.length;
    final verSuccessCount =
        staffLogs.where((l) => l.result == VerificationOutcome.verified).length;
    final verFlaggedCount = staffLogs
        .where((l) =>
            l.result == VerificationOutcome.stolen ||
            l.result == VerificationOutcome.suspended ||
            l.result == VerificationOutcome.mismatch)
        .length;

    DateTime? latestDate = staff.createdAt;
    for (final reg in staffRegistrations) {
      if (reg.registeredAt != null &&
          (latestDate == null || reg.registeredAt!.isAfter(latestDate))) {
        latestDate = reg.registeredAt;
      }
    }
    for (final log in staffLogs) {
      if (log.timestamp != null &&
          (latestDate == null || log.timestamp!.isAfter(latestDate))) {
        latestDate = log.timestamp;
      }
    }

    return StaffActivitySummary(
      profile: staff,
      registrationCount: regCount,
      activeRegistrationCount: activeRegCount,
      verificationCount: verCount,
      verifiedCount: verSuccessCount,
      flaggedCount: verFlaggedCount,
      lastActiveDate: latestDate,
    );
  }).toList();

  // Sort by highest activity first
  summaries.sort((a, b) => b.totalActivity.compareTo(a.totalActivity));

  return AsyncValue.data(summaries);
});
