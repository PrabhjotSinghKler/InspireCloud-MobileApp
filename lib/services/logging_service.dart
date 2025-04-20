// // lib/services/logging_service.dart
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';

// enum LogLevel { info, warning, error, fatal }

// class LoggingService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Log an event to Firestore
//   Future<void> logEvent(
//     String eventName,
//     Map<String, dynamic> parameters,
//   ) async {
//     try {
//       final String? userId = _auth.currentUser?.uid;

//       await _firestore.collection('app_logs').add({
//         'event': eventName,
//         'parameters': parameters,
//         'userId': userId,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       print('Failed to log event: $e');
//     }
//   }

//   // Log an error to Crashlytics
//   // Log an error to Crashlytics
//   Future<void> logError(
//     dynamic exception,
//     StackTrace? stackTrace, {
//     String? reason,
//     Iterable<DiagnosticsNode>? information,
//     bool fatal = false,
//   }) async {
//     try {
//       // Convert DiagnosticsNode to Object and handle null case
//       final Iterable<Object>? convertedInfo = information?.map(
//         (node) => node as Object,
//       );

//       await _crashlytics.recordError(
//         exception,
//         stackTrace,
//         reason: reason,
//         // Only pass non-null Iterable
//         information: convertedInfo ?? const <Object>[],
//         fatal: fatal,
//       );
//     } catch (e) {
//       print('Failed to log error: $e');
//     }
//   }

//   // Log a message with level
//   Future<void> log(
//     LogLevel level,
//     String message, {
//     Map<String, dynamic>? data,
//   }) async {
//     final Map<String, dynamic> logData = {
//       'message': message,
//       'level': level.toString(),
//       'timestamp': DateTime.now().toIso8601String(),
//       'data': data,
//     };

//     // Add user information if available
//     if (_auth.currentUser != null) {
//       logData['userId'] = _auth.currentUser!.uid;
//       logData['userEmail'] = _auth.currentUser!.email;
//     }

//     try {
//       await _firestore.collection('logs').add(logData);

//       // For errors and fatals, also log to Crashlytics
//       if (level == LogLevel.error || level == LogLevel.fatal) {
//         await _crashlytics.log(message);
//         if (data != null) {
//           for (final entry in data.entries) {
//             await _crashlytics.setCustomKey(entry.key, entry.value.toString());
//           }
//         }

//         if (level == LogLevel.fatal) {
//           await _crashlytics.recordError(
//             message,
//             StackTrace.current,
//             fatal: true,
//           );
//         }
//       }
//     } catch (e) {
//       print('Failed to write log: $e');
//     }
//   }
// }

// lib/services/logging_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, fatal }

class LoggingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names for different log types
  final String _generalLogsCollection = 'logs';
  final String _eventLogsCollection = 'app_logs';
  final String _userActivityCollection = 'user_activities';
  final String _pageViewCollection = 'page_views';

  // Log an event to Firestore
  Future<void> logEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      final String? userId = _auth.currentUser?.uid;

      await _firestore.collection(_eventLogsCollection).add({
        'event': eventName,
        'parameters': parameters,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  // Log an error to Crashlytics
  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<DiagnosticsNode>? information,
    bool fatal = false,
  }) async {
    try {
      // Convert DiagnosticsNode to Object and handle null case
      final Iterable<Object>? convertedInfo = information?.map(
        (node) => node as Object,
      );

      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        // Only pass non-null Iterable
        information: convertedInfo ?? const <Object>[],
        fatal: fatal,
      );
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  // Log a message with level
  Future<void> log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? metadata,
  }) async {
    final Map<String, dynamic> logData = {
      'message': message,
      'level': level.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata,
    };

    // Add user information if available
    if (_auth.currentUser != null) {
      logData['userId'] = _auth.currentUser!.uid;
      logData['userEmail'] = _auth.currentUser!.email;
    }

    try {
      await _firestore.collection(_generalLogsCollection).add(logData);

      // For errors and fatals, also log to Crashlytics
      if (level == LogLevel.error || level == LogLevel.fatal) {
        await _crashlytics.log(message);
        if (metadata != null) {
          for (final entry in metadata.entries) {
            await _crashlytics.setCustomKey(entry.key, entry.value.toString());
          }
        }

        if (level == LogLevel.fatal) {
          await _crashlytics.recordError(
            message,
            StackTrace.current,
            fatal: true,
          );
        }
      }
    } catch (e) {
      print('Failed to write log: $e');
    }
  }

  // Convenience methods for different log levels
  Future<void> debug(String message, {Map<String, dynamic>? metadata}) async {
    await log(LogLevel.debug, message, metadata: metadata);
  }

  Future<void> info(String message, {Map<String, dynamic>? metadata}) async {
    await log(LogLevel.info, message, metadata: metadata);
  }

  Future<void> warning(String message, {Map<String, dynamic>? metadata}) async {
    await log(LogLevel.warning, message, metadata: metadata);
  }

  Future<void> error(String message, {Map<String, dynamic>? metadata}) async {
    await log(LogLevel.error, message, metadata: metadata);
  }

  Future<void> fatal(String message, {Map<String, dynamic>? metadata}) async {
    await log(LogLevel.fatal, message, metadata: metadata);
  }

  // Log user activity
  Future<void> userActivity(
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    final String? userId = _auth.currentUser?.uid;
    final String? userEmail = _auth.currentUser?.email;

    final Map<String, dynamic> activityData = {
      'action': action,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'eventType': 'USER_ACTIVITY',
    };

    if (metadata != null) {
      activityData['metadata'] = metadata;
    }

    try {
      await _firestore.collection(_userActivityCollection).add(activityData);
    } catch (e) {
      print('Failed to log user activity: $e');
    }
  }

  // Log page view
  Future<void> pageView(
    String pageName, {
    Map<String, dynamic>? metadata,
  }) async {
    final String? userId = _auth.currentUser?.uid;
    final String? userEmail = _auth.currentUser?.email;

    final Map<String, dynamic> pageViewData = {
      'page': pageName,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'eventType': 'PAGE_VIEW',
    };

    if (metadata != null) {
      pageViewData['metadata'] = metadata;
    }

    try {
      await _firestore.collection(_pageViewCollection).add(pageViewData);
    } catch (e) {
      print('Failed to log page view: $e');
    }
  }
}
