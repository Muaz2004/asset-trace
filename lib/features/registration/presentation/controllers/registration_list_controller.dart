import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/registration_repository.dart';
import '../../domain/registration.dart';

/// Stream provider watching all registrations in real time.
final allRegistrationsStreamProvider =
    StreamProvider<List<Registration>>((ref) {
  final repository = ref.watch(registrationRepositoryProvider);
  return repository.watchAllRegistrations();
});

/// Filter state for registration list.
class RegistrationFilterState {
  const RegistrationFilterState({
    this.searchQuery = '',
    this.statusFilter = 'all', // 'all', 'active', 'suspended', 'reported_stolen', 'inactive'
    this.dateFilter = 'all', // 'all', 'today', 'this_week', 'this_month', 'custom'
    this.customStartDate,
    this.customEndDate,
  });

  final String searchQuery;
  final String statusFilter;
  final String dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  RegistrationFilterState copyWith({
    String? searchQuery,
    String? statusFilter,
    String? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return RegistrationFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

class RegistrationFilterNotifier extends Notifier<RegistrationFilterState> {
  @override
  RegistrationFilterState build() => const RegistrationFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void setDateFilter(String dateFilter, {DateTime? start, DateTime? end}) {
    state = state.copyWith(
      dateFilter: dateFilter,
      customStartDate: start,
      customEndDate: end,
    );
  }

  void reset() {
    state = const RegistrationFilterState();
  }
}

final registrationFilterProvider =
    NotifierProvider<RegistrationFilterNotifier, RegistrationFilterState>(
  RegistrationFilterNotifier.new,
);

/// Provider returning filtered registrations based on search query, status, and date filters.
final filteredRegistrationsProvider =
    Provider<AsyncValue<List<Registration>>>((ref) {
  final allAsync = ref.watch(allRegistrationsStreamProvider);
  final filter = ref.watch(registrationFilterProvider);

  return allAsync.whenData((registrations) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    return registrations.where((reg) {
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase().trim();
        final matchStudentId = reg.studentId.toLowerCase().contains(query);
        final matchSerial = reg.serialNumber.toLowerCase().contains(query);
        final matchStudentName = reg.studentName.toLowerCase().contains(query);
        final matchBrand = reg.pcBrand.toLowerCase().contains(query);
        final matchModel = reg.pcModel.toLowerCase().contains(query);
        final matchCode =
            (reg.registrationCode ?? '').toLowerCase().contains(query);
        final matchId = reg.id.toLowerCase().contains(query);

        if (!matchStudentId &&
            !matchSerial &&
            !matchStudentName &&
            !matchBrand &&
            !matchModel &&
            !matchCode &&
            !matchId) {
          return false;
        }
      }

      // Status filter
      if (filter.statusFilter != 'all') {
        if (filter.statusFilter == 'active') {
          if (!reg.isActive) return false;
        } else if (filter.statusFilter == 'suspended') {
          if (!reg.isSuspended) return false;
        } else if (filter.statusFilter == 'reported_stolen') {
          if (!reg.isReportedStolen) return false;
        } else if (filter.statusFilter == 'inactive') {
          if (reg.isActive) return false;
        } else if (reg.status != filter.statusFilter) {
          return false;
        }
      }

      // Date filter
      if (filter.dateFilter != 'all' && reg.registeredAt != null) {
        final regDate = reg.registeredAt!;
        if (filter.dateFilter == 'today') {
          if (regDate.isBefore(todayStart)) return false;
        } else if (filter.dateFilter == 'this_week') {
          if (regDate.isBefore(weekStart)) return false;
        } else if (filter.dateFilter == 'this_month') {
          if (regDate.isBefore(monthStart)) return false;
        } else if (filter.dateFilter == 'custom') {
          if (filter.customStartDate != null &&
              regDate.isBefore(filter.customStartDate!)) {
            return false;
          }
          if (filter.customEndDate != null &&
              regDate.isAfter(filter.customEndDate!)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  });
});

