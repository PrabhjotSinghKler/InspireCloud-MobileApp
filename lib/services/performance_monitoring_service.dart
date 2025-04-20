// lib/services/performance_monitoring_service.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceMonitoringService {
  final FirebasePerformance _performance = FirebasePerformance.instance;

  // Track a custom trace
  Future<void> startTrace(String traceName, Function() callback) async {
    final Trace trace = _performance.newTrace(traceName);
    await trace.start();

    try {
      await callback();
    } finally {
      await trace.stop();
    }
  }

  // Track HTTP request metrics
  HttpMetric startHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  // Enable or disable performance monitoring
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
  }
}
