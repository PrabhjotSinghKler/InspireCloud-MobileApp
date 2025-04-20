// lib/models/saved_quote_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedQuoteModel {
  final String? id;
  final String content;
  final String userId;
  final DateTime savedAt;
  final String category; // Added category field

  SavedQuoteModel({
    this.id,
    required this.content,
    required this.userId,
    required this.category, // Add this parameter
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  factory SavedQuoteModel.fromJson(Map<String, dynamic> json) {
    return SavedQuoteModel(
      id: json['id'],
      content: json['content'] ?? '',
      userId: json['user_id'] ?? '',
      category: json['category'] ?? 'General', // Add this field
      savedAt:
          json['saved_at'] != null
              ? (json['saved_at'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'user_id': userId,
      'category': category, // Add this field
      'saved_at': savedAt,
    };
  }
}
