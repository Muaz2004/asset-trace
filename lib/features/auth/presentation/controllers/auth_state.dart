import '../../domain/staff_profile.dart';

/// Enum representing the status of a staff account in the system.
enum AccountStatusType {
  initial,
  unauthenticated,
  authenticated,
  notRegistered,
  deactivated,
  invalidRole,
}

/// Comprehensive state representing the user's authentication and staff profile status.
class AppAuthState {
  const AppAuthState._({
    required this.status,
    this.profile,
    this.errorMessage,
    this.email,
  });

  const AppAuthState.initial()
      : this._(status: AccountStatusType.initial);

  const AppAuthState.unauthenticated()
      : this._(status: AccountStatusType.unauthenticated);

  AppAuthState.authenticated(StaffProfile profile)
      : this._(
          status: AccountStatusType.authenticated,
          profile: profile,
          email: profile.email,
        );

  const AppAuthState.notRegistered({required String email})
      : this._(
          status: AccountStatusType.notRegistered,
          email: email,
          errorMessage:
              'This account is not registered as an authorized university staff member.',
        );

  AppAuthState.deactivated({required StaffProfile profile})
      : this._(
          status: AccountStatusType.deactivated,
          profile: profile,
          email: profile.email,
          errorMessage:
              'This staff account has been deactivated. Please contact an administrator.',
        );

  const AppAuthState.invalidRole({required String email})
      : this._(
          status: AccountStatusType.invalidRole,
          email: email,
          errorMessage:
              'The account role configuration is invalid. Please contact an administrator.',
        );

  final AccountStatusType status;
  final StaffProfile? profile;
  final String? errorMessage;
  final String? email;

  bool get isInitial => status == AccountStatusType.initial;
  bool get isAuthenticated => status == AccountStatusType.authenticated;
  bool get isUnauthenticated => status == AccountStatusType.unauthenticated;
  bool get isNotRegistered => status == AccountStatusType.notRegistered;
  bool get isDeactivated => status == AccountStatusType.deactivated;
  bool get isInvalidRole => status == AccountStatusType.invalidRole;

  bool get hasAccessIssue => isNotRegistered || isDeactivated || isInvalidRole;
}
