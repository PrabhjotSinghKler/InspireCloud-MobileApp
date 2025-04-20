// lib/views/screens/admin/monitoring_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonitoringDashboard extends StatefulWidget {
  const MonitoringDashboard({super.key});

  @override
  State<MonitoringDashboard> createState() => _MonitoringDashboardState();
}

class _MonitoringDashboardState extends State<MonitoringDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserActivity> _userActivities = [];
  List<ApiUsage> _apiUsage = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user activity data
      final userActivityQuery = await _firestore
          .collection('user_stats')
          .orderBy('updatedAt', descending: true)
          .limit(10)
          .get();

      final userActivities = userActivityQuery.docs.map((doc) {
        final data = doc.data();
        return UserActivity(
          userId: doc.id,
          quotesGenerated: data['generatedQuotesCount'] ?? 0,
          quotesSaved: data['savedQuotesCount'] ?? 0,
          lastActivity: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();

      // Load API usage data
      final apiUsageQuery = await _firestore
          .collection('app_logs')
          .where('event', isEqualTo: 'api_call')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      final apiUsages = apiUsageQuery.docs.map((doc) {
        final data = doc.data();
        return ApiUsage(
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          endpoint: data['parameters']['endpoint'] ?? 'unknown',
          responseTime: data['parameters']['responseTime'] ?? 0,
          success: data['parameters']['success'] ?? false,
        );
      }).toList();

      setState(() {
        _userActivities = userActivities;
        _apiUsage = apiUsages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading monitoring data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Dashboard'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // API Usage Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'API Usage (Last 30 Calls)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _buildApiResponseTimeChart(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Success Rate: ${_calculateSuccessRate()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Activity Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Activity (Top 10)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _buildUserActivityChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // System Health Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'System Health',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSystemHealthIndicator(
                            'Database',
                            true,
                            'Normal',
                          ),
                          const SizedBox(height: 8),
                          _buildSystemHealthIndicator(
                            'API Services',
                            true,
                            'Normal',
                          ),
                          const SizedBox(height: 8),
                          _buildSystemHealthIndicator(
                            'Storage',
                            true,
                            'Normal',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSystemHealthIndicator(
    String system,
    bool isHealthy,
    String status,
  ) {
    return Row(
      children: [
        Icon(
          isHealthy ? Icons.check_circle : Icons.error,
          color: isHealthy ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          system,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(status),
      ],
    );
  }

  Widget _buildApiResponseTimeChart() {
    // Implementation would use charts_flutter package
    return const Center(
      child: Text('API Response Time Chart would be implemented here'),
    );
  }

  Widget _buildUserActivityChart() {
    // Implementation would use charts_flutter package
    return const Center(
      child: Text('User Activity Chart would be implemented here'),
    );
  }

  String _calculateSuccessRate() {
    if (_apiUsage.isEmpty) return '0';
    
    final successfulCalls = _apiUsage.where((usage) => usage.success).length;
    final rate = (successfulCalls / _apiUsage.length) * 100;
    return rate.toStringAsFixed(1);
  }
}

class UserActivity {
  final String userId;
  final int quotesGenerated;
  final int quotesSaved;
  final DateTime lastActivity;

  UserActivity({
    required this.userId,
    required this.quotesGenerated,
    required this.quotesSaved,
    required this.lastActivity,
  });
}

class ApiUsage {
  final DateTime timestamp;
  final String endpoint;
  final int responseTime;
  final bool success;

  ApiUsage({
    required this.timestamp,
    required this.endpoint,
    required this.responseTime,
    required this.success,
  });
}