import 'package:flutter/material.dart';
import 'package:flutter_project/services/ml_model_service.dart';
import 'package:flutter_project/widgets/status_card.dart';

// The vibration import has been removed.

class AnomalyReportScreen extends StatefulWidget {
  const AnomalyReportScreen({Key? key}) : super(key: key);

  @override
  _AnomalyReportScreenState createState() => _AnomalyReportScreenState();
}

class _AnomalyReportScreenState extends State<AnomalyReportScreen> {
  List<Map<String, dynamic>>? _anomalyResults;
  bool _isLoadingAnomalies = true;
  String? _anomalyErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnomalies();
  }

  Future<void> _fetchAnomalies() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAnomalies = true;
      _anomalyErrorMessage = null;
    });

    try {
      final results = await MlModelService.fetchAnomalyPredictions();
      if (mounted) {
        // 1. Filter the list to only include actual anomalies
        final anomalies = results.where((r) => r['Anomaly'] == true).toList();

        // 2. Sort the anomalies to show the newest ones at the top
        anomalies.sort((a, b) {
          final aTime = DateTime.tryParse(a['timestamp'] ?? '');
          final bTime = DateTime.tryParse(b['timestamp'] ?? '');
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime);
          }
          return 0; // Keep original order if timestamps are invalid
        });

        // --- CHANGE: Take the latest 6 results instead of 4 ---
        final latestAnomalies = anomalies.take(6).toList();

        setState(() => _anomalyResults = latestAnomalies);
      }
    } catch (e) {
      if (mounted) setState(() => _anomalyErrorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingAnomalies = false);
    }
  }

  // Helper function to get a specific color for each severity level
  Color _getColorForSeverity(String? severity) {
    switch (severity) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'Low':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Detection Report'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAnomalies,
        child: _buildAnomalyResultContent(),
      ),
    );
  }

  Widget _buildAnomalyResultContent() {
    if (_isLoadingAnomalies) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_anomalyErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _anomalyErrorMessage!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_anomalyResults != null) {
      if (_anomalyResults!.isEmpty) {
        return const Center(
          child: StatusCard(
            title: 'SYSTEM SCAN COMPLETE',
            subtitle: 'No anomalies were detected in the last 24 hours.',
            icon: Icons.check_circle_outline,
            color: Colors.greenAccent,
          ),
        );
      }
      // If anomalies are found, display them in a scrollable list
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _anomalyResults!.length, // This will now be 6 or less
        itemBuilder: (context, index) {
          final anomaly = _anomalyResults![index];
          final severity = anomaly['Severity'] as String?;
          // Handle cases where 'Devices' might not be a list
          final devices = (anomaly['Devices'] is List)
              ? (anomaly['Devices'] as List<dynamic>).join(', ')
              : anomaly['Devices'].toString();

          final cardColor = _getColorForSeverity(severity);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: StatusCard(
              title: 'ANOMALY: ${severity ?? 'Unknown'} Severity',
              subtitle: 'Devices: $devices\nTime: ${anomaly['timestamp']}',
              icon: Icons.warning_amber_rounded,
              color: cardColor,
            ),
          );
        },
      );
    }
    // Fallback message
    return const Center(child: Text('Pull to refresh data.'));
  }
}

