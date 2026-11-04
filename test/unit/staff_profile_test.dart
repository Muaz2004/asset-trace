import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_profile.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_role.dart';

void main() {
  group('StaffProfile Domain Model Tests', () {
    test('Constructs and converts StaffProfile to/from Map correctly', () {
      final now = DateTime(2026, 11, 4, 10, 0);
      final profile = StaffProfile(
        uid: 'test-uid-123',
        name: 'Dr. Aster Berhe',
        email: 'aster@aau.edu.et',
        role: StaffRole.admin,
        active: true,
        createdAt: now,
      );

      final map = profile.toFirestore();
      expect(map['uid'], 'test-uid-123');
      expect(map['name'], 'Dr. Aster Berhe');
      expect(map['email'], 'aster@aau.edu.et');
      expect(map['role'], 'admin');
      expect(map['active'], isTrue);

      final reconstructed = StaffProfile.fromMap({
        'uid': 'test-uid-123',
        'name': 'Dr. Aster Berhe',
        'email': 'aster@aau.edu.et',
        'role': 'admin',
        'active': true,
        'createdAt': now.toIso8601String(),
      }, 'test-uid-123');

      expect(reconstructed.uid, profile.uid);
      expect(reconstructed.name, profile.name);
      expect(reconstructed.email, profile.email);
      expect(reconstructed.role, profile.role);
      expect(reconstructed.active, profile.active);
    });

    test('Throws FormatException when role in Firestore is invalid', () {
      expect(
        () => StaffProfile.fromMap({
          'name': 'Student Abebe',
          'email': 'abebe@student.aau.edu.et',
          'role': 'student',
          'active': true,
        }, 'invalid-role-uid'),
        throwsFormatException,
      );
    });

    test('copyWith updates fields while preserving unedited attributes', () {
      final profile = StaffProfile(
        uid: 'uid-abc',
        name: 'Tsegaye Gabre-Medhin',
        email: 'tsegaye@aau.edu.et',
        role: StaffRole.libraryStaff,
        active: true,
      );

      final updated = profile.copyWith(active: false, name: 'Tsegaye G.');
      expect(updated.active, isFalse);
      expect(updated.name, 'Tsegaye G.');
      expect(updated.role, StaffRole.libraryStaff);
      expect(updated.uid, 'uid-abc');
    });
  });
}
