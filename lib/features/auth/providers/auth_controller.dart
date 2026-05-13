import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);

      state = const AsyncData(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      state = AsyncError(_readableAuthError(error), stackTrace);
    } catch (error, stackTrace) {
      state = AsyncError('Something went wrong. Please try again.', stackTrace);
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password);

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Account was created, but no user profile was returned.',
        );
      }

      await ref
          .read(userRepositoryProvider)
          .createUserProfile(
            uid: user.uid,
            email: user.email ?? email,
            displayName: email.split('@').first,
          );

      state = const AsyncData(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      state = AsyncError(_readableAuthError(error), stackTrace);
    } catch (error, stackTrace) {
      state = AsyncError('Something went wrong. Please try again.', stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError('Unable to sign out. Please try again.', stackTrace);
    }
  }

  String _readableAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
