import 'package:flutter/material.dart';

/// Staff roles recognized by the application.
enum StaffRole {
  admin('admin', 'Administrator'),
  registrationOfficer('registration_officer', 'Registration Officer'),
  libraryStaff('library_staff', 'Library Staff'),
  securityOfficer('security_officer', 'Security Officer');

  const StaffRole(this.value, this.displayName);

  /// Raw string stored in Firestore.
  final String value;

  /// User-facing display title.
  final String displayName;

  /// Parses a role string from Firestore. Returns null if invalid or unrecognized.
  static StaffRole? fromString(String? roleString) {
    if (roleString == null) return null;
    for (final role in StaffRole.values) {
      if (role.value == roleString || role.name == roleString) {
        return role;
      }
    }
    return null;
  }

  /// Whether this role can access administration functionality.
  bool get canAccessAdmin => this == StaffRole.admin;

  /// Whether this role can access computer registration.
  bool get canAccessRegistration =>
      this == StaffRole.admin || this == StaffRole.registrationOfficer;

  /// Whether this role can access library verification.
  bool get canAccessLibrary =>
      this == StaffRole.admin || this == StaffRole.libraryStaff;

  /// Whether this role can access security checkpoint verification.
  bool get canAccessSecurity =>
      this == StaffRole.admin || this == StaffRole.securityOfficer;

  /// Role icon for UI display.
  IconData get icon {
    switch (this) {
      case StaffRole.admin:
        return Icons.admin_panel_settings_rounded;
      case StaffRole.registrationOfficer:
        return Icons.app_registration_rounded;
      case StaffRole.libraryStaff:
        return Icons.local_library_rounded;
      case StaffRole.securityOfficer:
        return Icons.security_rounded;
    }
  }
}
