import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable domain model representing a student computer ownership registration.
class Registration {
  const Registration({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.phoneNumber,
    required this.pcBrand,
    required this.pcModel,
    required this.serialNumber,
    required this.pcPhotoUrl,
    required this.studentWithPcPhotoUrl,
    this.status = 'active',
    required this.registeredBy,
    this.registeredByName,
    this.registeredByEmail,
    this.registeredAt,
  });

  final String id;
  final String studentName;
  final String studentId;
  final String phoneNumber;
  final String pcBrand;
  final String pcModel;
  final String serialNumber;
  final String pcPhotoUrl;
  final String studentWithPcPhotoUrl;
  final String status;
  final String registeredBy;
  final String? registeredByName;
  final String? registeredByEmail;
  final DateTime? registeredAt;

  bool get isActive => status.toLowerCase() == 'active';

  /// Deserializes a Firestore map into a [Registration] object.
  factory Registration.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parsedRegisteredAt;
    final rawRegisteredAt = data['registeredAt'];
    if (rawRegisteredAt is Timestamp) {
      parsedRegisteredAt = rawRegisteredAt.toDate();
    } else if (rawRegisteredAt is String) {
      parsedRegisteredAt = DateTime.tryParse(rawRegisteredAt);
    }

    return Registration(
      id: docId,
      studentName: (data['studentName'] as String?)?.trim() ?? '',
      studentId: (data['studentId'] as String?)?.trim().toUpperCase() ?? '',
      phoneNumber: (data['phoneNumber'] as String?)?.trim() ?? '',
      pcBrand: (data['pcBrand'] as String?)?.trim() ?? '',
      pcModel: (data['pcModel'] as String?)?.trim() ?? '',
      serialNumber: (data['serialNumber'] as String?)?.trim().toUpperCase() ?? '',
      pcPhotoUrl: data['pcPhotoUrl'] as String? ?? '',
      studentWithPcPhotoUrl: data['studentWithPcPhotoUrl'] as String? ?? '',
      status: (data['status'] as String?)?.trim().toLowerCase() ?? 'active',
      registeredBy: data['registeredBy'] as String? ?? '',
      registeredByName: data['registeredByName'] as String?,
      registeredByEmail: data['registeredByEmail'] as String?,
      registeredAt: parsedRegisteredAt,
    );
  }

  /// Deserializes a Firestore [DocumentSnapshot].
  factory Registration.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw const FormatException('Registration document contains no data');
    }
    return Registration.fromMap(data, doc.id);
  }

  /// Serializes the model for Cloud Firestore persistence.
  Map<String, dynamic> toFirestore() {
    return {
      'studentName': studentName.trim(),
      'studentId': studentId.trim().toUpperCase(),
      'phoneNumber': phoneNumber.trim(),
      'pcBrand': pcBrand.trim(),
      'pcModel': pcModel.trim(),
      'serialNumber': serialNumber.trim().toUpperCase(),
      'pcPhotoUrl': pcPhotoUrl,
      'studentWithPcPhotoUrl': studentWithPcPhotoUrl,
      'status': status.toLowerCase(),
      'registeredBy': registeredBy,
      if (registeredByName != null) 'registeredByName': registeredByName,
      if (registeredByEmail != null) 'registeredByEmail': registeredByEmail,
      if (registeredAt != null)
        'registeredAt': Timestamp.fromDate(registeredAt!)
      else
        'registeredAt': FieldValue.serverTimestamp(),
    };
  }

  Registration copyWith({
    String? id,
    String? studentName,
    String? studentId,
    String? phoneNumber,
    String? pcBrand,
    String? pcModel,
    String? serialNumber,
    String? pcPhotoUrl,
    String? studentWithPcPhotoUrl,
    String? status,
    String? registeredBy,
    String? registeredByName,
    String? registeredByEmail,
    DateTime? registeredAt,
  }) {
    return Registration(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pcBrand: pcBrand ?? this.pcBrand,
      pcModel: pcModel ?? this.pcModel,
      serialNumber: serialNumber ?? this.serialNumber,
      pcPhotoUrl: pcPhotoUrl ?? this.pcPhotoUrl,
      studentWithPcPhotoUrl: studentWithPcPhotoUrl ?? this.studentWithPcPhotoUrl,
      status: status ?? this.status,
      registeredBy: registeredBy ?? this.registeredBy,
      registeredByName: registeredByName ?? this.registeredByName,
      registeredByEmail: registeredByEmail ?? this.registeredByEmail,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Registration &&
        other.id == id &&
        other.studentName == studentName &&
        other.studentId == studentId &&
        other.phoneNumber == phoneNumber &&
        other.pcBrand == pcBrand &&
        other.pcModel == pcModel &&
        other.serialNumber == serialNumber &&
        other.pcPhotoUrl == pcPhotoUrl &&
        other.studentWithPcPhotoUrl == studentWithPcPhotoUrl &&
        other.status == status &&
        other.registeredBy == registeredBy &&
        other.registeredAt == registeredAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        studentName,
        studentId,
        phoneNumber,
        pcBrand,
        pcModel,
        serialNumber,
        pcPhotoUrl,
        studentWithPcPhotoUrl,
        status,
        registeredBy,
        registeredAt,
      );
}
