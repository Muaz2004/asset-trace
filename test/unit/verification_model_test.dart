import 'package:aau_pc_verify/features/registration/data/registration_repository.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';
import 'package:aau_pc_verify/features/verification/domain/verification_log.dart';
import 'package:aau_pc_verify/features/verification/domain/verification_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4 Identifier Generation Tests', () {
    test('generateOpaqueQrIdentifier produces unpredictable 48-char hex string with prefix and no PII', () {
      final id1 = RegistrationRepository.generateOpaqueQrIdentifier();
      final id2 = RegistrationRepository.generateOpaqueQrIdentifier();

      expect(id1, startsWith('aau_qr_'));
      expect(id2, startsWith('aau_qr_'));
      // Prefix is 7 chars + 48 hex chars = 55 chars
      expect(id1.length, 55);
      expect(id1, isNot(equals(id2)));
      expect(RegExp(r'^aau_qr_[0-9a-f]{48}$').hasMatch(id1), isTrue);
    });

    test('generateSixDigitCode produces valid 6-digit numeric string preserving leading zeroes', () {
      final codes = <String>{};
      for (int i = 0; i < 100; i++) {
        final code = RegistrationRepository.generateSixDigitCode();
        expect(code.length, 6);
        expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
        codes.add(code);
      }
      // Across 100 calls, we should have high variety
      expect(codes.length, greaterThan(80));
    });

    test('Registration domain model preserves QR credentials and dates', () {
      final now = DateTime(2026, 11, 7, 10, 0);
      final reg = Registration(
        id: 'reg_test_001',
        studentName: 'Kebede Michael',
        studentId: 'UGR/1111/14',
        phoneNumber: '0911000000',
        pcBrand: 'HP',
        pcModel: 'EliteBook',
        serialNumber: 'HP123456',
        pcPhotoUrl: 'https://res.cloudinary.com/test/pc.jpg',
        studentWithPcPhotoUrl: 'https://res.cloudinary.com/test/student.jpg',
        registeredBy: 'uid_officer_1',
        qrIdentifier: 'aau_qr_0123456789abcdef0123456789abcdef0123456789abcdef',
        registrationCode: '007891',
        qrGeneratedAt: now,
      );

      expect(reg.hasQrCredentials, isTrue);
      expect(reg.registrationCode, '007891');
      expect(reg.registrationCode!.startsWith('00'), isTrue);

      final map = reg.toFirestore();
      expect(map['qrIdentifier'], 'aau_qr_0123456789abcdef0123456789abcdef0123456789abcdef');
      expect(map['registrationCode'], '007891');

      final reconstructed = Registration.fromMap({
        'studentName': 'Kebede Michael',
        'studentId': 'UGR/1111/14',
        'phoneNumber': '0911000000',
        'pcBrand': 'HP',
        'pcModel': 'EliteBook',
        'serialNumber': 'HP123456',
        'pcPhotoUrl': 'https://res.cloudinary.com/test/pc.jpg',
        'studentWithPcPhotoUrl': 'https://res.cloudinary.com/test/student.jpg',
        'registeredBy': 'uid_officer_1',
        'qrIdentifier': 'aau_qr_0123456789abcdef0123456789abcdef0123456789abcdef',
        'registrationCode': '007891',
        'qrGeneratedAt': now.toIso8601String(),
      }, 'reg_test_001');

      expect(reconstructed.hasQrCredentials, isTrue);
      expect(reconstructed.registrationCode, '007891');
      expect(reconstructed.qrIdentifier, reg.qrIdentifier);
    });
  });

  group('Verification Domain Tests', () {
    test('VerificationOutcome parses known values and defaults to failed for unknown', () {
      expect(VerificationOutcome.fromString('verified'), VerificationOutcome.verified);
      expect(VerificationOutcome.fromString('mismatch'), VerificationOutcome.mismatch);
      expect(VerificationOutcome.fromString('suspended'), VerificationOutcome.suspended);
      expect(VerificationOutcome.fromString('stolen'), VerificationOutcome.stolen);
      expect(VerificationOutcome.fromString('failed'), VerificationOutcome.failed);
      expect(VerificationOutcome.fromString('not_found'), VerificationOutcome.notFound);
      expect(VerificationOutcome.fromString('unknown_status'), VerificationOutcome.failed);
      expect(VerificationOutcome.fromString(null), VerificationOutcome.failed);

      expect(VerificationOutcome.verified.isClearance, isTrue);
      expect(VerificationOutcome.mismatch.isClearance, isFalse);
      expect(VerificationOutcome.stolen.isClearance, isFalse);
    });

    test('VerificationLog serializes and reconstructs correctly', () {
      final now = DateTime(2026, 11, 7, 10, 30);
      const log = VerificationLog(
        id: 'log_abc_123',
        registrationId: 'reg_999',
        verifiedBy: 'officer_uid_55',
        verifiedByName: 'Security Alemu',
        verifiedByRole: 'security_officer',
        timestamp: null,
        method: 'QR',
        result: VerificationOutcome.verified,
        notes: 'Physical check passed at Gate 1.',
      );

      final map = log.toFirestore();
      expect(map['registrationId'], 'reg_999');
      expect(map['verifiedBy'], 'officer_uid_55');
      expect(map['verifiedByName'], 'Security Alemu');
      expect(map['verifiedByRole'], 'security_officer');
      expect(map['method'], 'QR');
      expect(map['result'], 'verified');
      expect(map['notes'], 'Physical check passed at Gate 1.');

      final reconstructed = VerificationLog.fromMap({
        'registrationId': 'reg_999',
        'verifiedBy': 'officer_uid_55',
        'verifiedByName': 'Security Alemu',
        'verifiedByRole': 'security_officer',
        'timestamp': now.toIso8601String(),
        'method': 'QR',
        'result': 'verified',
        'notes': 'Physical check passed at Gate 1.',
      }, 'log_abc_123');

      expect(reconstructed.id, 'log_abc_123');
      expect(reconstructed.result, VerificationOutcome.verified);
      expect(reconstructed.isQrMethod, isTrue);
      expect(reconstructed.isManualCodeMethod, isFalse);
    });
  });
}
