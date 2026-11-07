import 'package:cloud_firestore/cloud_firestore.dart';

import 'staff_role.dart';

/// Represents a staff member's university profile stored in Firestore.
class StaffProfile {
  const StaffProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final StaffRole role;
  final bool active;
  final DateTime? createdAt;

  /// Whether this profile is a System Administrator.
  bool get isAdmin => role == StaffRole.admin;

  /// Creates a [StaffProfile] from Firestore document data.
  factory StaffProfile.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    final roleString = data['role'] as String?;
    final role = StaffRole.fromString(roleString);

    if (role == null) {
      throw FormatException('Invalid or unrecognized staff role: $roleString');
    }

    return StaffProfile(
      uid: docId,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim().toLowerCase() ?? '',
      role: role,
      active: (data['active'] as bool?) ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  /// Creates a [StaffProfile] from a Firestore [DocumentSnapshot].
  factory StaffProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw const FormatException('Staff document contains no data');
    }
    return StaffProfile.fromMap(data, doc.id);
  }

  /// Converts the profile to Firestore map representation.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'role': role.value,
      'active': active,
      if (createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!)
      else
        'createdAt': FieldValue.serverTimestamp(),
    };
  }

  StaffProfile copyWith({
    String? uid,
    String? name,
    String? email,
    StaffRole? role,
    bool? active,
    DateTime? createdAt,
  }) {
    return StaffProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StaffProfile &&
        other.uid == uid &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.active == active &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(uid, name, email, role, active, createdAt);
}
