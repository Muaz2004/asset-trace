import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_role.dart';

void main() {
  group('StaffRole Enum Tests', () {
    test('Correctly parses all valid role strings', () {
      expect(StaffRole.fromString('admin'), StaffRole.admin);
      expect(
        StaffRole.fromString('registration_officer'),
        StaffRole.registrationOfficer,
      );
      expect(StaffRole.fromString('library_staff'), StaffRole.libraryStaff);
      expect(StaffRole.fromString('security_officer'), StaffRole.securityOfficer);
    });

    test('Returns null for invalid or unrecognized role strings', () {
      expect(StaffRole.fromString('student'), isNull);
      expect(StaffRole.fromString(''), isNull);
      expect(StaffRole.fromString(null), isNull);
      expect(StaffRole.fromString('unknown_role'), isNull);
    });

    test('Verifies role-based access permissions', () {
      // Administrator has access to all operational domains
      expect(StaffRole.admin.canAccessAdmin, isTrue);
      expect(StaffRole.admin.canAccessRegistration, isTrue);
      expect(StaffRole.admin.canAccessLibrary, isTrue);
      expect(StaffRole.admin.canAccessSecurity, isTrue);

      // Registration Officer can access only registration
      expect(StaffRole.registrationOfficer.canAccessAdmin, isFalse);
      expect(StaffRole.registrationOfficer.canAccessRegistration, isTrue);
      expect(StaffRole.registrationOfficer.canAccessLibrary, isFalse);
      expect(StaffRole.registrationOfficer.canAccessSecurity, isFalse);

      // Library Staff can access only library
      expect(StaffRole.libraryStaff.canAccessAdmin, isFalse);
      expect(StaffRole.libraryStaff.canAccessRegistration, isFalse);
      expect(StaffRole.libraryStaff.canAccessLibrary, isTrue);
      expect(StaffRole.libraryStaff.canAccessSecurity, isFalse);

      // Security Officer can access only security
      expect(StaffRole.securityOfficer.canAccessAdmin, isFalse);
      expect(StaffRole.securityOfficer.canAccessRegistration, isFalse);
      expect(StaffRole.securityOfficer.canAccessLibrary, isFalse);
      expect(StaffRole.securityOfficer.canAccessSecurity, isTrue);
    });
  });
}
