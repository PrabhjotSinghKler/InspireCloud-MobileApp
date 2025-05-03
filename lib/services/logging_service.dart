import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoggingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    final userId = _auth.currentUser?.uid;

    await _firestore.collection('logs').add({
      'type': 'error',
      'event': reason ?? 'Unhandled exception',
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': {
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      },
    });
  }

  /// Log to Firestore `/logs` collection
  Future<void> log({
    required String type,
    required String event,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _auth.currentUser?.uid;

    await _firestore.collection('logs').add({
      'type': type,
      'event': event,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });
  }
}
