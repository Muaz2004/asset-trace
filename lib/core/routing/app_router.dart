import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/create_staff_screen.dart';
import '../../features/admin/presentation/screens/staff_activity_screen.dart';
import '../../features/admin/presentation/screens/staff_detail_screen.dart';
import '../../features/admin/presentation/screens/staff_list_screen.dart';
import '../../features/auth/domain/staff_role.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/access_denied_screen.dart';
import '../../features/auth/presentation/screens/account_status_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/dashboards/presentation/screens/library_dashboard_screen.dart';
import '../../features/dashboards/presentation/screens/registration_dashboard_screen.dart';
import '../../features/dashboards/presentation/screens/security_dashboard_screen.dart';
import '../../features/registration/presentation/screens/edit_registration_screen.dart';
import '../../features/registration/presentation/screens/registration_detail_screen.dart';
import '../../features/registration/presentation/screens/registration_form_screen.dart';
import '../../features/registration/presentation/screens/registration_list_screen.dart';
import '../../features/registration/presentation/screens/registration_search_screen.dart';
import '../../features/registration/presentation/screens/registration_success_screen.dart';
import '../../features/verification/presentation/screens/manual_lookup_screen.dart';
import '../../features/verification/presentation/screens/ownership_verification_screen.dart';
import '../../features/verification/presentation/screens/qr_scanner_screen.dart';
import '../../features/verification/presentation/screens/verification_detail_screen.dart';
import '../../features/verification/presentation/screens/verification_history_screen.dart';
import 'route_paths.dart';


/// Listenable that triggers GoRouter redirect re-evaluation whenever auth state changes.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Ref ref) {
    ref.listen(appAuthStateProvider, (_, _) {
      notifyListeners();
    });
  }
}

final authRefreshNotifierProvider = Provider<AuthRefreshNotifier>((ref) {
  return AuthRefreshNotifier(ref);
});

