import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';
import 'package:aau_pc_verify/features/registration/presentation/controllers/registration_list_controller.dart';
import 'package:aau_pc_verify/features/registration/data/registration_repository.dart';

// Mock repository for testing search state notifier
class MockSearchRegistrationRepository extends RegistrationRepository {
  MockSearchRegistrationRepository({
    this.searchResults = const [],
    this.shouldThrow = false,
  }) : super();

  final List<Registration> searchResults;
  final bool shouldThrow;

  @override
  Future<List<Registration>> searchRegistrations(String rawQuery, {int limit = 20}) async {
    if (shouldThrow) {
      throw Exception('Search service unavailable');
    }
    return searchResults;
  }
}

void main() {
  group('Registration Archiving & Search Unit Tests', () {
    final sampleDate = DateTime(2026, 11, 7, 10, 0);

    test('Registration model correctly handles archived status and audit fields', () {
      final archivedReg = Registration(
        id: 'reg-archived-1',
        studentName: 'Abebe Bikila',
        studentId: 'UGR/1234/14',
        phoneNumber: '0911223344',
        pcBrand: 'Dell',
        pcModel: 'Latitude 5420',
        serialNumber: 'DELL-12345',
        pcPhotoUrl: 'https://res.cloudinary.com/dummy/pc.jpg',
        studentWithPcPhotoUrl: 'https://res.cloudinary.com/dummy/student.jpg',
        status: 'archived',
        statusReason: 'Student graduated and returned official PC registration',
        registeredBy: 'officer-1',
        registeredByName: 'Officer Dawit',
        archivedBy: 'admin-1',
        archivedByName: 'Admin Tigist',
        archivedAt: sampleDate,
      );

      expect(archivedReg.isArchived, isTrue);
      expect(archivedReg.isActive, isFalse);
      expect(archivedReg.statusDisplayName, 'Archived');
      expect(archivedReg.archivedByName, 'Admin Tigist');

      final map = archivedReg.toFirestore();
      expect(map['status'], 'archived');
      expect(map['archivedBy'], 'admin-1');
      expect(map['archivedByName'], 'Admin Tigist');

      final reconstructed = Registration.fromMap({
        'studentName': 'Abebe Bikila',
        'studentId': 'UGR/1234/14',
        'phoneNumber': '0911223344',
        'pcBrand': 'Dell',
        'pcModel': 'Latitude 5420',
        'serialNumber': 'DELL-12345',
        'pcPhotoUrl': 'https://res.cloudinary.com/dummy/pc.jpg',
        'studentWithPcPhotoUrl': 'https://res.cloudinary.com/dummy/student.jpg',
        'status': 'archived',
        'statusReason': 'Student graduated and returned official PC registration',
        'registeredBy': 'officer-1',
        'registeredByName': 'Officer Dawit',
        'archivedBy': 'admin-1',
        'archivedByName': 'Admin Tigist',
        'archivedAt': sampleDate.toIso8601String(),
      }, 'reg-archived-1');

      expect(reconstructed.isArchived, isTrue);
      expect(reconstructed.archivedByName, 'Admin Tigist');
      expect(reconstructed.statusReason, contains('Student graduated'));
    });

    test('RegistrationSearchState correctly reports empty and success states', () {
      const initialState = RegistrationSearchState();
      expect(initialState.isLoading, isFalse);
      expect(initialState.hasSearched, isFalse);
      expect(initialState.isEmptyResult, isFalse);
      expect(initialState.hasResults, isFalse);
      expect(initialState.hasError, isFalse);

      const emptySearchedState = RegistrationSearchState(
        query: 'NONEXISTENT',
        hasSearched: true,
        results: [],
      );
      expect(emptySearchedState.isEmptyResult, isTrue);
      expect(emptySearchedState.hasResults, isFalse);

      final sampleReg = Registration(
        id: 'reg-1',
        studentName: 'Sara Connor',
        studentId: 'UGR/9999/14',
        phoneNumber: '0922334455',
        pcBrand: 'HP',
        pcModel: 'EliteBook',
        serialNumber: 'HP-SN-001',
        pcPhotoUrl: '',
        studentWithPcPhotoUrl: '',
        registeredBy: 'off-1',
      );

      final withResultsState = RegistrationSearchState(
        query: 'Sara',
        hasSearched: true,
        results: [sampleReg],
      );
      expect(withResultsState.hasResults, isTrue);
      expect(withResultsState.isEmptyResult, isFalse);
      expect(withResultsState.results.length, 1);
    });

    test('RegistrationSearchNotifier transitions through search, success, error, and clear', () async {
      final sampleReg = Registration(
        id: 'reg-recovered-1',
        studentName: 'Dawit Tsige',
        studentId: 'UGR/7777/14',
        phoneNumber: '0911778899',
        pcBrand: 'Apple',
        pcModel: 'MacBook Air M2',
        serialNumber: 'C02ABC123XYZ',
        pcPhotoUrl: '',
        studentWithPcPhotoUrl: '',
        registeredBy: 'off-1',
        registrationCode: '789123',
        qrIdentifier: 'AAU-PC-789123',
      );

      final mockRepo = MockSearchRegistrationRepository(searchResults: [sampleReg]);
      final container = ProviderContainer(
        overrides: [
          registrationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(registrationSearchControllerProvider.notifier);

      // Verify Initial State
      expect(container.read(registrationSearchControllerProvider).hasSearched, isFalse);

      // Blank search is ignored
      await notifier.search('   ');
      expect(container.read(registrationSearchControllerProvider).hasSearched, isFalse);

      // Execute valid search
      await notifier.search('Dawit');
      final searchState = container.read(registrationSearchControllerProvider);
      expect(searchState.isLoading, isFalse);
      expect(searchState.hasSearched, isTrue);
      expect(searchState.hasResults, isTrue);
      expect(searchState.results.first.registrationCode, '789123');

      // Clear search
      notifier.clear();
      final clearedState = container.read(registrationSearchControllerProvider);
      expect(clearedState.hasSearched, isFalse);
      expect(clearedState.query, '');
      expect(clearedState.results, isEmpty);
    });

    test('RegistrationSearchNotifier handles error and retry', () async {
      final mockRepo = MockSearchRegistrationRepository(shouldThrow: true);
      final container = ProviderContainer(
        overrides: [
          registrationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(registrationSearchControllerProvider.notifier);
      await notifier.search('error_query');

      final errorState = container.read(registrationSearchControllerProvider);
      expect(errorState.isLoading, isFalse);
      expect(errorState.hasError, isTrue);
      expect(errorState.error, contains('Search service unavailable'));
    });
  });
}
