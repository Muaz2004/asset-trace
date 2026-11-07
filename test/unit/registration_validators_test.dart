import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/core/utils/validators.dart';

void main() {
  group('Registration Field Validators Tests', () {
    test('Validates university student IDs', () {
      expect(Validators.validateStudentId('UGR/1234/14'), isNull);
      expect(Validators.validateStudentId('GSE/5678/15'), isNull);
      expect(Validators.validateStudentId('ETS-0123-12'), isNull);
      expect(Validators.validateStudentId('R/1234/13'), isNull);

      expect(Validators.validateStudentId(''), 'Student ID is required');
      expect(Validators.validateStudentId('   '), 'Student ID is required');
      expect(Validators.validateStudentId(null), 'Student ID is required');
      expect(Validators.validateStudentId('U1'), 'Enter a valid student ID (e.g., UGR/1234/14)');
    });

    test('Validates Ethiopian phone numbers', () {
      expect(Validators.validatePhoneNumber('0911223344'), isNull);
      expect(Validators.validatePhoneNumber('0711223344'), isNull);
      expect(Validators.validatePhoneNumber('+251911223344'), isNull);
      expect(Validators.validatePhoneNumber('0911 22 33 44'), isNull);

      expect(Validators.validatePhoneNumber(''), 'Phone number is required');
      expect(Validators.validatePhoneNumber('091122'), 'Enter a valid Ethiopian phone number (e.g., 0911223344 or +251911223344)');
      expect(Validators.validatePhoneNumber('1234567890'), 'Enter a valid Ethiopian phone number (e.g., 0911223344 or +251911223344)');
    });

    test('Validates hardware serial numbers', () {
      expect(Validators.validateSerialNumber('5CD2341ABC'), isNull);
      expect(Validators.validateSerialNumber('PF-1234-XYZ'), isNull);
      expect(Validators.validateSerialNumber('C02D1234MD6R'), isNull);

      expect(Validators.validateSerialNumber(''), 'Serial number is required');
      expect(Validators.validateSerialNumber(null), 'Serial number is required');
      expect(Validators.validateSerialNumber('ABC'), 'Enter a valid serial number (min 4 alphanumeric characters)');
    });

    test('Validates computer brand and model', () {
      expect(Validators.validatePcBrand('Lenovo'), isNull);
      expect(Validators.validatePcBrand('HP'), isNull);
      expect(Validators.validatePcBrand(''), 'Computer brand is required');
      expect(Validators.validatePcBrand('A'), 'Brand must be at least 2 characters');

      expect(Validators.validatePcModel('ThinkPad T14'), isNull);
      expect(Validators.validatePcModel(''), 'Computer model is required');
      expect(Validators.validatePcModel('X'), 'Model must be at least 2 characters');
    });

    test('Validates student name', () {
      expect(Validators.validateStudentName('Tadesse Gemeda'), isNull);
      expect(Validators.validateStudentName(''), 'Student full name is required');
      expect(Validators.validateStudentName('T'), 'Enter at least first and last name (3+ characters)');
    });
  });
}
