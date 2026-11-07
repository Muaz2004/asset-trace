import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';

void main() {
  group('Registration Domain Model Tests', () {
    test('Constructs, normalizes, and serializes Registration to/from Map', () {
      final now = DateTime(2026, 11, 4, 12, 30);
      final reg = Registration(
        id: 'reg-doc-123',
        studentName: 'Aster Aweke',
        studentId: 'ugr/4567/14',
        phoneNumber: '0911002233',
        pcBrand: 'Lenovo',
        pcModel: 'ThinkPad T14',
        serialNumber: 'pf1234abc',
        pcPhotoUrl: 'https://storage.googleapis.com/test-bucket/pc.jpg',
        studentWithPcPhotoUrl:
            'https://storage.googleapis.com/test-bucket/student.jpg',
        status: 'active',
        registeredBy: 'officer-uid-789',
        registeredByName: 'Officer Dawit',
        registeredByEmail: 'dawit@aau.edu.et',
        registeredAt: now,
      );

      final firestoreMap = reg.toFirestore();
      expect(firestoreMap['studentName'], 'Aster Aweke');
      expect(firestoreMap['studentId'], 'UGR/4567/14'); // Normalized to uppercase
      expect(firestoreMap['serialNumber'], 'PF1234ABC'); // Normalized to uppercase
      expect(firestoreMap['status'], 'active');
      expect(firestoreMap['pcPhotoUrl'], 'https://storage.googleapis.com/test-bucket/pc.jpg');
      expect(firestoreMap['registeredByName'], 'Officer Dawit');

      final reconstructed = Registration.fromMap({
        'studentName': 'Aster Aweke',
        'studentId': 'ugr/4567/14',
        'phoneNumber': '0911002233',
        'pcBrand': 'Lenovo',
        'pcModel': 'ThinkPad T14',
        'serialNumber': 'pf1234abc',
        'pcPhotoUrl': 'https://storage.googleapis.com/test-bucket/pc.jpg',
        'studentWithPcPhotoUrl':
            'https://storage.googleapis.com/test-bucket/student.jpg',
        'status': 'active',
        'registeredBy': 'officer-uid-789',
        'registeredByName': 'Officer Dawit',
        'registeredByEmail': 'dawit@aau.edu.et',
        'registeredAt': now.toIso8601String(),
      }, 'reg-doc-123');

      expect(reconstructed.id, 'reg-doc-123');
      expect(reconstructed.studentId, 'UGR/4567/14');
      expect(reconstructed.serialNumber, 'PF1234ABC');
      expect(reconstructed.isActive, isTrue);
    });

    test('copyWith preserves unchanged attributes while updating fields', () {
      final reg = Registration(
        id: 'reg-1',
        studentName: 'Mulugeta Tesfaye',
        studentId: 'UGR/9999/15',
        phoneNumber: '0922334455',
        pcBrand: 'Dell',
        pcModel: 'Latitude 5420',
        serialNumber: 'DELL5420XYZ',
        pcPhotoUrl: 'https://test/pc.jpg',
        studentWithPcPhotoUrl: 'https://test/student.jpg',
        registeredBy: 'officer-1',
      );

      final updated = reg.copyWith(status: 'inactive');
      expect(updated.status, 'inactive');
      expect(updated.isActive, isFalse);
      expect(updated.studentName, 'Mulugeta Tesfaye');
      expect(updated.serialNumber, 'DELL5420XYZ');
    });
  });
}
