import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/verification_repository.dart';
import '../../domain/verification_log.dart';
import '../../domain/verification_outcome.dart';

/// Filter state for verification history.
class VerificationFilterState {
  const VerificationFilterState({
    this.searchQuery = '',
    this.outcomeFilter = 'all', // 'all', 'verified', 'failed', 'flagged', 'stolen', 'suspended'
    this.methodFilter = 'all', // 'all', 'QR', 'manual_code'
    this.staffUidFilter = 'all',
    this.dateFilter = 'all', // 'all', 'today', 'this_week', 'this_month'
  });

  final String searchQuery;
  final String outcomeFilter;
  final String methodFilter;
  final String staffUidFilter;
  final String dateFilter;

  VerificationFilterState copyWith({
    String? searchQuery,
    String? outcomeFilter,
    String? methodFilter,
    String? staffUidFilter,
    String? dateFilter,
  }) {
    return VerificationFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      outcomeFilter: outcomeFilter ?? this.outcomeFilter,
      methodFilter: methodFilter ?? this.methodFilter,
      staffUidFilter: staffUidFilter ?? this.staffUidFilter,
      dateFilter: dateFilter ?? this.dateFilter,
    );
  }
}

class VerificationFilterNotifier extends Notifier<VerificationFilterState> {
  @override
  VerificationFilterState build() => const VerificationFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setOutcomeFilter(String outcome) {
    state = state.copyWith(outcomeFilter: outcome);
  }

  void setMethodFilter(String method) {
    state = state.copyWith(methodFilter: method);
  }

  void setStaffFilter(String staffUid) {
    state = state.copyWith(staffUidFilter: staffUid);
  }

  void setDateFilter(String date) {
    state = state.copyWith(dateFilter: date);
  }

  void reset() {
    state = const VerificationFilterState();
  }
}

final verificationFilterProvider =
    NotifierProvider<VerificationFilterNotifier, VerificationFilterState>(
  VerificationFilterNotifier.new,
);

/// Provider returning filtered verification logs.
final filteredVerificationLogsProvider =
    Provider<AsyncValue<List<VerificationLog>>>((ref) {
  final allAsync = ref.watch(allVerificationLogsStreamProvider);
  final filter = ref.watch(verificationFilterProvider);

  return allAsync.whenData((logs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    return logs.where((log) {
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase().trim();
        final matchRegId = log.registrationId.toLowerCase().contains(query);
        final matchOfficer =
            (log.verifiedByName ?? '').toLowerCase().contains(query);
        final matchNotes = (log.notes ?? '').toLowerCase().contains(query);
        if (!matchRegId && !matchOfficer && !matchNotes) {
          return false;
        }
      }

      if (filter.outcomeFilter != 'all') {
        if (filter.outcomeFilter == 'flagged') {
          if (log.result != VerificationOutcome.mismatch &&
              log.result != VerificationOutcome.stolen &&
              log.result != VerificationOutcome.suspended) {
            return false;
          }
        } else if (log.result.value != filter.outcomeFilter) {
          return false;
        }
      }

      if (filter.methodFilter != 'all') {
        if (log.method != filter.methodFilter) {
          return false;
        }
      }

      if (filter.staffUidFilter != 'all') {
        if (log.verifiedBy != filter.staffUidFilter) {
          return false;
        }
      }

      if (filter.dateFilter != 'all' && log.timestamp != null) {
        final logDate = log.timestamp!;
        if (filter.dateFilter == 'today') {
          if (logDate.isBefore(todayStart)) return false;
        } else if (filter.dateFilter == 'this_week') {
          if (logDate.isBefore(weekStart)) return false;
        } else if (filter.dateFilter == 'this_month') {
          if (logDate.isBefore(monthStart)) return false;
        }
      }

      return true;
    }).toList();
  });
});
