import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/core/theme/app_theme.dart';
import 'package:aau_pc_verify/features/registration/data/registration_repository.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';
import 'package:aau_pc_verify/features/registration/presentation/controllers/registration_controller.dart';
import 'package:aau_pc_verify/features/registration/presentation/controllers/registration_list_controller.dart';
import 'package:aau_pc_verify/features/registration/presentation/screens/registration_detail_screen.dart';
import 'package:aau_pc_verify/features/registration/presentation/screens/registration_form_screen.dart';
import 'package:aau_pc_verify/features/registration/presentation/screens/registration_list_screen.dart';
import 'package:aau_pc_verify/features/registration/presentation/screens/registration_success_screen.dart';

void main() {
  const sampleRegistration = Registration(
    id: 'test-reg-id-999',
    studentName: 'Tigist Assefa',
    studentId: 'UGR/7777/14',
    phoneNumber: '0911556677',
    pcBrand: 'Lenovo',
    pcModel: 'IdeaPad 3',
    serialNumber: 'LENOVO123XYZ',
    pcPhotoUrl: 'https://test.com/pc.jpg',
    studentWithPcPhotoUrl: 'https://test.com/student.jpg',
    status: 'active',
    registeredBy: 'officer-test-uid',
    registeredByName: 'Officer Dawit',
    registeredByEmail: 'dawit@aau.edu.et',
  );

  group('Registration Screens Widget Tests', () {
    testWidgets('RegistrationFormScreen validates student step on empty continue',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegistrationFormScreen(),
          ),
        ),
      );

      expect(find.text('Computer Registration'), findsOneWidget);
      expect(find.text('Student Information'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Continue on empty form
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Form validation errors should trigger
      expect(find.text('Student full name is required'), findsOneWidget);
      expect(find.text('Student ID is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
    });

    testWidgets('RegistrationSuccessScreen displays registration reference and details',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationControllerProvider.overrideWith(
              () => _MockSuccessRegistrationController(sampleRegistration),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegistrationSuccessScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Registration Successful'), findsOneWidget);
      expect(find.text('test-reg-id-999'), findsOneWidget);
      expect(find.text('Tigist Assefa (UGR/7777/14)'), findsOneWidget);
      expect(find.text('Lenovo IdeaPad 3'), findsOneWidget);
      expect(find.text('Register Another Computer'), findsOneWidget);
    });

    testWidgets('RegistrationListScreen displays search bar and registration records',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRegistrationsStreamProvider.overrideWithValue(
              const AsyncData([sampleRegistration]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegistrationListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Registration Records'), findsOneWidget);
      expect(find.text('Register PC'), findsOneWidget);
      expect(find.text('Tigist Assefa'), findsOneWidget);
      expect(find.text('UGR/7777/14'), findsOneWidget);
      expect(find.text('Lenovo IdeaPad 3'), findsOneWidget);
    });

    testWidgets('RegistrationDetailScreen displays verified ownership details',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationRepositoryProvider.overrideWithValue(
              _MockRegistrationRepository(sampleRegistration),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegistrationDetailScreen(
              registrationId: 'test-reg-id-999',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Registration Details'), findsOneWidget);
      expect(find.text('Tigist Assefa'), findsOneWidget);
      expect(find.text('Hardware Specifications'), findsOneWidget);
      expect(find.text('Audit & Registration Metadata'), findsOneWidget);
      expect(find.text('Verification Photographs'), findsOneWidget);
      expect(find.text('LENOVO123XYZ'), findsOneWidget);
    });
  });
}

class _MockSuccessRegistrationController extends RegistrationController {
  _MockSuccessRegistrationController(this._registration);

  final Registration _registration;

  @override
  RegistrationFormState build() {
    return RegistrationFormState(
      createdRegistration: _registration,
    );
  }
}

class _MockRegistrationRepository extends RegistrationRepository {
  _MockRegistrationRepository(this._sample);

  final Registration _sample;

  @override
  Stream<Registration?> watchRegistration(String id) {
    return Stream.value(_sample);
  }
}
