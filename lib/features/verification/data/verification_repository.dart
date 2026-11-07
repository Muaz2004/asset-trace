import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../registration/data/registration_repository.dart';
import '../../registration/domain/registration.dart';
import '../domain/verification_log.dart';
import '../domain/verification_outcome.dart';

/// Exception thrown when rate-limiting or anti-abuse protection triggers on manual lookup.
class RateLimitException implements Exception {
  const RateLimitException(this.message, {this.cooldownSeconds = 5});

  final String message;
  final int cooldownSeconds;

  @override
  String toString() => message;
}

/// Repository managing computer ownership lookups, rate limiting, and immutable verification logging.
class VerificationRepository {
  VerificationRepository({
    FirebaseFirestore? firestore,
    RegistrationRepository? registrationRepository,
  })  : _customFirestore = firestore,
        _registrationRepo = registrationRepository ?? RegistrationRepository();

  final FirebaseFirestore? _customFirestore;
  final RegistrationRepository _registrationRepo;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _logsCollection =>
      _firestore.collection(AppConstants.verificationLogsCollection);

  CollectionReference<Map<String, dynamic>> get _registrationsCollection =>
      _firestore.collection(AppConstants.registrationsCollection);

  // Rate-limiting tracking for manual code lookups
  final List<DateTime> _recentLookupAttempts = [];
  int _consecutiveFailures = 0;
  DateTime? _lockoutUntil;

  /// Checks if manual lookup is currently rate-limited.
  int get remainingCooldownSeconds {
    if (_lockoutUntil == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      return 0;
    }
    return _lockoutUntil!.difference(now).inSeconds + 1;
  }

  /// Looks up computer registration by scanned opaque QR identifier.
  Future<Registration?> lookupByQr(String qrIdentifier) async {
    final cleanQr = qrIdentifier.trim();
    if (cleanQr.isEmpty) return null;
    return _registrationRepo.getRegistrationByQr(cleanQr);
  }

  /// Looks up computer registration by 6-digit numeric code with rate limiting and anti-brute-force defense.
  Future<Registration?> lookupByCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanCode)) {
      throw const FormatException('Registration code must consist of exactly 6 numeric digits.');
    }

    // Rate limiting check
    final now = DateTime.now();
    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      final secondsLeft = _lockoutUntil!.difference(now).inSeconds + 1;
      throw RateLimitException(
        'Too many attempts. Please wait $secondsLeft seconds before trying again.',
        cooldownSeconds: secondsLeft,
      );
    }

    // Evict attempts older than 60 seconds
    _recentLookupAttempts.removeWhere(
      (timestamp) => now.difference(timestamp).inSeconds > 60,
    );

    if (_recentLookupAttempts.length >= 8) {
      _lockoutUntil = now.add(const Duration(seconds: 15));
      throw const RateLimitException(
        'Excessive lookup attempts detected. Cooldown activated for 15 seconds.',
        cooldownSeconds: 15,
      );
    }

    _recentLookupAttempts.add(now);

    final registration = await _registrationRepo.getRegistrationByCode(cleanCode);

    if (registration == null) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= 4) {
        _lockoutUntil = now.add(const Duration(seconds: 10));
      }
    } else {
      _consecutiveFailures = 0;
    }

    return registration;
  }

  /// Resets client rate-limiting state (e.g. for testing).
  void resetRateLimiter() {
    _recentLookupAttempts.clear();
    _consecutiveFailures = 0;
    _lockoutUntil = null;
  }

  /// Atomically records an immutable physical ownership verification log in Firestore.
  Future<VerificationLog> recordVerificationAttempt({
    required String registrationId,
    required String verifiedBy,
    String? verifiedByName,
    required String verifiedByRole,
    required String method,
    required VerificationOutcome result,
    String? notes,
  }) async {
    final newDocRef = _logsCollection.doc();
    final now = DateTime.now();

    final logData = {
      'registrationId': registrationId.trim(),
      'verifiedBy': verifiedBy.trim(),
      if (verifiedByName != null) 'verifiedByName': verifiedByName.trim(),
      'verifiedByRole': verifiedByRole.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'method': method.trim(),
      'result': result.value,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    // If computer was flagged as stolen or suspended, also update the master registration status
    if (result == VerificationOutcome.stolen || result == VerificationOutcome.suspended) {
      final newStatus = result == VerificationOutcome.stolen ? 'stolen' : 'suspended';
      final regDocRef = _registrationsCollection.doc(registrationId);

      await _firestore.runTransaction((transaction) async {
        transaction.set(newDocRef, logData);
        transaction.update(regDocRef, {
          'status': newStatus,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
          'lastVerifiedBy': verifiedBy,
        });
      });
    } else {
      await newDocRef.set(logData);
    }

    return VerificationLog(
      id: newDocRef.id,
      registrationId: registrationId,
      verifiedBy: verifiedBy,
      verifiedByName: verifiedByName,
      verifiedByRole: verifiedByRole,
      timestamp: now,
      method: method,
      result: result,
      notes: notes,
    );
  }

  /// Streams recent verification logs ordered by timestamp descending.
  Stream<List<VerificationLog>> watchRecentVerificationLogs({int limit = 15}) {
    return _logsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final logs = <VerificationLog>[];
      for (final doc in snapshot.docs) {
        try {
          logs.add(VerificationLog.fromFirestore(doc));
        } catch (_) {
          // Skip malformed records
        }
      }
      return logs;
    });
  }

  /// Streams all verification logs with an optional limit.
  Stream<List<VerificationLog>> watchAllVerificationLogs({int limit = 100}) {
    return _logsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final logs = <VerificationLog>[];
      for (final doc in snapshot.docs) {
        try {
          logs.add(VerificationLog.fromFirestore(doc));
        } catch (_) {
          // Skip malformed records
        }
      }
      return logs;
    });
  }

  /// Retrieves a single verification log by its document ID.
  Future<VerificationLog?> getVerificationLog(String id) async {
    final doc = await _logsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return VerificationLog.fromFirestore(doc);
  }

  /// Streams verification logs for a specific computer registration.
  Stream<List<VerificationLog>> watchLogsForRegistration(String registrationId) {
    return _logsCollection
        .where('registrationId', isEqualTo: registrationId)
        .snapshots()
        .map((snapshot) {
      final logs = <VerificationLog>[];
      for (final doc in snapshot.docs) {
        try {
          logs.add(VerificationLog.fromFirestore(doc));
        } catch (_) {
          // Skip
        }
      }
      // Sort in memory by timestamp descending
      logs.sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });
      return logs;
    });
  }
}

/// Provider for [VerificationRepository].
final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  final registrationRepo = ref.watch(registrationRepositoryProvider);
  return VerificationRepository(registrationRepository: registrationRepo);
});

/// Stream provider for recent verification logs.
final recentVerificationLogsStreamProvider =
    StreamProvider.autoDispose<List<VerificationLog>>((ref) {
  return ref.watch(verificationRepositoryProvider).watchRecentVerificationLogs();
});

/// Stream provider for all verification logs (up to 100 recent for operational views).
final allVerificationLogsStreamProvider =
    StreamProvider<List<VerificationLog>>((ref) {
  return ref.watch(verificationRepositoryProvider).watchAllVerificationLogs();
});

/// Stream provider for verification logs of a specific registration.
final registrationVerificationLogsStreamProvider =
    StreamProvider.family.autoDispose<List<VerificationLog>, String>((ref, id) {
  return ref.watch(verificationRepositoryProvider).watchLogsForRegistration(id);
});
