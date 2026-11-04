import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/data/staff_repository.dart';
import '../../../../features/auth/domain/staff_profile.dart';
import '../../../../features/auth/domain/staff_role.dart';

/// Provider watching the entire staff list from Firestore.
final allStaffStreamProvider = StreamProvider<List<StaffProfile>>((ref) {
  final staffRepository = ref.watch(staffRepositoryProvider);
  return staffRepository.watchAllStaff();
});

/// Filter state for the staff list view.
class StaffFilterState {
  const StaffFilterState({
    this.searchQuery = '',
    this.roleFilter,
    this.statusFilter,
  });

  final String searchQuery;
  final StaffRole? roleFilter;
  final bool? statusFilter; // null: all, true: active, false: inactive

  StaffFilterState copyWith({
    String? searchQuery,
    StaffRole? Function()? roleFilter,
    bool? Function()? statusFilter,
  }) {
    return StaffFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter != null ? roleFilter() : this.roleFilter,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
    );
  }
}

/// Provider managing the active filter criteria on the staff list screen.
class StaffFilterNotifier extends Notifier<StaffFilterState> {
  @override
  StaffFilterState build() => const StaffFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setRoleFilter(StaffRole? role) {
    state = state.copyWith(roleFilter: () => role);
  }

  void setStatusFilter(bool? status) {
    state = state.copyWith(statusFilter: () => status);
  }

  void reset() {
    state = const StaffFilterState();
  }
}

final staffFilterProvider =
    NotifierProvider<StaffFilterNotifier, StaffFilterState>(
  StaffFilterNotifier.new,
);

/// Provider yielding filtered staff members based on search query and filter criteria.
final filteredStaffListProvider = Provider<AsyncValue<List<StaffProfile>>>((ref) {
  final allStaffAsync = ref.watch(allStaffStreamProvider);
  final filter = ref.watch(staffFilterProvider);

  return allStaffAsync.whenData((staffList) {
    return staffList.where((staff) {
      // Search query match (name or email)
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase().trim();
        final matchesName = staff.name.toLowerCase().contains(query);
        final matchesEmail = staff.email.toLowerCase().contains(query);
        if (!matchesName && !matchesEmail) {
          return false;
        }
      }

      // Role filter match
      if (filter.roleFilter != null && staff.role != filter.roleFilter) {
        return false;
      }

      // Status filter match
      if (filter.statusFilter != null && staff.active != filter.statusFilter) {
        return false;
      }

      return true;
    }).toList();
  });
});

/// Async notifier managing administrative mutations (creating staff, updating roles, status).
class StaffManagementController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Creates a new staff account safely without modifying the administrator's session.
  Future<StaffProfile?> createStaff({
    required String name,
    required String email,
    required StaffRole role,
    required String temporaryPassword,
  }) async {
    state = const AsyncLoading();
    try {
      final staffRepo = ref.read(staffRepositoryProvider);
      final profile = await staffRepo.createStaffAccount(
        name: name,
        email: email,
        role: role,
        temporaryPassword: temporaryPassword,
      );
      state = const AsyncData(null);
      return profile;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Updates staff profile details (name).
  Future<bool> updateStaffProfile(String uid, {required String name}) async {
    state = const AsyncLoading();
    try {
      final staffRepo = ref.read(staffRepositoryProvider);
      await staffRepo.updateStaffProfile(uid, name: name);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Assigns a new role to a staff member.
  /// Prevents self-role demotion if operating on the current admin's own UID.
  Future<bool> assignRole(String targetUid, StaffRole newRole) async {
    final currentUid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (currentUid == targetUid && newRole != StaffRole.admin) {
      state = AsyncError(
        'Security restriction: You cannot remove administrator privileges from your own account.',
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      final staffRepo = ref.read(staffRepositoryProvider);
      await staffRepo.updateStaffRole(targetUid, newRole);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Activates or deactivates a staff member account.
  /// Prevents an administrator from deactivating their own account.
  Future<bool> setStaffActiveStatus(String targetUid, bool active) async {
    final currentUid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (currentUid == targetUid && !active) {
      state = AsyncError(
        'Security restriction: You cannot deactivate your own administrator account.',
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      final staffRepo = ref.read(staffRepositoryProvider);
      await staffRepo.setStaffActiveStatus(targetUid, active);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final staffManagementControllerProvider =
    AsyncNotifierProvider.autoDispose<StaffManagementController, void>(
  StaffManagementController.new,
);