/// Riverpod provider exposing the application's GoRouter instance with protected routes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(authRefreshNotifierProvider);

  return GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = ref.read(appAuthStateProvider);
      final path = state.matchedLocation;

      // Allow loading phase to settle
      if (authState.isInitial) {
        return null;
      }

      // 1. Unauthenticated users can only access login and password recovery
      if (authState.isUnauthenticated) {
        if (path == RoutePaths.login || path == RoutePaths.forgotPassword) {
          return null;
        }
        return RoutePaths.login;
      }

      // 2. Authenticated users with invalid/inactive/unregistered staff profiles
      if (authState.hasAccessIssue) {
        if (path == RoutePaths.accountStatus) {
          return null;
        }
        return RoutePaths.accountStatus;
      }

      // 3. Fully authenticated staff members with active profiles
      if (authState.isAuthenticated) {
        final role = authState.profile!.role;

        // If on auth or status screens, redirect to their role dashboard
        if (path == RoutePaths.login ||
            path == RoutePaths.forgotPassword ||
            path == RoutePaths.accountStatus) {
          switch (role) {
            case StaffRole.admin:
              return RoutePaths.adminDashboard;
            case StaffRole.registrationOfficer:
              return RoutePaths.registrationDashboard;
            case StaffRole.libraryStaff:
              return RoutePaths.libraryDashboard;
            case StaffRole.securityOfficer:
              return RoutePaths.securityDashboard;
          }
        }

        // Role-based route guard enforcement
        if (path.startsWith('/admin') && !role.canAccessAdmin) {
          return RoutePaths.accessDenied;
        }

        if (path.startsWith('/registration') && !role.canAccessRegistration) {
          return RoutePaths.accessDenied;
        }

        if (path.startsWith('/library') && !role.canAccessLibrary) {
          return RoutePaths.accessDenied;
        }

        if (path.startsWith('/security') && !role.canAccessSecurity) {
          return RoutePaths.accessDenied;
        }

        if (path.startsWith('/verification') && !role.canAccessVerification) {
          return RoutePaths.accessDenied;
        }

        // Profile and access denied routes are accessible to all authenticated staff
        return null;
      }

      return null;
    },
    routes: [
      // Authentication
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.accountStatus,
        name: RouteNames.accountStatus,
        builder: (context, state) => const AccountStatusScreen(),
      ),
      GoRoute(
        path: RoutePaths.accessDenied,
        name: RouteNames.accessDenied,
        builder: (context, state) => const AccessDeniedScreen(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Role Dashboards
      GoRoute(
        path: RoutePaths.adminDashboard,
        name: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.registrationDashboard,
        name: RouteNames.registrationDashboard,
        builder: (context, state) => const RegistrationDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.libraryDashboard,
        name: RouteNames.libraryDashboard,
        builder: (context, state) => const LibraryDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.securityDashboard,
        name: RouteNames.securityDashboard,
        builder: (context, state) => const SecurityDashboardScreen(),
      ),

      // Computer Registration (Phase 3)
      GoRoute(
        path: RoutePaths.registrationForm,
        name: RouteNames.registrationForm,
        builder: (context, state) => const RegistrationFormScreen(),
      ),
      GoRoute(
        path: RoutePaths.registrationSuccess,
        name: RouteNames.registrationSuccess,
        builder: (context, state) => const RegistrationSuccessScreen(),
      ),
      GoRoute(
        path: RoutePaths.registrationList,
        name: RouteNames.registrationList,
        builder: (context, state) => const RegistrationListScreen(),
      ),
      GoRoute(
        path: RoutePaths.registrationSearch,
        name: RouteNames.registrationSearch,
        builder: (context, state) => const RegistrationSearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.registrationDetail,
        name: RouteNames.registrationDetail,
        builder: (context, state) {
          final registrationId = state.pathParameters['id'] ?? '';
          return RegistrationDetailScreen(registrationId: registrationId);
        },
      ),
      GoRoute(
        path: RoutePaths.editRegistration,
        name: RouteNames.editRegistration,
        builder: (context, state) {
          final registrationId = state.pathParameters['id'] ?? '';
          return EditRegistrationScreen(registrationId: registrationId);
        },
      ),

      // Computer Ownership Verification (Phase 4 & 5)
      GoRoute(
        path: RoutePaths.qrScanner,
        name: RouteNames.qrScanner,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: RoutePaths.manualLookup,
        name: RouteNames.manualLookup,
        builder: (context, state) => const ManualLookupScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownershipVerification,
        name: RouteNames.ownershipVerification,
        builder: (context, state) {
          final registrationId = state.pathParameters['id'] ?? '';
          final method = state.uri.queryParameters['method'] ?? 'QR';
          return OwnershipVerificationScreen(
            registrationId: registrationId,
            verificationMethod: method,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.verificationHistory,
        name: RouteNames.verificationHistory,
        builder: (context, state) => const VerificationHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.verificationDetail,
        name: RouteNames.verificationDetail,
        builder: (context, state) {
          final logId = state.pathParameters['id'] ?? '';
          return VerificationDetailScreen(logId: logId);
        },
      ),

      // Administrator Staff Management & Activity
      GoRoute(
        path: RoutePaths.staffList,
        name: RouteNames.staffList,
        builder: (context, state) => const StaffListScreen(),
      ),
      GoRoute(
        path: RoutePaths.createStaff,
        name: RouteNames.createStaff,
        builder: (context, state) => const CreateStaffScreen(),
      ),
      GoRoute(
        path: RoutePaths.staffDetail,
        name: RouteNames.staffDetail,
        builder: (context, state) {
          final staffId = state.pathParameters['id'] ?? '';
          return StaffDetailScreen(staffId: staffId);
        },
      ),
      GoRoute(
        path: RoutePaths.staffActivity,
        name: RouteNames.staffActivity,
        builder: (context, state) => const StaffActivityScreen(),
      ),
    ],
  );
});
