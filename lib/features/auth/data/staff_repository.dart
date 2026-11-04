import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../firebase_options.dart';
import '../domain/staff_profile.dart';
import '../domain/staff_role.dart';

/// Repository managing staff profile data in Cloud Firestore.
class StaffRepository {
  StaffRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _staffCollection =>
      _firestore.collection(AppConstants.staffCollection);

  /// Retrieves a staff profile by user UID.
  Future<StaffProfile?> getStaffProfile(String uid) async {
    final doc = await _staffCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return StaffProfile.fromFirestore(doc);
  }

  /// Streams a single staff profile in real time.
  Stream<StaffProfile?> watchStaffProfile(String uid) {
    return _staffCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return StaffProfile.fromFirestore(doc);
    });
  }

  /// Streams all staff members in real time, ordered by creation date descending.
  Stream<List<StaffProfile>> watchAllStaff() {
    return _staffCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = <StaffProfile>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(StaffProfile.fromFirestore(doc));
        } catch (_) {
          // If a document has an invalid format, skip or log gracefully
        }
      }
      return list;
    });
  }

  /// Retrieves all staff members as a one-time future.
  Future<List<StaffProfile>> getAllStaff() async {
    final snapshot =
        await _staffCollection.orderBy('createdAt', descending: true).get();
    final list = <StaffProfile>[];
    for (final doc in snapshot.docs) {
      try {
        list.add(StaffProfile.fromFirestore(doc));
      } catch (_) {
        // Skip malformed records
      }
    }
    return list;
  }

  /// Creates a new staff member account.
  ///
  /// Uses an isolated secondary [FirebaseApp] instance to create the Firebase
  /// Auth user so that the administrator's current authenticated session
  /// is never replaced or invalidated.
  Future<StaffProfile> createStaffAccount({
    required String name,
    required String email,
    required StaffRole role,
    required String temporaryPassword,
  }) async {
    final secondaryAppName =
        'StaffCreationApp_${DateTime.now().millisecondsSinceEpoch}';

    final secondaryApp = await Firebase.initializeApp(
      name: secondaryAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: temporaryPassword,
      );

      final newUid = userCredential.user?.uid;
      if (newUid == null) {
        throw Exception('Failed to obtain UID for newly created staff user');
      }

      final profile = StaffProfile(
        uid: newUid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: role,
        active: true,
        createdAt: DateTime.now(),
      );

      // Write staff profile document into primary Firestore
      await _staffCollection.doc(newUid).set(profile.toFirestore());

      await secondaryAuth.signOut();
      return profile;
    } finally {
      await secondaryApp.delete();
    }
  }

  /// Updates a staff member's basic information.
  Future<void> updateStaffProfile(String uid, {required String name}) async {
    await _staffCollection.doc(uid).update({
      'name': name.trim(),
    });
  }

  /// Updates a staff member's assigned role.
  Future<void> updateStaffRole(String uid, StaffRole newRole) async {
    await _staffCollection.doc(uid).update({
      'role': newRole.value,
    });
  }

  /// Activates or deactivates a staff member account.
  Future<void> setStaffActiveStatus(String uid, bool active) async {
    await _staffCollection.doc(uid).update({
      'active': active,
    });
  }
}

/// Provider for [StaffRepository].
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository();
});
