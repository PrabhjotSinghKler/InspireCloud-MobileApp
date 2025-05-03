import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email & password
  // In auth_service.dart
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        print('AuthService: Sign in successful for ${user.email}');
        return user;
      } else {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'No user returned from sign-in',
        );
      }
    } catch (e, stackTrace) {
      print('AuthService sign in error: $e');
      rethrow;
    }
  }

  // Register with email & password
  // In auth_service.dart
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Check specifically for reCAPTCHA-related errors
      if (e is FirebaseAuthException) {
        if (e.code == 'recaptcha-error' ||
            e.message?.contains('RECAPTCHA') == true ||
            e.message?.contains('recaptcha') == true ||
            e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
          // Log the specific error for debugging
          // print('Firebase reCAPTCHA error: ${e.message}');

          // Provide a more user-friendly error message
          throw Exception(
            'Registration temporarily unavailable. Please try again later or contact support.',
          );
        }
      }
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Error handling helper
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return Exception('The email address is not valid.');
        case 'user-disabled':
          return Exception('This user has been disabled.');
        case 'user-not-found':
          return Exception('No user found with this email.');
        case 'wrong-password':
          return Exception('Incorrect password.');
        case 'email-already-in-use':
          return Exception('This email is already in use by another account.');
        case 'weak-password':
          return Exception('The password is too weak.');
        case 'operation-not-allowed':
          return Exception('Operation not allowed.');
        case 'too-many-requests':
          return Exception('Too many attempts. Try again later.');
        default:
          return Exception('An unknown error occurred: ${e.code}');
      }
    }
    return Exception('An error occurred: $e');
  }
}
