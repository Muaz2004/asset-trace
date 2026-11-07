import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/core/theme/app_theme.dart';
import 'package:aau_pc_verify/features/admin/presentation/controllers/staff_activity_controller.dart';
import 'package:aau_pc_verify/features/admin/presentation/screens/staff_activity_screen.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_profile.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_role.dart';
import 'package:aau_pc_verify/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aau_pc_verify/features/auth/presentation/controllers/auth_state.dart';
import 'package:aau_pc_verify/features/registration/data/registration_repository.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';
import 'package:aau_pc_verify/features/registration/presentation/screens/edit_registration_screen.dart';
import 'package:aau_pc_verify/features/verification/data/verification_repository.dart';
import 'package:aau_pc_verify/features/verification/domain/verification_log.dart';
import 'package:aau_pc_verify/features/verification/domain/verification_outcome.dart';
import 'package:aau_pc_verify/features/verification/presentation/screens/verification_history_screen.dart';

void main() {
  const sampleProfile = StaffProfile(
    uid: 'admin-1',
    name: 'Admin User',
    email: 'admin@aau.edu.et',
    role: StaffRole.admin,
    active: true,
  );

  group('Phase 5 Screens Widget Tests', () {
    testWidgets('VerificationHistoryScreen renders filter bar and log cards',
        (tester) async {
      final sampleLog = VerificationLog(
        id: 'test-log-1',
        registrationId: 'reg-abc-123',
        verifiedBy: 'officer-1',
        verifiedByName: 'Dawit Officer',
        verifiedByRole: 'security_officer',
        method: 'QR',
        result: VerificationOutcome.verified,
        timestamp: DateTime(2026, 11, 7, 10, 30),
        notes: 'Gate 2 standard check',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allVerificationLogsStreamProvider.overrideWith(
              (ref) => Stream.value([sampleLog]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VerificationHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Verification History'), findsOneWidget);
      expect(find.text('Outcome: '), findsOneWidget);
      expect(find.text('All Methods'), findsOneWidget);
      expect(find.text('Ownership Verified'), findsOneWidget);
      expect(find.text('Reg ID: reg-abc-123'), findsOneWidget);
    });

    testWidgets('StaffActivityScreen renders operational overview and member cards',
        (tester) async {
      const summary = StaffActivitySummary(
        profile: sampleProfile,
        registrationCount: 15,
        activeRegistrationCount: 12,
        verificationCount: 42,
        verifiedCount: 40,
        flaggedCount: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffActivityListProvider.overrideWithValue(
              const AsyncData([summary]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StaffActivityScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Staff Activity & Accountability'), findsOneWidget);
      expect(find.text('Operational Accountability Overview'), findsOneWidget);
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('15'), findsWidgets);
      expect(find.text('42'), findsWidgets);
    });

    testWidgets('EditRegistrationScreen renders editable fields with initial values',
        (tester) async {
      final sampleRegistration = Registration(
        id: 'reg-edit-1',
        studentName: 'Marta Hailu',
        studentId: 'UGR/7890/14',
        phoneNumber: '0911334455',
        pcBrand: 'Dell',
        pcModel: 'Latitude 5420',
        serialNumber: 'DELL5420SN',
        pcPhotoUrl: '',
        studentWithPcPhotoUrl: '',
        status: 'active',
        registeredBy: 'admin-1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appAuthStateProvider.overrideWith(
              (ref) => AppAuthState.authenticated(sampleProfile),
            ),
            registrationRepositoryProvider.overrideWithValue(
              _MockRegistrationRepository(sampleRegistration),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditRegistrationScreen(registrationId: sampleRegistration.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Registration Details'), findsOneWidget);
      expect(find.text('Student Information'), findsOneWidget);
      expect(find.text('Computer Specifications'), findsOneWidget);
    });
  });
}

class _MockRegistrationRepository extends RegistrationRepository {
  _MockRegistrationRepository(this._sample);

  final Registration _sample;

  @override
  Stream<Registration?> watchRegistration(String id) {
    return Stream.value(_sample);
  }
}
