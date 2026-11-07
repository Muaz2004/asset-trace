import 'dart:math';

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

/// Repository managing computer registrations in Cloud Firestore with atomic duplicate enforcement
/// and QR credential and 6-digit registration code allocation.
class RegistrationRepository {
  RegistrationRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  static final Random _secureRandom = Random.secure();

  CollectionReference<Map<String, dynamic>> get _registrationsCollection =>
      _firestore.collection(AppConstants.registrationsCollection);

  CollectionReference<Map<String, dynamic>> get _activeSerialsCollection =>
      _firestore.collection(AppConstants.activeSerialsCollection);

  /// Generates an unpredictable, opaque 32-character hexadecimal QR identifier with zero PII.
  static String generateOpaqueQrIdentifier() {
    final values = List<int>.generate(24, (_) => _secureRandom.nextInt(256));
    final hexString = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'aau_qr_$hexString';
  }

  /// Generates a cryptographically random 6-digit numeric registration code supporting leading zeroes.
  static String generateSixDigitCode() {
    final number = _secureRandom.nextInt(1000000);
    return number.toString().padLeft(6, '0');
  }

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
  /// Executes inside a Firestore transaction matching the authorized security rules schema:
  /// 1. Reads active_serials to check uniqueness.
  /// 2. Writes registrations document (with status 'active', registeredBy, and allocated QR/6-digit credentials).
  /// 3. Writes active_serials document satisfying existing getAfter() security requirements.
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

    final allocatedCode = generateSixDigitCode();
    final allocatedQr = generateOpaqueQrIdentifier();
    final now = DateTime.now();

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

      // 2. Prepare registration document data satisfying existing security rules:
      // - registeredBy matches authenticated UID
      // - status is 'active'
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
        'qrIdentifier': allocatedQr,
        'registrationCode': allocatedCode,
        'qrGeneratedAt': FieldValue.serverTimestamp(),
      };

      // 3. Atomically write registration and active serial constraint records
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
      registeredAt: now,
      qrIdentifier: allocatedQr,
      registrationCode: allocatedCode,
      qrGeneratedAt: now,
    );
  }

  /// Allocates QR identifier and 6-digit registration code to an existing registration lacking them.
  Future<Registration> ensureQrCredentials(Registration registration) async {
    if (registration.hasQrCredentials) {
      return registration;
    }

    final allocatedCode = generateSixDigitCode();
    final allocatedQr = generateOpaqueQrIdentifier();
    final now = DateTime.now();

    await _registrationsCollection.doc(registration.id).update({
      'qrIdentifier': allocatedQr,
      'registrationCode': allocatedCode,
      'qrGeneratedAt': FieldValue.serverTimestamp(),
    });

    return registration.copyWith(
      qrIdentifier: allocatedQr,
      registrationCode: allocatedCode,
      qrGeneratedAt: now,
    );
  }

  /// Looks up a registration by its opaque QR identifier directly from the registrations collection.
  Future<Registration?> getRegistrationByQr(String qrIdentifier) async {
    final cleanQr = qrIdentifier.trim();
    if (cleanQr.isEmpty) return null;

    final query = await _registrationsCollection
        .where('qrIdentifier', isEqualTo: cleanQr)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Registration.fromFirestore(query.docs.first);
    }

    return null;
  }

  /// Looks up a registration by its 6-digit registration code directly from the registrations collection.
  Future<Registration?> getRegistrationByCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.length != 6) return null;

    final query = await _registrationsCollection
        .where('registrationCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Registration.fromFirestore(query.docs.first);
    }

    return null;
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

  /// Updates the lifecycle status of a registration (active, suspended, reported_stolen)
  /// with mandatory staff audit attribution and reasoning.
  Future<void> updateRegistrationStatus({
    required String registrationId,
    required String newStatus,
    required String reason,
    required String changedBy,
    String? changedByName,
  }) async {
    final validStatuses = {'active', 'suspended', 'reported_stolen'};
    final normalized = newStatus.trim().toLowerCase();
    if (!validStatuses.contains(normalized)) {
      throw ArgumentError('Invalid registration status: $newStatus');
    }

    final updateData = <String, dynamic>{
      'status': normalized,
      'statusReason': reason.trim(),
      'statusChangedBy': changedBy.trim(),
      if (changedByName != null && changedByName.trim().isNotEmpty)
        'statusChangedByName': changedByName.trim(),
      'statusChangedAt': FieldValue.serverTimestamp(),
    };

    await _registrationsCollection.doc(registrationId).update(updateData);
  }

  /// Updates permitted editable fields of an existing registration with audit tracking.
  Future<void> updateRegistrationDetails({
    required String registrationId,
    required String studentName,
    required String phoneNumber,
    required String pcBrand,
    required String pcModel,
    required String updatedBy,
    String? updatedByName,
  }) async {
    final updateData = <String, dynamic>{
      'studentName': studentName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'pcBrand': pcBrand.trim(),
      'pcModel': pcModel.trim(),
      'updatedBy': updatedBy.trim(),
      if (updatedByName != null && updatedByName.trim().isNotEmpty)
        'updatedByName': updatedByName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _registrationsCollection.doc(registrationId).update(updateData);
  }

  /// Fetches a page of registrations ordered by registeredAt descending for efficient pagination.
  Future<List<Registration>> getRegistrationsPaginated({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
  }) async {
    Query<Map<String, dynamic>> query = _registrationsCollection
        .orderBy('registeredAt', descending: true)
        .limit(limit);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await query.get();
    final list = <Registration>[];
    for (final doc in snapshot.docs) {
      try {
        list.add(Registration.fromFirestore(doc));
      } catch (_) {
        // Skip malformed records
      }
    }
    return list;
  }

  /// Streams all computer registrations ordered by registration date descending.
  Stream<List<Registration>> watchAllRegistrations({int? limit}) {
    Query<Map<String, dynamic>> query =
        _registrationsCollection.orderBy('registeredAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots().map((snapshot) {
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
