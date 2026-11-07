import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aau_pc_verify/features/admin/presentation/controllers/staff_activity_controller.dart';
import 'package:aau_pc_verify/features/admin/presentation/controllers/staff_management_controller.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_profile.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_role.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';
import 'package:aau_pc_verify/features/registration/presentation/controllers/registration_list_controller.dart';
import 'package:aau_pc_verify/features/verification/data/verification_repository.dart';
import 'package:aau_pc_verify/features/verification/domain/verification_log.dart';
import 'package:aau_pc_verify/features/verification/domain/verification_outcome.dart';

void main() {
  group('Staff Activity & Operational Statistics Tests', () {
    const staff1 = StaffProfile(
      uid: 'staff-reg-1',
      name: 'Abebe Registration',
      email: 'abebe@aau.edu.et',
      role: StaffRole.registrationOfficer,
      active: true,
    );

    const staff2 = StaffProfile(
      uid: 'staff-sec-2',
      name: 'Dawit Security',
      email: 'dawit@aau.edu.et',
      role: StaffRole.securityOfficer,
      active: true,
    );

    final sampleStaff = [staff1, staff2];

    final sampleRegistrations = [
      const Registration(
        id: 'reg-1',
        studentName: 'Student 1',
        studentId: 'UGR/001/14',
        phoneNumber: '0911000000',
        pcBrand: 'Dell',
        pcModel: 'Latitude',
        serialNumber: 'SN001',
        pcPhotoUrl: '',
        studentWithPcPhotoUrl: '',
        status: 'active',
        registeredBy: 'staff-reg-1',
      ),
      const Registration(
        id: 'reg-2',
        studentName: 'Student 2',
        studentId: 'UGR/002/14',
        phoneNumber: '0911000001',
        pcBrand: 'HP',
        pcModel: 'ProBook',
        serialNumber: 'SN002',
        pcPhotoUrl: '',
        studentWithPcPhotoUrl: '',
        status: 'suspended',
        registeredBy: 'staff-reg-1',
      ),
    ];

    final sampleLogs = [
      const VerificationLog(
        id: 'log-1',
        registrationId: 'reg-1',
        verifiedBy: 'staff-sec-2',
        verifiedByRole: 'security_officer',
        method: 'QR',
        result: VerificationOutcome.verified,
      ),
      const VerificationLog(
        id: 'log-2',
        registrationId: 'reg-2',
        verifiedBy: 'staff-sec-2',
        verifiedByRole: 'security_officer',
        method: 'manual_code',
        result: VerificationOutcome.stolen,
      ),
      const VerificationLog(
        id: 'log-3',
        registrationId: 'reg-1',
        verifiedBy: 'staff-sec-2',
        verifiedByRole: 'security_officer',
        method: 'QR',
        result: VerificationOutcome.verified,
      ),
    ];

    test('Computes registration and verification metrics per staff member correctly', () {
      final container = ProviderContainer(
        overrides: [
          allStaffStreamProvider.overrideWithValue(
            AsyncData(sampleStaff),
          ),
          allRegistrationsStreamProvider.overrideWithValue(
            AsyncData(sampleRegistrations),
          ),
          allVerificationLogsStreamProvider.overrideWithValue(
            AsyncData(sampleLogs),
          ),
        ],
      );

      final activityList = container.read(staffActivityListProvider).value!;
      expect(activityList.length, 2);

      // staff2 has 3 verifications + 0 registrations = totalActivity 3
      // staff1 has 2 registrations + 0 verifications = totalActivity 2
      // List should be sorted descending by totalActivity: staff2 first
      expect(activityList[0].profile.uid, 'staff-sec-2');
      expect(activityList[0].verificationCount, 3);
      expect(activityList[0].verifiedCount, 2);
      expect(activityList[0].flaggedCount, 1);
      expect(activityList[0].registrationCount, 0);

      expect(activityList[1].profile.uid, 'staff-reg-1');
      expect(activityList[1].registrationCount, 2);
      expect(activityList[1].activeRegistrationCount, 1);
      expect(activityList[1].verificationCount, 0);
    });
  });
}
