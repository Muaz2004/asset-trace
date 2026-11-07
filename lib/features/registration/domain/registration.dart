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
    this.qrIdentifier,
    this.registrationCode,
    this.qrGeneratedAt,
    this.statusReason,
    this.statusChangedBy,
    this.statusChangedByName,
    this.statusChangedAt,
    this.updatedBy,
    this.updatedByName,
    this.updatedAt,
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

  /// Opaque unpredictable token encoded in the QR code (contains zero PII).
  final String? qrIdentifier;

  /// Unique 6-digit numeric registration code (supports leading zeroes, e.g. "048291").
  final String? registrationCode;

  /// Timestamp when the QR credential and 6-digit code were allocated.
  final DateTime? qrGeneratedAt;

  /// Reason recorded when status was changed (suspension or reported stolen).
  final String? statusReason;

  /// Staff UID responsible for the latest status transition.
  final String? statusChangedBy;

  /// Display name of the staff member responsible for the latest status transition.
  final String? statusChangedByName;

  /// Timestamp of the latest status transition.
  final DateTime? statusChangedAt;

  /// Staff UID who last updated registration details.
  final String? updatedBy;

  /// Display name of staff who last updated registration details.
  final String? updatedByName;

  /// Timestamp of last detail update.
  final DateTime? updatedAt;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isSuspended => status.toLowerCase() == 'suspended';
  bool get isReportedStolen =>
      status.toLowerCase() == 'reported_stolen' ||
      status.toLowerCase() == 'stolen';

  String get statusDisplayName {
    if (isActive) return 'Active';
    if (isSuspended) return 'Suspended';
    if (isReportedStolen) return 'Reported Stolen';
    return status;
  }

  bool get hasQrCredentials =>
      qrIdentifier != null &&
      qrIdentifier!.isNotEmpty &&
      registrationCode != null &&
      registrationCode!.isNotEmpty;

  /// Deserializes a Firestore map into a [Registration] object.
  factory Registration.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parsedRegisteredAt;
    final rawRegisteredAt = data['registeredAt'];
    if (rawRegisteredAt is Timestamp) {
      parsedRegisteredAt = rawRegisteredAt.toDate();
    } else if (rawRegisteredAt is String) {
      parsedRegisteredAt = DateTime.tryParse(rawRegisteredAt);
    }

    DateTime? parsedQrGeneratedAt;
    final rawQrGeneratedAt = data['qrGeneratedAt'];
    if (rawQrGeneratedAt is Timestamp) {
      parsedQrGeneratedAt = rawQrGeneratedAt.toDate();
    } else if (rawQrGeneratedAt is String) {
      parsedQrGeneratedAt = DateTime.tryParse(rawQrGeneratedAt);
    }

    DateTime? parsedStatusChangedAt;
    final rawStatusChangedAt = data['statusChangedAt'] ?? data['statusUpdatedAt'];
    if (rawStatusChangedAt is Timestamp) {
      parsedStatusChangedAt = rawStatusChangedAt.toDate();
    } else if (rawStatusChangedAt is String) {
      parsedStatusChangedAt = DateTime.tryParse(rawStatusChangedAt);
    }

    DateTime? parsedUpdatedAt;
    final rawUpdatedAt = data['updatedAt'];
    if (rawUpdatedAt is Timestamp) {
      parsedUpdatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt);
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
      qrIdentifier: (data['qrIdentifier'] as String?)?.trim(),
      registrationCode: (data['registrationCode'] as String?)?.trim(),
      qrGeneratedAt: parsedQrGeneratedAt,
      statusReason: (data['statusReason'] as String?)?.trim(),
      statusChangedBy: (data['statusChangedBy'] as String?)?.trim() ??
          (data['lastVerifiedBy'] as String?)?.trim(),
      statusChangedByName: (data['statusChangedByName'] as String?)?.trim(),
      statusChangedAt: parsedStatusChangedAt,
      updatedBy: (data['updatedBy'] as String?)?.trim(),
      updatedByName: (data['updatedByName'] as String?)?.trim(),
      updatedAt: parsedUpdatedAt,
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
      if (qrIdentifier != null) 'qrIdentifier': qrIdentifier,
      if (registrationCode != null) 'registrationCode': registrationCode,
      if (qrGeneratedAt != null)
        'qrGeneratedAt': Timestamp.fromDate(qrGeneratedAt!),
      if (statusReason != null) 'statusReason': statusReason,
      if (statusChangedBy != null) 'statusChangedBy': statusChangedBy,
      if (statusChangedByName != null)
        'statusChangedByName': statusChangedByName,
      if (statusChangedAt != null)
        'statusChangedAt': Timestamp.fromDate(statusChangedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (updatedByName != null) 'updatedByName': updatedByName,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
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
    String? qrIdentifier,
    String? registrationCode,
    DateTime? qrGeneratedAt,
    String? statusReason,
    String? statusChangedBy,
    String? statusChangedByName,
    DateTime? statusChangedAt,
    String? updatedBy,
    String? updatedByName,
    DateTime? updatedAt,
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
      qrIdentifier: qrIdentifier ?? this.qrIdentifier,
      registrationCode: registrationCode ?? this.registrationCode,
      qrGeneratedAt: qrGeneratedAt ?? this.qrGeneratedAt,
      statusReason: statusReason ?? this.statusReason,
      statusChangedBy: statusChangedBy ?? this.statusChangedBy,
      statusChangedByName: statusChangedByName ?? this.statusChangedByName,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      updatedAt: updatedAt ?? this.updatedAt,
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
        other.registeredAt == registeredAt &&
        other.qrIdentifier == qrIdentifier &&
        other.registrationCode == registrationCode &&
        other.statusReason == statusReason &&
        other.statusChangedBy == statusChangedBy;
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
        qrIdentifier,
        registrationCode,
        statusReason,
        statusChangedBy,
      );
}
