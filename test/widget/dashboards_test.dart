import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/core/theme/app_theme.dart';
import 'package:aau_pc_verify/features/admin/presentation/controllers/staff_management_controller.dart';
import 'package:aau_pc_verify/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:aau_pc_verify/features/admin/presentation/screens/create_staff_screen.dart';
import 'package:aau_pc_verify/features/admin/presentation/screens/staff_list_screen.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_profile.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_role.dart';
import 'package:aau_pc_verify/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aau_pc_verify/features/auth/presentation/screens/profile_screen.dart';
import 'package:aau_pc_verify/features/dashboards/presentation/screens/library_dashboard_screen.dart';
import 'package:aau_pc_verify/features/dashboards/presentation/screens/registration_dashboard_screen.dart';
import 'package:aau_pc_verify/features/dashboards/presentation/screens/security_dashboard_screen.dart';

void main() {
  const adminProfile = StaffProfile(
    uid: 'admin-uid',
    name: 'Admin User',
    email: 'admin@aau.edu.et',
    role: StaffRole.admin,
    active: true,
  );

  const sampleStaffList = [
    adminProfile,
    StaffProfile(
      uid: 'staff-2',
      name: 'Registration Officer Abebe',
      email: 'abebe@aau.edu.et',
      role: StaffRole.registrationOfficer,
      active: true,
    ),
  ];

  group('Role Dashboard Widget Tests', () {
    testWidgets('AdminDashboardScreen renders overview, management, and operations',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentStaffProfileStreamProvider.overrideWith(
              (ref) => Stream.value(adminProfile),
            ),
            allStaffStreamProvider.overrideWithValue(
              const AsyncData(sampleStaffList),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Administrator Portal'), findsOneWidget);
      expect(find.text('Staff Directory'), findsOneWidget);
      expect(find.text('Add Staff Member'), findsOneWidget);
      expect(find.text('Staff Accounts Summary'), findsOneWidget);
      expect(find.text('2 registered'), findsOneWidget);
    });

    testWidgets('RegistrationDashboardScreen renders portal info without fake buttons',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentStaffProfileStreamProvider.overrideWith(
              (ref) => Stream.value(
                const StaffProfile(
                  uid: 'reg-uid',
                  name: 'Reg Officer',
                  email: 'reg@aau.edu.et',
                  role: StaffRole.registrationOfficer,
                  active: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegistrationDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Registration Portal'), findsOneWidget);
      expect(find.text('Register Student Computer'), findsOneWidget);
      expect(find.text('No Computer Registrations Yet'), findsOneWidget);
    });

    testWidgets('LibraryDashboardScreen renders verification module info',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentStaffProfileStreamProvider.overrideWith(
              (ref) => Stream.value(
                const StaffProfile(
                  uid: 'lib-uid',
                  name: 'Library Staff',
                  email: 'lib@aau.edu.et',
                  role: StaffRole.libraryStaff,
                  active: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LibraryDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Library Verification'), findsAtLeastNWidgets(1));
      expect(find.text('Verify Student PC Ownership'), findsOneWidget);
      expect(find.text('No Verification Logs Recorded'), findsOneWidget);
    });

    testWidgets('SecurityDashboardScreen renders QR scanner and lookup entry points',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentStaffProfileStreamProvider.overrideWith(
              (ref) => Stream.value(
                const StaffProfile(
                  uid: 'sec-uid',
                  name: 'Security Officer',
                  email: 'sec@aau.edu.et',
                  role: StaffRole.securityOfficer,
                  active: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SecurityDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Security Checkpoint'), findsOneWidget);
      expect(find.text('QR Code Scanner'), findsOneWidget);
      expect(find.text('Registration Lookup'), findsOneWidget);
    });

    testWidgets('StaffListScreen displays search and staff cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allStaffStreamProvider.overrideWithValue(
              const AsyncData(sampleStaffList),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StaffListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Staff Directory'), findsOneWidget);
      expect(find.text('New Staff'), findsOneWidget);
      expect(find.text('All Roles'), findsOneWidget);
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('Registration Officer Abebe'), findsOneWidget);
    });

    testWidgets('CreateStaffScreen validates required fields on submission',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateStaffScreen(),
          ),
        ),
      );

      expect(find.text('Provision Staff Account'), findsOneWidget);

      await tester.tap(find.text('Create Staff Account'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Temporary password is required'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders account details and sign out button',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentStaffProfileStreamProvider.overrideWith(
              (ref) => Stream.value(adminProfile),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Staff Account'), findsOneWidget);
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('admin@aau.edu.et'), findsOneWidget);
      expect(find.text('Administrator'), findsAtLeastNWidgets(1));
      expect(find.text('Sign Out of Portal'), findsOneWidget);
    });
  });
}
