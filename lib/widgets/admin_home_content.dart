import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_project/services/ml_model_service.dart';
import 'package:flutter_project/screens/anomaly_report_screen.dart';
import 'package:flutter_project/widgets/realtime_chart.dart';
import 'package:flutter_project/widgets/status_card.dart';
import 'package:flutter_project/widgets/summary_card.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AdminHomeContent extends StatefulWidget {
  const AdminHomeContent({Key? key}) : super(key: key);

  @override
  _AdminHomeContentState createState() => _AdminHomeContentState();
}

class _AdminHomeContentState extends State<AdminHomeContent> {
  // State for the dynamic anomaly card
  bool _isLoadingAnomalies = true;
  String _anomalyStatusText = 'Checking system status...';
  Color _anomalyStatusColor = Colors.grey;
  
  // State to control the fade-in animation
  bool _cardsVisible = false;

  @override
  void initState() {
    super.initState();
    _checkSystemStatus();
    // Trigger the animation shortly after the screen builds
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _cardsVisible = true);
    });
  }

  // Fetches anomaly data and updates the status card's text and color
  Future<void> _checkSystemStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAnomalies = true;
      _anomalyStatusText = 'Checking system status...';
      _anomalyStatusColor = Colors.grey;
    });

    try {
      final results = await MlModelService.fetchAnomalyPredictions();
      final anomalies = results.where((r) => r['Anomaly'] == true).toList();

      if (!mounted) return;

      if (anomalies.isEmpty) {
        setState(() {
          _anomalyStatusText = 'SYSTEM NORMAL - NO ANOMALIES DETECTED';
          _anomalyStatusColor = Colors.greenAccent;
        });
      } else {
        // Sort all anomalies to ensure we can find the latest ones
        anomalies.sort((a, b) {
          final aTime = DateTime.tryParse(a['timestamp'] ?? '');
          final bTime = DateTime.tryParse(b['timestamp'] ?? '');
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        // --- NEW LOGIC: Check for anomalies in the last hour ---
        final now = DateTime.now();
        final oneHourAgo = now.subtract(const Duration(hours: 1));
        final newAnomalies = anomalies.where((a) {
          final aTime = DateTime.tryParse(a['timestamp'] ?? '');
          return aTime != null && aTime.isAfter(oneHourAgo);
        }).toList();

        // --- NEW LOGIC: Get the 6 most recent anomalies for the fallback display ---
        final latestAnomalies = anomalies.take(6).toList();

        // Determine the highest severity from all anomalies in the last 24h
        bool hasHigh = anomalies.any((a) => a['Severity'] == 'High');
        bool hasMedium = anomalies.any((a) => a['Severity'] == 'Medium');

        setState(() {
          if (newAnomalies.isNotEmpty) {
            _anomalyStatusText = '${newAnomalies.length} NEW ANOMALIES (LAST HOUR) - TAP TO VIEW';
          } else {
            // --- CHANGE: Show the count of the latest anomalies (up to 6) ---
            _anomalyStatusText = '${latestAnomalies.length} RECENT ANOMALIES (LAST 24H) - TAP TO VIEW';
          }
          
          if (hasHigh) {
            _anomalyStatusColor = Colors.redAccent;
          } else if (hasMedium) {
            _anomalyStatusColor = Colors.orangeAccent;
          } else {
            _anomalyStatusColor = Colors.amber;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _anomalyStatusText = 'ERROR CHECKING STATUS - TAP TO VIEW DETAILS';
          _anomalyStatusColor = Colors.blueGrey;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAnomalies = false);
      }
    }
  }

  void _navigateToAnomalyReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnomalyReportScreen()),
    ).then((_) {
      // Re-check status when returning from the report screen
      _checkSystemStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference solarRef = FirebaseDatabase.instance.ref('solar_generation');
    final DatabaseReference batteryRef = FirebaseDatabase.instance.ref('battery_storage');
    final DatabaseReference consumptionRef = FirebaseDatabase.instance.ref('energy_consumption');

    return RefreshIndicator(
      onRefresh: _checkSystemStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LIVE OVERVIEW', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard(solarRef, 'SOLAR', 'kW', Icons.wb_sunny, Colors.cyan),
                  _buildSummaryCard(consumptionRef, 'CONSUMPTION', 'kW', Icons.power, Colors.blueAccent),
                  _buildSummaryCard(batteryRef, 'BATTERY', '%', Icons.battery_charging_full, Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              const Text('REAL-TIME ENERGY FLOW', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const RealtimeChart(),
              const SizedBox(height: 24),
              const Text('SYSTEM STATUS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // --- DYNAMIC & INTERACTIVE ANOMALY CARD ---
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _cardsVisible ? 1.0 : 0.0,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  padding: EdgeInsets.only(top: _cardsVisible ? 0 : 30),
                  child: GestureDetector(
                    onTap: _navigateToAnomalyReport,
                    child: StatusCard(
                      title: 'ANOMALY STATUS:',
                      subtitle: _anomalyStatusText,
                      icon: _anomalyStatusColor == Colors.greenAccent ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      color: _anomalyStatusColor,
                      isLoading: _isLoadingAnomalies,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // --- ANIMATED PREDICTIVE MAINTENANCE CARD ---
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
                opacity: _cardsVisible ? 1.0 : 0.0,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  padding: EdgeInsets.only(top: _cardsVisible ? 0 : 30),
                  child: const StatusCard(
                    title: 'PREDICTIVE MAINTENANCE:',
                    subtitle: 'INVERTER SERVICE DUE IN 5 DAYS',
                    icon: Icons.build_circle_outlined,
                    color: Color(0xFFf9a825),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(DatabaseReference ref, String title, String unit, IconData icon, Color color) {
    // This function remains the same
    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Expanded(child: Center(child: SpinKitFadingCircle(color: Colors.grey, size: 30.0)));
        }
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          var value = snapshot.data!.snapshot.value;
          double percent = 0.0;
          if (unit == '%') { percent = (double.tryParse(value.toString()) ?? 0) / 100.0; } 
          else { percent = (double.tryParse(value.toString()) ?? 0) / 5.0; } // Assume max 5kW for others
          return SummaryCard( title: title, value: '$value $unit', icon: icon, progressColor: color, percent: percent, );
        }
        return SummaryCard(title: title, value: '-- $unit', icon: icon, progressColor: Colors.grey, percent: 0.0);
      },
    );
  }
}

