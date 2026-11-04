import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/staff_repository.dart';
import '../../domain/staff_profile.dart';
import 'auth_state.dart';

/// Stream provider that watches the current staff member's Firestore profile.
final currentStaffProfileStreamProvider =
    StreamProvider.autoDispose<StaffProfile?>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) {
    return Stream.value(null);
  }
  final staffRepository = ref.watch(staffRepositoryProvider);
  return staffRepository.watchStaffProfile(authUser.uid);
});

/// Core provider computing the full [AppAuthState] by combining
/// Firebase Auth state and Firestore staff profile state.
final appAuthStateProvider = Provider<AppAuthState>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);

  return authAsync.when(
    data: (user) {
      if (user == null) {
        return const AppAuthState.unauthenticated();
      }

      final profileAsync = ref.watch(currentStaffProfileStreamProvider);

      return profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return AppAuthState.notRegistered(
              email: user.email ?? 'Unknown Email',
            );
          }
          if (!profile.active) {
            return AppAuthState.deactivated(profile: profile);
          }
          return AppAuthState.authenticated(profile);
        },
        loading: () => const AppAuthState.initial(),
        error: (error, _) {
          if (error is FormatException) {
            return AppAuthState.invalidRole(
              email: user.email ?? 'Unknown Email',
            );
          }
          return AppAuthState.notRegistered(
            email: user.email ?? 'Unknown Email',
          );
        },
      );
    },
    loading: () => const AppAuthState.initial(),
    error: (error, stack) => const AppAuthState.unauthenticated(),
  );
});

/// Async state for authentication UI operations (login, reset password, logout).
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Attempts to sign in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Sends a password recovery email.
  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetEmail(email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Signs out the current staff member.
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider for [AuthController].
final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(
  AuthController.new,
);
