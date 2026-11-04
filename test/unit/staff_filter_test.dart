import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/features/admin/presentation/controllers/staff_management_controller.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_profile.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_role.dart';

void main() {
  group('StaffFilterNotifier and Filter Logic Tests', () {
    const sampleStaff = [
      StaffProfile(
        uid: 'uid-1',
        name: 'Dawit Abebe',
        email: 'dawit@aau.edu.et',
        role: StaffRole.admin,
        active: true,
      ),
      StaffProfile(
        uid: 'uid-2',
        name: 'Sara Tesfaye',
        email: 'sara@aau.edu.et',
        role: StaffRole.registrationOfficer,
        active: true,
      ),
      StaffProfile(
        uid: 'uid-3',
        name: 'Kebede Michael',
        email: 'kebede@aau.edu.et',
        role: StaffRole.securityOfficer,
        active: false,
      ),
    ];

    test('Filters staff by name search query', () {
      final container = ProviderContainer(
        overrides: [
          allStaffStreamProvider.overrideWithValue(const AsyncData(sampleStaff)),
        ],
      );
      addTearDown(container.dispose);

      container.read(staffFilterProvider.notifier).setSearchQuery('sara');
      final result = container.read(filteredStaffListProvider).value;

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.name, 'Sara Tesfaye');
    });

    test('Filters staff by role', () {
      final container = ProviderContainer(
        overrides: [
          allStaffStreamProvider.overrideWithValue(const AsyncData(sampleStaff)),
        ],
      );
      addTearDown(container.dispose);

      container.read(staffFilterProvider.notifier).setRoleFilter(StaffRole.admin);
      final result = container.read(filteredStaffListProvider).value;

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.role, StaffRole.admin);
    });

    test('Filters staff by active/inactive status', () {
      final container = ProviderContainer(
        overrides: [
          allStaffStreamProvider.overrideWithValue(const AsyncData(sampleStaff)),
        ],
      );
      addTearDown(container.dispose);

      // Inactive only
      container.read(staffFilterProvider.notifier).setStatusFilter(false);
      final inactiveList = container.read(filteredStaffListProvider).value;

      expect(inactiveList, isNotNull);
      expect(inactiveList!.length, 1);
      expect(inactiveList.first.name, 'Kebede Michael');

      // Active only
      container.read(staffFilterProvider.notifier).setStatusFilter(true);
      final activeList = container.read(filteredStaffListProvider).value;

      expect(activeList, isNotNull);
      expect(activeList!.length, 2);
    });
  });
}
