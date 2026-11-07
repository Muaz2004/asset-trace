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
    this.statusFilter = 'all', // 'all', 'active', 'inactive'
  });

  final String searchQuery;
  final String statusFilter;

  RegistrationFilterState copyWith({
    String? searchQuery,
    String? statusFilter,
  }) {
    return RegistrationFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
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

  void reset() {
    state = const RegistrationFilterState();
  }
}

final registrationFilterProvider =
    NotifierProvider<RegistrationFilterNotifier, RegistrationFilterState>(
  RegistrationFilterNotifier.new,
);

/// Provider returning filtered registrations based on search query and status filter.
final filteredRegistrationsProvider =
    Provider<AsyncValue<List<Registration>>>((ref) {
  final allAsync = ref.watch(allRegistrationsStreamProvider);
  final filter = ref.watch(registrationFilterProvider);

  return allAsync.whenData((registrations) {
    return registrations.where((reg) {
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase().trim();
        final matchStudentId = reg.studentId.toLowerCase().contains(query);
        final matchSerial = reg.serialNumber.toLowerCase().contains(query);
        final matchStudentName = reg.studentName.toLowerCase().contains(query);
        final matchBrand = reg.pcBrand.toLowerCase().contains(query);
        if (!matchStudentId &&
            !matchSerial &&
            !matchStudentName &&
            !matchBrand) {
          return false;
        }
      }

      if (filter.statusFilter != 'all') {
        if (reg.status != filter.statusFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});
