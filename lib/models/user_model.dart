// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName; // Changed from 'name' to 'displayName'
  final String? photoUrl;
  final String role; // 'user' or 'admin'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName, // Changed from 'name' to 'displayName'
    this.photoUrl,
    this.role = 'user', // Default role is 'user'
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName:
          json['displayName'], // Chang%$ed from 'name' to 'displayName'
      photoUrl: json['photoUrl'],
      role: json['role'] ?? 'user',
      createdAt:
          json['created_at'] != null
              ? (json['created_at'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName, // Changed from 'name' to 'displayName'
      'photoUrl': photoUrl,
      'role': role,
      'created_at': createdAt,
    };
  }
}
