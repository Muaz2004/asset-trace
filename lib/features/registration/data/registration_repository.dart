import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/registration.dart';

/// Exception thrown when attempting to register a computer with an already active serial number.
class DuplicateSerialException implements Exception {
  const DuplicateSerialException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Repository managing computer registrations in Cloud Firestore with atomic duplicate enforcement.
class RegistrationRepository {
  RegistrationRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _registrationsCollection =>
      _firestore.collection(AppConstants.registrationsCollection);

  CollectionReference<Map<String, dynamic>> get _activeSerialsCollection =>
      _firestore.collection(AppConstants.activeSerialsCollection);

  /// Checks if an active computer registration exists for the provided serial number.
  Future<bool> isSerialAlreadyRegistered(String serialNumber) async {
    final normalized = serialNumber.trim().toUpperCase();

    // Check atomic active_serials collection first
    final serialDoc = await _activeSerialsCollection.doc(normalized).get();
    if (serialDoc.exists && (serialDoc.data()?['active'] == true)) {
      return true;
    }

    // Secondary fallback query on registrations collection
    final query = await _registrationsCollection
        .where('serialNumber', isEqualTo: normalized)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Creates a new computer ownership registration.
  ///
  /// Executes inside a Firestore transaction to atomically guarantee that no two
  /// active registrations can be recorded for the same physical computer serial number.
  Future<Registration> createRegistration({
    required String studentName,
    required String studentId,
    required String phoneNumber,
    required String pcBrand,
    required String pcModel,
    required String serialNumber,
    required String pcPhotoUrl,
    required String studentWithPcPhotoUrl,
    required String registeredBy,
    String? registeredByName,
    String? registeredByEmail,
  }) async {
    final normalizedSerial = serialNumber.trim().toUpperCase();
    final normalizedStudentId = studentId.trim().toUpperCase();

    final newDocRef = _registrationsCollection.doc();
    final serialDocRef = _activeSerialsCollection.doc(normalizedSerial);

    await _firestore.runTransaction((transaction) async {
      // 1. Check if the serial number is already actively registered
      final serialSnapshot = await transaction.get(serialDocRef);
      if (serialSnapshot.exists && (serialSnapshot.data()?['active'] == true)) {
        final existingStudent =
            serialSnapshot.data()?['studentId'] ?? 'another student';
        throw DuplicateSerialException(
          'Computer with serial number "$normalizedSerial" is already actively registered (Student ID: $existingStudent). Duplicate registrations are not permitted.',
        );
      }

      // 2. Prepare registration data
      final registrationData = {
        'studentName': studentName.trim(),
        'studentId': normalizedStudentId,
        'phoneNumber': phoneNumber.trim(),
        'pcBrand': pcBrand.trim(),
        'pcModel': pcModel.trim(),
        'serialNumber': normalizedSerial,
        'pcPhotoUrl': pcPhotoUrl,
        'studentWithPcPhotoUrl': studentWithPcPhotoUrl,
        'status': 'active',
        'registeredBy': registeredBy,
        'registeredByName': ?registeredByName,
        'registeredByEmail': ?registeredByEmail,
        'registeredAt': FieldValue.serverTimestamp(),
      };

      // 3. Atomically write registration and serial constraint records
      transaction.set(newDocRef, registrationData);
      transaction.set(serialDocRef, {
        'serialNumber': normalizedSerial,
        'registrationId': newDocRef.id,
        'studentId': normalizedStudentId,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return Registration(
      id: newDocRef.id,
      studentName: studentName.trim(),
      studentId: normalizedStudentId,
      phoneNumber: phoneNumber.trim(),
      pcBrand: pcBrand.trim(),
      pcModel: pcModel.trim(),
      serialNumber: normalizedSerial,
      pcPhotoUrl: pcPhotoUrl,
      studentWithPcPhotoUrl: studentWithPcPhotoUrl,
      status: 'active',
      registeredBy: registeredBy,
      registeredByName: registeredByName,
      registeredByEmail: registeredByEmail,
      registeredAt: DateTime.now(),
    );
  }

  /// Retrieves a single registration by document ID.
  Future<Registration?> getRegistration(String id) async {
    final doc = await _registrationsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return Registration.fromFirestore(doc);
  }

  /// Streams a single registration by document ID in real time.
  Stream<Registration?> watchRegistration(String id) {
    return _registrationsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Registration.fromFirestore(doc);
    });
  }

  /// Streams all computer registrations ordered by registration date descending.
  Stream<List<Registration>> watchAllRegistrations() {
    return _registrationsCollection
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = <Registration>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(Registration.fromFirestore(doc));
        } catch (_) {
          // Skip malformed records
        }
      }
      return list;
    });
  }
}

/// Provider for [RegistrationRepository].
final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository();
});
