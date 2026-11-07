/// Application route paths and names.
class RoutePaths {
  RoutePaths._();

  // Authentication & Status
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String accountStatus = '/account-status';
  static const String accessDenied = '/access-denied';
  static const String profile = '/profile';

  // Role Dashboards
  static const String adminDashboard = '/admin';
  static const String registrationDashboard = '/registration';
  static const String libraryDashboard = '/library';
  static const String securityDashboard = '/security';

  // Admin Staff Management
  static const String staffList = '/admin/staff';
  static const String createStaff = '/admin/staff/new';
  static const String staffDetail = '/admin/staff/:id';

  // Computer Registration (Phase 3)
  static const String registrationForm = '/registration/new';
  static const String registrationSuccess = '/registration/success';
  static const String registrationList = '/registration/list';
  static const String registrationDetail = '/registration/detail/:id';
}

class RouteNames {
  RouteNames._();

  static const String login = 'login';
  static const String forgotPassword = 'forgot-password';
  static const String accountStatus = 'account-status';
  static const String accessDenied = 'access-denied';
  static const String profile = 'profile';

  static const String adminDashboard = 'admin-dashboard';
  static const String registrationDashboard = 'registration-dashboard';
  static const String libraryDashboard = 'library-dashboard';
  static const String securityDashboard = 'security-dashboard';

  static const String staffList = 'staff-list';
  static const String createStaff = 'create-staff';
  static const String staffDetail = 'staff-detail';

  // Computer Registration (Phase 3)
  static const String registrationForm = 'registration-form';
  static const String registrationSuccess = 'registration-success';
  static const String registrationList = 'registration-list';
  static const String registrationDetail = 'registration-detail';
}
