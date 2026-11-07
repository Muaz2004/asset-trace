import 'package:cloud_firestore/cloud_firestore.dart';

import 'verification_outcome.dart';

/// Immutable domain model representing a verification attempt recorded in `verification_logs/{logId}`.
class VerificationLog {
  const VerificationLog({
    required this.id,
    required this.registrationId,
    required this.verifiedBy,
    this.verifiedByName,
    required this.verifiedByRole,
    this.timestamp,
    required this.method,
    required this.result,
    this.notes,
  });

  final String id;
  final String registrationId;
  final String verifiedBy;
  final String? verifiedByName;
  final String verifiedByRole;
  final DateTime? timestamp;

  /// Verification method: 'QR' or 'manual_code'
  final String method;

  /// Verification outcome
  final VerificationOutcome result;

  /// Staff verification notes
  final String? notes;

  bool get isQrMethod => method == 'QR';
  bool get isManualCodeMethod => method == 'manual_code';

  /// Deserializes a Firestore map into a [VerificationLog].
  factory VerificationLog.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parsedTimestamp;
    final rawTimestamp = data['timestamp'];
    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp);
    }

    return VerificationLog(
      id: docId,
      registrationId: (data['registrationId'] as String?)?.trim() ?? '',
      verifiedBy: (data['verifiedBy'] as String?)?.trim() ?? '',
      verifiedByName: data['verifiedByName'] as String?,
      verifiedByRole: (data['verifiedByRole'] as String?)?.trim() ?? 'unknown',
      timestamp: parsedTimestamp,
      method: (data['method'] as String?)?.trim() ?? 'QR',
      result: VerificationOutcome.fromString(data['result'] as String?),
      notes: data['notes'] as String?,
    );
  }

  /// Deserializes a Firestore [DocumentSnapshot].
  factory VerificationLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw const FormatException('Verification log document contains no data');
    }
    return VerificationLog.fromMap(data, doc.id);
  }

  /// Serializes the model for Cloud Firestore persistence.
  Map<String, dynamic> toFirestore() {
    return {
      'registrationId': registrationId.trim(),
      'verifiedBy': verifiedBy.trim(),
      if (verifiedByName != null) 'verifiedByName': verifiedByName!.trim(),
      'verifiedByRole': verifiedByRole.trim(),
      if (timestamp != null)
        'timestamp': Timestamp.fromDate(timestamp!)
      else
        'timestamp': FieldValue.serverTimestamp(),
      'method': method.trim(),
      'result': result.value,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerificationLog &&
        other.id == id &&
        other.registrationId == registrationId &&
        other.verifiedBy == verifiedBy &&
        other.verifiedByRole == verifiedByRole &&
        other.timestamp == timestamp &&
        other.method == method &&
        other.result == result &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        registrationId,
        verifiedBy,
        verifiedByRole,
        timestamp,
        method,
        result,
        notes,
      );
}
