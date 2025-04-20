import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;

  AuthController() {
    print('AuthController initialized, setting up auth state listener');
    _authService.authStateChanges.listen((User? user) async {
      print('Auth state changed. User: ${user?.email ?? 'null'}');
      _firebaseUser = user;
      if (user != null) {
        try {
          await _loadUserData(user.uid);
        } catch (e) {
          print('Error loading user data from Firestore: $e');
          // Create a basic user model from Firebase Auth data if Firestore fails
          _user = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );
          _isLoading = false;
          notifyListeners();
        }
      } else {
        print('User is null, setting _user to null');
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get user data from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        // If user document exists, create UserModel from it
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _user = UserModel.fromJson({...userData, 'uid': uid});
      } else {
        // If user doesn't exist in Firestore yet, create a basic model from Firebase Auth
        _user = UserModel(
          uid: _firebaseUser!.uid,
          email: _firebaseUser!.email ?? '',
          displayName: _firebaseUser!.displayName,
          photoUrl: _firebaseUser!.photoURL,
        );

        // Create the user document in Firestore
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

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isLoading => _isLoading;

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    print('AuthController signIn method started for: $email');
    _isLoading = true;
    notifyListeners();
    try {
      print('Calling auth service signIn');
      await _authService.signInWithEmailAndPassword(email, password);
      print('Auth service signIn completed');
    } catch (e) {
      print('Error in AuthController signIn: $e');

      // Check if this is our special error case where auth actually succeeded
      if (e.toString().contains('AUTH_SUCCEEDED_WITH_ERROR')) {
        print('Authentication succeeded despite error');
        _isLoading = false;
        notifyListeners();
        return; // Auth succeeded, let auth state listener handle it
      }

      // Check if user is already signed in despite the error
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print('User is authenticated despite error: ${currentUser.email}');
        _isLoading = false;
        notifyListeners();
        return; // Auth succeeded, let auth state listener handle it
      }

      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign up with email and password
  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.createUserWithEmailAndPassword(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Updated updateDisplayName method for AuthController
  Future<void> updateDisplayName(String displayName) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_firebaseUser == null) {
        throw Exception('User not logged in');
      }

      // Update Firestore user document
      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'displayName': displayName,
      });

      // Update local user model
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

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to update display name: $e');
    }
  }

  // Upload and update profile photo
  Future<void> updateProfilePhoto(File imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_firebaseUser == null) {
        throw Exception('User not logged in');
      }

      // Generate a unique filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${_firebaseUser!.uid}_$timestamp.jpg';

      // Create a reference to the storage location with the unique filename
      final storageRef = _storage.ref().child('profile_images').child(fileName);

      // Upload the file with metadata
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for the upload to complete and handle any errors
      final snapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL only if upload was successful
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore user document with the new photo URL
        await _firestore.collection('users').doc(_firebaseUser!.uid).update({
          'photoUrl': downloadUrl,
        });

        // Update local user model
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
