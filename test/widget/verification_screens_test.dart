import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/core/theme/app_theme.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_profile.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_role.dart';
import 'package:aau_pc_verify/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aau_pc_verify/features/auth/presentation/controllers/auth_state.dart';
import 'package:aau_pc_verify/features/registration/data/registration_repository.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';
import 'package:aau_pc_verify/features/verification/presentation/screens/manual_lookup_screen.dart';
import 'package:aau_pc_verify/features/verification/presentation/screens/ownership_verification_screen.dart';

void main() {
  const sampleProfile = StaffProfile(
    uid: 'security_officer_1',
    name: 'Officer Lemma',
    email: 'lemma@aau.edu.et',
    role: StaffRole.securityOfficer,
    active: true,
  );

  const sampleRegistration = Registration(
    id: 'reg_verify_001',
    studentName: 'Birtukan Mideksa',
    studentId: 'UGR/5555/14',
    phoneNumber: '0912345678',
    pcBrand: 'Dell',
    pcModel: 'XPS 13',
    serialNumber: 'DELL-XPS-9988',
    pcPhotoUrl: '',
    studentWithPcPhotoUrl: '',
    status: 'active',
    registeredBy: 'reg_officer_1',
    registrationCode: '123456',
    qrIdentifier: 'aau_qr_test_token',
  );

  group('Verification Screens Widget Tests', () {
    testWidgets('ManualLookupScreen renders 6-digit inputs and buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ManualLookupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manual Code Lookup'), findsOneWidget);
      expect(find.text('Enter 6-Digit Registration Code'), findsOneWidget);
      expect(find.text('Verify Computer Ownership'), findsOneWidget);
      expect(find.text('Scan QR Code with Camera'), findsOneWidget);

      // Enter digits into the hidden text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, '048291');
      await tester.pumpAndSettle();

      // Check that digit '0' and '4' appear in the boxes
      expect(find.text('0'), findsWidgets);
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('OwnershipVerificationScreen displays student, PC details, and outcomes',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appAuthStateProvider.overrideWith(
              (ref) => AppAuthState.authenticated(sampleProfile),
            ),
            registrationRepositoryProvider.overrideWithValue(
              _MockVerificationRegRepo(sampleRegistration),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const OwnershipVerificationScreen(
              registrationId: 'reg_verify_001',
              verificationMethod: 'manual_code',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Physical PC Inspection'), findsOneWidget);
      expect(find.text('REGISTERED STUDENT'), findsOneWidget);
      expect(find.text('Birtukan Mideksa'), findsOneWidget);
      expect(find.text('UGR/5555/14'), findsOneWidget);
      expect(find.text('REGISTERED COMPUTER'), findsOneWidget);
      expect(find.text('Dell XPS 13'), findsOneWidget);
      expect(find.text('Serial: DELL-XPS-9988'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(find.text('Physical Verification Outcome'), findsOneWidget);
      expect(find.text('Ownership Verified'), findsOneWidget);
      expect(find.text('Information Mismatch'), findsOneWidget);
      expect(find.text('Record Ownership Verified'), findsOneWidget);
    });
  });
}

class _MockVerificationRegRepo extends RegistrationRepository {
  _MockVerificationRegRepo(this._reg);

  final Registration _reg;

  @override
  Stream<Registration?> watchRegistration(String id) {
    return Stream.value(_reg);
  }
}
