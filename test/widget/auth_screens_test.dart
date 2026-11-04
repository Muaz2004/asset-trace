import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aau_pc_verify/core/constants/app_constants.dart';
import 'package:aau_pc_verify/core/theme/app_theme.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_profile.dart';
import 'package:aau_pc_verify/features/auth/domain/staff_role.dart';
import 'package:aau_pc_verify/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aau_pc_verify/features/auth/presentation/controllers/auth_state.dart';
import 'package:aau_pc_verify/features/auth/presentation/screens/access_denied_screen.dart';
import 'package:aau_pc_verify/features/auth/presentation/screens/account_status_screen.dart';
import 'package:aau_pc_verify/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:aau_pc_verify/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('Authentication and Status Widget Tests', () {
    testWidgets('LoginScreen displays fields and triggers validation on empty submit',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      // Verify essential login widgets exist
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.loginSubtitle), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign In to Staff Portal'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);

      // Submit without entering data
      await tester.tap(find.text('Sign In to Staff Portal'));
      await tester.pumpAndSettle();

      // Form validation errors should appear
      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen validates email and displays instructions',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ForgotPasswordScreen(),
          ),
        ),
      );

      expect(find.text('Forgot Your Password?'), findsOneWidget);
      expect(find.text('Send Password Reset Link'), findsOneWidget);

      // Tap submit with empty email
      await tester.tap(find.text('Send Password Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Email address is required'), findsOneWidget);
    });

    testWidgets('AccountStatusScreen renders not registered warning', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appAuthStateProvider.overrideWithValue(
              const AppAuthState.notRegistered(email: 'unregistered@student.aau.edu.et'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AccountStatusScreen(),
          ),
        ),
      );

      expect(find.text('Not Registered as Staff'), findsOneWidget);
      expect(find.text('unregistered@student.aau.edu.et'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('AccountStatusScreen renders deactivated account warning', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appAuthStateProvider.overrideWithValue(
              AppAuthState.deactivated(
                profile: const StaffProfile(
                  uid: 'deactivated-uid',
                  name: 'Inactive Staff',
                  email: 'inactive@aau.edu.et',
                  role: StaffRole.securityOfficer,
                  active: false,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AccountStatusScreen(),
          ),
        ),
      );

      expect(find.text('Account Deactivated'), findsOneWidget);
      expect(find.text('inactive@aau.edu.et'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('AccessDeniedScreen renders unauthorized warning and return button',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AccessDeniedScreen(),
          ),
        ),
      );

      expect(find.text('Unauthorized Area'), findsOneWidget);
      expect(find.text('Return to My Dashboard'), findsOneWidget);
    });
  });
}
