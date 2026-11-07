import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/controllers/staff_management_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../registration/presentation/controllers/registration_list_controller.dart';
import '../../../verification/data/verification_repository.dart';
import '../../../verification/domain/verification_outcome.dart';

/// Admin operational statistics calculated from live Firestore data.
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalRegistrations,
    required this.activeRegistrations,
    required this.suspendedRegistrations,
    required this.reportedStolenRegistrations,
    required this.totalVerifications,
    required this.verifiedVerifications,
    required this.flaggedVerifications,
    required this.totalStaff,
    required this.activeStaff,
    required this.inactiveStaff,
  });

  final int totalRegistrations;
  final int activeRegistrations;
  final int suspendedRegistrations;
  final int reportedStolenRegistrations;
  final int totalVerifications;
  final int verifiedVerifications;
  final int flaggedVerifications;
  final int totalStaff;
  final int activeStaff;
  final int inactiveStaff;
}

final adminDashboardStatsProvider =
    Provider<AsyncValue<AdminDashboardStats>>((ref) {
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

  final totalStaff = staffList.length;
  final activeStaff = staffList.where((s) => s.active).length;
  final inactiveStaff = totalStaff - activeStaff;

  final totalRegs = registrations.length;
  final activeRegs = registrations.where((r) => r.isActive).length;
  final suspendedRegs = registrations.where((r) => r.isSuspended).length;
  final stolenRegs = registrations.where((r) => r.isReportedStolen).length;

  final totalVers = logs.length;
  final verifiedVers =
      logs.where((l) => l.result == VerificationOutcome.verified).length;
  final flaggedVers = logs
      .where((l) =>
          l.result == VerificationOutcome.stolen ||
          l.result == VerificationOutcome.suspended ||
          l.result == VerificationOutcome.mismatch)
      .length;

  return AsyncValue.data(
    AdminDashboardStats(
      totalRegistrations: totalRegs,
      activeRegistrations: activeRegs,
      suspendedRegistrations: suspendedRegs,
      reportedStolenRegistrations: stolenRegs,
      totalVerifications: totalVers,
      verifiedVerifications: verifiedVers,
      flaggedVerifications: flaggedVers,
      totalStaff: totalStaff,
      activeStaff: activeStaff,
      inactiveStaff: inactiveStaff,
    ),
  );
});

/// Registration officer personal operational statistics.
class OfficerRegistrationStats {
  const OfficerRegistrationStats({
    required this.myTotalRegistrations,
    required this.myActiveRegistrations,
    required this.systemTotalRegistrations,
  });

  final int myTotalRegistrations;
  final int myActiveRegistrations;
  final int systemTotalRegistrations;
}

final officerRegistrationStatsProvider =
    Provider<AsyncValue<OfficerRegistrationStats>>((ref) {
  final currentProfile = ref.watch(appAuthStateProvider).profile;
  final registrationsAsync = ref.watch(allRegistrationsStreamProvider);

  return registrationsAsync.whenData((registrations) {
    final uid = currentProfile?.uid ?? '';
    final myRegs = registrations.where((r) => r.registeredBy == uid).toList();
    final myActive = myRegs.where((r) => r.isActive).length;

    return OfficerRegistrationStats(
      myTotalRegistrations: myRegs.length,
      myActiveRegistrations: myActive,
      systemTotalRegistrations: registrations.length,
    );
  });
});

/// Verification operational statistics for checkpoint and library staff.
class CheckpointVerificationStats {
  const CheckpointVerificationStats({
    required this.totalVerifications,
    required this.verifiedCount,
    required this.flaggedCount,
    required this.todayCount,
  });

  final int totalVerifications;
  final int verifiedCount;
  final int flaggedCount;
  final int todayCount;
}

final checkpointVerificationStatsProvider =
    Provider<AsyncValue<CheckpointVerificationStats>>((ref) {
  final logsAsync = ref.watch(allVerificationLogsStreamProvider);

  return logsAsync.whenData((logs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final verified =
        logs.where((l) => l.result == VerificationOutcome.verified).length;
    final flagged = logs
        .where((l) =>
            l.result == VerificationOutcome.stolen ||
            l.result == VerificationOutcome.suspended ||
            l.result == VerificationOutcome.mismatch)
        .length;
    final today = logs.where((l) {
      if (l.timestamp == null) return false;
      return l.timestamp!.isAfter(todayStart);
    }).length;

    return CheckpointVerificationStats(
      totalVerifications: logs.length,
      verifiedCount: verified,
      flaggedCount: flagged,
      todayCount: today,
    );
  });
});
