import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/core/theme/app_theme.dart';
import 'package:aau_pc_verify/features/registration/data/registration_repository.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';
import 'package:aau_pc_verify/features/registration/presentation/screens/registration_search_screen.dart';

class _FakeSearchRepo extends RegistrationRepository {
  _FakeSearchRepo(this.results) : super();

  final List<Registration> results;

  @override
  Future<List<Registration>> searchRegistrations(String rawQuery, {int limit = 20}) async {
    if (rawQuery.contains('nonexistent')) {
      return [];
    }
    return results;
  }
}

void main() {
  final sampleReg = Registration(
    id: 'reg-recovered-123',
    studentName: 'Bethlehem Tadesse',
    studentId: 'UGR/5544/14',
    phoneNumber: '0911223344',
    pcBrand: 'HP',
    pcModel: 'Pavilion 15',
    serialNumber: 'HP-SN-5544-XYZ',
    pcPhotoUrl: '',
    studentWithPcPhotoUrl: '',
    status: 'active',
    registeredBy: 'off-1',
    registrationCode: '998877',
    qrIdentifier: 'AAU-PC-998877',
  );

  group('RegistrationSearchScreen Widget Tests', () {
    testWidgets('Renders search input and tip chips in initial state', (tester) async {
      final fakeRepo = _FakeSearchRepo([sampleReg]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegistrationSearchScreen(),
          ),
        ),
      );

      expect(find.text('Search & Credential Recovery'), findsOneWidget);
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('Student Credential Recovery'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Student Full Name'), findsOneWidget);
    });

    testWidgets('Displays search results and credentials upon query submission', (tester) async {
      final fakeRepo = _FakeSearchRepo([sampleReg]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegistrationSearchScreen(),
          ),
        ),
      );

      final searchBar = find.byType(SearchBar);
      await tester.enterText(searchBar, 'Bethlehem');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Bethlehem Tadesse'), findsOneWidget);
      expect(find.textContaining('UGR/5544/14'), findsOneWidget);
      expect(find.textContaining('0911223344'), findsOneWidget);
      expect(find.textContaining('HP-SN-5544-XYZ'), findsOneWidget);
      expect(find.textContaining('998877'), findsOneWidget);
      expect(find.text('View Credentials →'), findsOneWidget);
    });

    testWidgets('Displays no-results empty state when no record matches', (tester) async {
      final fakeRepo = _FakeSearchRepo([sampleReg]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegistrationSearchScreen(),
          ),
        ),
      );

      final searchBar = find.byType(SearchBar);
      await tester.enterText(searchBar, 'nonexistent');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('No Registrations Found'), findsOneWidget);
      expect(find.textContaining('No computer registrations match "nonexistent"'), findsOneWidget);
    });
  });
}
