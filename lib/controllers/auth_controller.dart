import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/logging_service.dart';
import '../navigation_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LoggingService _loggingService = LoggingService();

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  bool _hasHandledInitialState = false;

  AuthController() {
    _authService.authStateChanges.listen((User? user) async {
      print('Auth state changed. User: ${user?.email ?? 'null'}');

      // Skip logging sign-out on initial state when user is null
      if (!_hasHandledInitialState && user == null) {
        _hasHandledInitialState = true;
        return;
      }

      _firebaseUser = user;

      if (user != null) {
        _hasHandledInitialState = true;
        await _loadUserData(user.uid);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();

        if (navigatorKey.currentContext != null) {
          Navigator.of(
            navigatorKey.currentContext!,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    });
  }

  // User and State Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isLoading => _isLoading;

  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _user = UserModel.fromJson({...userData, 'uid': uid});
      } else {
        _user = UserModel(
          uid: _firebaseUser!.uid,
          email: _firebaseUser!.email ?? '',
          displayName: _firebaseUser!.displayName,
          photoUrl: _firebaseUser!.photoURL,
        );

        await _firestore.collection('users').doc(uid).set(_user!.toJson());
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (user != null) {
        print('AuthController: Sign-in complete for ${user.email}');
      }
    } catch (e) {
      print('Error in AuthController signIn: $e');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.createUserWithEmailAndPassword(email, password);
      await _loggingService.log(
        type: 'security',
        event: 'user_signed_up',
        metadata: {'email': email, 'method': 'email_password'},
      );
    } catch (e) {
      // TEMPORARY BYPASS for type casting error
      if (e.toString().contains("PigeonUserDetails") ||
          e.toString().contains("is not a subtype")) {
        debugPrint('[TEMP BYPASS] Pigeon casting error ignored: $e');
        // Continue to login or navigation without rethrow
        return;
      }

      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_firebaseUser == null) return;

    final userId = _firebaseUser!.uid;
    _isLoading = true;
    notifyListeners();

    try {
      await _loggingService.log(
        type: 'security',
        event: 'user_signed_out',
        metadata: {'userId': userId},
      );
      await _authService.signOut();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      await _loggingService.log(
        type: 'security',
        event: 'password_reset_requested',
        metadata: {'email': email},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_firebaseUser == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'displayName': displayName,
      });

      if (_user != null) {
        _user = UserModel(
          uid: _user!.uid,
          email: _user!.email,
          displayName: displayName,
          photoUrl: _user!.photoUrl,
          role: _user!.role,
          createdAt: _user!.createdAt,
        );
      }

      await _loggingService.log(
        type: 'activity',
        event: 'updated_display_name',
        metadata: {'newName': displayName},
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to update display name: $e');
    }
  }

  Future<void> updateProfilePhoto(File imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_firebaseUser == null) throw Exception('User not logged in');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${_firebaseUser!.uid}_$timestamp.jpg';
      final storageRef = _storage.ref().child('profile_images/$fileName');

      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() => null);

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('users').doc(_firebaseUser!.uid).update({
          'photoUrl': downloadUrl,
        });

        if (_user != null) {
          _user = UserModel(
            uid: _user!.uid,
            email: _user!.email,
            displayName: _user!.displayName,
            photoUrl: downloadUrl,
            role: _user!.role,
            createdAt: _user!.createdAt,
          );
        }

        await _loggingService.log(
          type: 'activity',
          event: 'updated_profile_photo',
          metadata: {'photoUrl': downloadUrl},
        );
      } else {
        throw Exception('Upload failed: ${snapshot.state}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error in updateProfilePhoto: $e');
      throw Exception('Failed to update profile photo: $e');
    }
  }
}
