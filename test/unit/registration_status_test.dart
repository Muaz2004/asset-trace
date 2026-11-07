import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';

void main() {
  group('Phase 5 Registration Status & Audit Domain Tests', () {
    test('Correctly identifies active, suspended, and reported_stolen statuses', () {
      const activeReg = Registration(
        id: 'reg-1',
        studentName: 'Abebe Bikila',
        studentId: 'UGR/1234/14',
        phoneNumber: '0911223344',
        pcBrand: 'Dell',
        pcModel: 'Latitude 5420',
        serialNumber: 'DELL1234',
        pcPhotoUrl: 'https://res.cloudinary.com/test/pc.jpg',
        studentWithPcPhotoUrl: 'https://res.cloudinary.com/test/student.jpg',
        status: 'active',
        registeredBy: 'officer-1',
      );

      expect(activeReg.isActive, isTrue);
      expect(activeReg.isSuspended, isFalse);
      expect(activeReg.isReportedStolen, isFalse);
      expect(activeReg.statusDisplayName, 'Active');

      final suspendedReg = activeReg.copyWith(
        status: 'suspended',
        statusReason: 'Under administrative review',
        statusChangedBy: 'admin-1',
        statusChangedByName: 'Administrator',
      );

      expect(suspendedReg.isActive, isFalse);
      expect(suspendedReg.isSuspended, isTrue);
      expect(suspendedReg.isReportedStolen, isFalse);
      expect(suspendedReg.statusDisplayName, 'Suspended');
      expect(suspendedReg.statusReason, 'Under administrative review');
      expect(suspendedReg.statusChangedByName, 'Administrator');

      final stolenReg = activeReg.copyWith(
        status: 'reported_stolen',
        statusReason: 'Reported stolen at Main Library on Nov 7',
        statusChangedBy: 'security-1',
        statusChangedByName: 'Security Lead',
      );

      expect(stolenReg.isActive, isFalse);
      expect(stolenReg.isSuspended, isFalse);
      expect(stolenReg.isReportedStolen, isTrue);
      expect(stolenReg.statusDisplayName, 'Reported Stolen');
    });

    test('Serializes and deserializes status audit metadata with Firestore compatibility', () {
      final now = DateTime(2026, 11, 7, 14, 0);
      final reg = Registration(
        id: 'reg-audit-1',
        studentName: 'Tirunesh Dibaba',
        studentId: 'UGR/5678/14',
        phoneNumber: '0922334455',
        pcBrand: 'HP',
        pcModel: 'EliteBook 840',
        serialNumber: 'HP840XYZ',
        pcPhotoUrl: 'https://res.cloudinary.com/test/pc.jpg',
        studentWithPcPhotoUrl: 'https://res.cloudinary.com/test/student.jpg',
        status: 'suspended',
        registeredBy: 'officer-1',
        registeredByName: 'Officer Dawit',
        statusReason: 'Serial plate inspection required',
        statusChangedBy: 'officer-2',
        statusChangedByName: 'Officer Selam',
        statusChangedAt: now,
        updatedBy: 'admin-1',
        updatedByName: 'Admin User',
        updatedAt: now,
      );

      final map = reg.toFirestore();
      expect(map['status'], 'suspended');
      expect(map['statusReason'], 'Serial plate inspection required');
      expect(map['statusChangedBy'], 'officer-2');
      expect(map['statusChangedByName'], 'Officer Selam');
      expect(map['updatedBy'], 'admin-1');
      expect(map['updatedByName'], 'Admin User');

      // Reconstruct from map
      final reconstructed = Registration.fromMap({
        'studentName': 'Tirunesh Dibaba',
        'studentId': 'UGR/5678/14',
        'phoneNumber': '0922334455',
        'pcBrand': 'HP',
        'pcModel': 'EliteBook 840',
        'serialNumber': 'HP840XYZ',
        'pcPhotoUrl': 'https://res.cloudinary.com/test/pc.jpg',
        'studentWithPcPhotoUrl': 'https://res.cloudinary.com/test/student.jpg',
        'status': 'suspended',
        'registeredBy': 'officer-1',
        'registeredByName': 'Officer Dawit',
        'statusReason': 'Serial plate inspection required',
        'statusChangedBy': 'officer-2',
        'statusChangedByName': 'Officer Selam',
        'statusChangedAt': Timestamp.fromDate(now),
        'updatedBy': 'admin-1',
        'updatedByName': 'Admin User',
        'updatedAt': Timestamp.fromDate(now),
      }, 'reg-audit-1');

      expect(reconstructed.id, 'reg-audit-1');
      expect(reconstructed.isSuspended, isTrue);
      expect(reconstructed.statusReason, 'Serial plate inspection required');
      expect(reconstructed.statusChangedByName, 'Officer Selam');
      expect(reconstructed.updatedByName, 'Admin User');
      expect(reconstructed.statusChangedAt, now);
      expect(reconstructed.updatedAt, now);
    });

    test('Gracefully handles incomplete historical documents lacking Phase 5 fields', () {
      final legacyDoc = Registration.fromMap({
        'studentName': 'Historical Student',
        'studentId': 'UGR/0001/10',
        'phoneNumber': '0911000000',
        'pcBrand': 'Lenovo',
        'pcModel': 'ThinkPad',
        'serialNumber': 'LEGACY1234',
        'pcPhotoUrl': '',
        'studentWithPcPhotoUrl': '',
        'status': 'active',
        'registeredBy': 'old-officer',
      }, 'legacy-doc-1');

      expect(legacyDoc.id, 'legacy-doc-1');
      expect(legacyDoc.isActive, isTrue);
      expect(legacyDoc.isSuspended, isFalse);
      expect(legacyDoc.isReportedStolen, isFalse);
      expect(legacyDoc.statusReason, isNull);
      expect(legacyDoc.statusChangedBy, isNull);
      expect(legacyDoc.updatedBy, isNull);
    });
  });
}
