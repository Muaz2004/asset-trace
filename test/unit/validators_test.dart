import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/core/utils/validators.dart';

void main() {
  group('Validators Utility Tests', () {
    test('Email validator accepts valid emails and rejects malformed inputs', () {
      expect(Validators.validateEmail('staff@aau.edu.et'), isNull);
      expect(Validators.validateEmail('admin.user@aau.edu.et'), isNull);

      expect(Validators.validateEmail(''), 'Email address is required');
      expect(Validators.validateEmail('   '), 'Email address is required');
      expect(Validators.validateEmail(null), 'Email address is required');
      expect(Validators.validateEmail('not-an-email'), 'Enter a valid email address');
      expect(Validators.validateEmail('missing@domain'), 'Enter a valid email address');
    });

    test('Password validator requires at least 6 characters', () {
      expect(Validators.validatePassword('secret123'), isNull);
      expect(Validators.validatePassword('123456'), isNull);

      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters');
    });

    test('Name validator requires at least 2 characters', () {
      expect(Validators.validateName('Abebe Bikila'), isNull);
      expect(Validators.validateName('Li'), isNull);

      expect(Validators.validateName(''), 'Full name is required');
      expect(Validators.validateName(null), 'Full name is required');
      expect(Validators.validateName('A'), 'Name must be at least 2 characters');
    });
  });
}
