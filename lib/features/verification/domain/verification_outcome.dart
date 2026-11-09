import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Outcomes produced by physical computer ownership verification.
enum VerificationOutcome {
  verified(
    'verified',
    'Ownership Verified',
    'Student identity and computer ownership match registered university records.',
  ),
  mismatch(
    'mismatch',
    'Information Mismatch',
    'Physical serial, model, or student physical presence does not match registered details.',
  ),
  notFound(
    'not_found',
    'Registration Not Found',
    'No valid registration record found matching the presented QR code or 6-digit code.',
  ),
  suspended(
    'suspended',
    'Registration Suspended',
    'Registration record has been temporarily suspended due to administrative review or flag.',
  ),
  stolen(
    'stolen',
    'Computer Reported Stolen',
    'This computer is flagged as stolen in the university campus security registry.',
  ),
  failed(
    'failed',
    'Verification Failed',
    'Verification could not be confirmed due to damaged labels, refusal of inspection, or other issues.',
  );

  const VerificationOutcome(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  /// Parses a verification outcome string stored in Firestore.
  static VerificationOutcome fromString(String? outcomeString) {
    if (outcomeString == null) return VerificationOutcome.failed;
    final normalized = outcomeString.trim().toLowerCase();
    for (final outcome in VerificationOutcome.values) {
      if (outcome.value == normalized || outcome.name.toLowerCase() == normalized) {
        return outcome;
      }
    }
    return VerificationOutcome.failed;
  }

  /// Color associated with outcome status for badges and indicators.
  Color get color {
    switch (this) {
      case VerificationOutcome.verified:
        return AppTheme.aauGold;
      case VerificationOutcome.mismatch:
        return AppTheme.aauGoldLight;
      case VerificationOutcome.notFound:
        return AppTheme.textSecondary;
      case VerificationOutcome.suspended:
        return AppTheme.aauGoldDark;
      case VerificationOutcome.stolen:
        return AppTheme.statusWarning;
      case VerificationOutcome.failed:
        return AppTheme.statusWarning;
    }
  }

  /// Icon associated with outcome status.
  IconData get icon {
    switch (this) {
      case VerificationOutcome.verified:
        return Icons.check_circle_rounded;
      case VerificationOutcome.mismatch:
        return Icons.warning_amber_rounded;
      case VerificationOutcome.notFound:
        return Icons.search_off_rounded;
      case VerificationOutcome.suspended:
        return Icons.pause_circle_filled_rounded;
      case VerificationOutcome.stolen:
        return Icons.gavel_rounded;
      case VerificationOutcome.failed:
        return Icons.cancel_rounded;
    }
  }

  /// Whether this outcome represents a positive security clearance.
  bool get isClearance => this == VerificationOutcome.verified;
}
