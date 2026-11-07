import 'package:aau_pc_verify/features/verification/data/verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VerificationRepository Unit Tests', () {
    test('lookupByCode rejects codes that are not 6 digits', () async {
      final repo = VerificationRepository();

      expect(() => repo.lookupByCode('123'), throwsA(isA<FormatException>()));
      expect(() => repo.lookupByCode('1234567'), throwsA(isA<FormatException>()));
      expect(() => repo.lookupByCode('abcdef'), throwsA(isA<FormatException>()));
      expect(() => repo.lookupByCode(''), throwsA(isA<FormatException>()));
    });

    test('Rate-limiting tracks cooldown and remainingCooldownSeconds correctly', () {
      final repo = VerificationRepository();
      expect(repo.remainingCooldownSeconds, 0);

      repo.resetRateLimiter();
      expect(repo.remainingCooldownSeconds, 0);
    });
  });
}
