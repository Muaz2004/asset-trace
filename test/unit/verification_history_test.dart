import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aau_pc_verify/features/verification/data/verification_repository.dart';
import 'package:aau_pc_verify/features/verification/domain/verification_log.dart';
import 'package:aau_pc_verify/features/verification/domain/verification_outcome.dart';
import 'package:aau_pc_verify/features/verification/presentation/controllers/verification_history_controller.dart';

void main() {
  group('Verification History Controller & Filter Logic Tests', () {
    final now = DateTime.now();
    final sampleLogs = [
      VerificationLog(
        id: 'log-1',
        registrationId: 'reg-alpha-123',
        verifiedBy: 'officer-1',
        verifiedByName: 'Dawit Security',
        verifiedByRole: 'security_officer',
        method: 'QR',
        result: VerificationOutcome.verified,
        timestamp: now.subtract(const Duration(minutes: 10)),
        notes: 'Normal gate pass scan',
      ),
      VerificationLog(
        id: 'log-2',
        registrationId: 'reg-beta-456',
        verifiedBy: 'officer-2',
        verifiedByName: 'Selam Library',
        verifiedByRole: 'library_staff',
        method: 'manual_code',
        result: VerificationOutcome.stolen,
        timestamp: now.subtract(const Duration(hours: 3)),
        notes: 'Flagged laptop - security alerted',
      ),
      VerificationLog(
        id: 'log-3',
        registrationId: 'reg-gamma-789',
        verifiedBy: 'officer-1',
        verifiedByName: 'Dawit Security',
        verifiedByRole: 'security_officer',
        method: 'QR',
        result: VerificationOutcome.mismatch,
        timestamp: now.subtract(const Duration(days: 3)),
        notes: 'Serial sticker did not match screen info',
      ),
      VerificationLog(
        id: 'log-4',
        registrationId: 'reg-delta-000',
        verifiedBy: 'officer-3',
        verifiedByName: 'Bekele Gate',
        verifiedByRole: 'security_officer',
        method: 'manual_code',
        result: VerificationOutcome.failed,
        timestamp: now.subtract(const Duration(days: 40)),
        notes: 'Student refused photo verification',
      ),
    ];

    test('Filters logs by search query (registration ID, officer, notes)', () {
      final container = ProviderContainer(
        overrides: [
          allVerificationLogsStreamProvider.overrideWithValue(
            AsyncData(sampleLogs),
          ),
        ],
      );

      final notifier = container.read(verificationFilterProvider.notifier);

      // Search by registration ID
      notifier.setSearchQuery('reg-beta');
      var filtered = container.read(filteredVerificationLogsProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'log-2');

      // Search by officer name
      notifier.setSearchQuery('Dawit');
      filtered = container.read(filteredVerificationLogsProvider).value!;
      expect(filtered.length, 2);

      // Search by notes
      notifier.setSearchQuery('refused photo');
      filtered = container.read(filteredVerificationLogsProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'log-4');
    });

    test('Filters logs by outcome and method', () {
      final container = ProviderContainer(
        overrides: [
          allVerificationLogsStreamProvider.overrideWithValue(
            AsyncData(sampleLogs),
          ),
        ],
      );

      final notifier = container.read(verificationFilterProvider.notifier);

      // Filter by outcome: verified
      notifier.setOutcomeFilter('verified');
      var filtered = container.read(filteredVerificationLogsProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.result, VerificationOutcome.verified);

      // Filter by flagged / stolen
      notifier.setOutcomeFilter('flagged');
      filtered = container.read(filteredVerificationLogsProvider).value!;
      expect(filtered.length, 2); // log-2 (stolen) and log-3 (mismatch)

      // Filter by method: manual_code
      notifier.reset();
      notifier.setMethodFilter('manual_code');
      filtered = container.read(filteredVerificationLogsProvider).value!;
      expect(filtered.length, 2);
      expect(filtered.every((l) => l.isManualCodeMethod), isTrue);
    });

    test('Filters logs by date preset (today, this_week)', () {
      final container = ProviderContainer(
        overrides: [
          allVerificationLogsStreamProvider.overrideWithValue(
            AsyncData(sampleLogs),
          ),
        ],
      );

      final notifier = container.read(verificationFilterProvider.notifier);

      // Filter by today
      notifier.setDateFilter('today');
      var filtered = container.read(filteredVerificationLogsProvider).value!;
      expect(filtered.length, 2); // log-1 (10m ago) and log-2 (3h ago)

      // Filter by this_week
      notifier.setDateFilter('this_week');
      filtered = container.read(filteredVerificationLogsProvider).value!;
      expect(filtered.length, 3); // log-1, log-2, log-3 (within 7 days)
    });
  });
}
