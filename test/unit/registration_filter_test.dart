import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/features/registration/domain/registration.dart';
import 'package:aau_pc_verify/features/registration/presentation/controllers/registration_list_controller.dart';

void main() {
  group('RegistrationFilterNotifier and Filter Logic Tests', () {
    final sampleRegistrations = [
      const Registration(
        id: 'reg-1',
        studentName: 'Blen Hailu',
        studentId: 'UGR/1111/14',
        phoneNumber: '0911111111',
        pcBrand: 'Apple',
        pcModel: 'MacBook Air M1',
        serialNumber: 'C02ABC1234',
        pcPhotoUrl: 'https://test/pc1.jpg',
        studentWithPcPhotoUrl: 'https://test/student1.jpg',
        status: 'active',
        registeredBy: 'officer-1',
      ),
      const Registration(
        id: 'reg-2',
        studentName: 'Yared Negash',
        studentId: 'UGR/2222/14',
        phoneNumber: '0922222222',
        pcBrand: 'Dell',
        pcModel: 'Latitude 7490',
        serialNumber: 'DELL7490XYZ',
        pcPhotoUrl: 'https://test/pc2.jpg',
        studentWithPcPhotoUrl: 'https://test/student2.jpg',
        status: 'active',
        registeredBy: 'officer-1',
      ),
      const Registration(
        id: 'reg-3',
        studentName: 'Hiwot Tadesse',
        studentId: 'UGR/3333/15',
        phoneNumber: '0933333333',
        pcBrand: 'HP',
        pcModel: 'ProBook 450 G8',
        serialNumber: 'HP450G8ABC',
        pcPhotoUrl: 'https://test/pc3.jpg',
        studentWithPcPhotoUrl: 'https://test/student3.jpg',
        status: 'inactive',
        registeredBy: 'officer-1',
      ),
    ];

    test('Filters registrations by Student ID query', () {
      final container = ProviderContainer(
        overrides: [
          allRegistrationsStreamProvider
              .overrideWithValue(AsyncData(sampleRegistrations)),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(registrationFilterProvider.notifier)
          .setSearchQuery('2222');
      final result = container.read(filteredRegistrationsProvider).value;

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.studentName, 'Yared Negash');
    });

    test('Filters registrations by Serial Number query', () {
      final container = ProviderContainer(
        overrides: [
          allRegistrationsStreamProvider
              .overrideWithValue(AsyncData(sampleRegistrations)),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(registrationFilterProvider.notifier)
          .setSearchQuery('C02ABC');
      final result = container.read(filteredRegistrationsProvider).value;

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.pcBrand, 'Apple');
    });

    test('Filters registrations by active and inactive status', () {
      final container = ProviderContainer(
        overrides: [
          allRegistrationsStreamProvider
              .overrideWithValue(AsyncData(sampleRegistrations)),
        ],
      );
      addTearDown(container.dispose);

      // Active only
      container
          .read(registrationFilterProvider.notifier)
          .setStatusFilter('active');
      final activeList = container.read(filteredRegistrationsProvider).value;
      expect(activeList!.length, 2);

      // Inactive only
      container
          .read(registrationFilterProvider.notifier)
          .setStatusFilter('inactive');
      final inactiveList = container.read(filteredRegistrationsProvider).value;
      expect(inactiveList!.length, 1);
      expect(inactiveList.first.studentName, 'Hiwot Tadesse');
    });
  });
}
