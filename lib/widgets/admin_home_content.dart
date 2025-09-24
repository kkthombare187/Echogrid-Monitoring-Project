import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// ADD THIS IMPORT to link to the issue reports screen
import 'package:flutter_project/screens/issue_reports_screen.dart';
import 'package:flutter_project/widgets/realtime_chart.dart';
import 'package:flutter_project/widgets/status_card.dart';
import 'package:flutter_project/widgets/summary_card.dart';

class AdminHomeContent extends StatelessWidget {
  const AdminHomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DatabaseReference solarRef = FirebaseDatabase.instance.ref('solar_generation');
    final DatabaseReference batteryRef = FirebaseDatabase.instance.ref('battery_storage');
    final DatabaseReference consumptionRef = FirebaseDatabase.instance.ref('energy_consumption');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- LIVE OVERVIEW Section ---
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

            // --- REAL-TIME ENERGY FLOW Section ---
            const Text('REAL-TIME ENERGY FLOW', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                SizedBox(width: 4),
                Text('Generation', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(width: 16),
                Icon(Icons.circle, color: Colors.cyan, size: 12),
                SizedBox(width: 4),
                Text('Consumption', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(width: 16),
                Icon(Icons.circle, color: Colors.orange, size: 12),
                SizedBox(width: 4),
                Text('Storage', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            const RealtimeChart(),
            const SizedBox(height: 24),

            // --- SYSTEM STATUS Section ---
            const Text('SYSTEM STATUS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const StatusCard(
                title: 'ANOMALY DETECTED:',
                subtitle: 'UNEXPECTED DROP IN SOLAR GENERATION',
                icon: Icons.warning_amber_rounded,
                color: Color(0xFFc62828)),
            const SizedBox(height: 12),
            const StatusCard(
                title: 'PREDICTIVE MAINTENANCE:',
                subtitle: 'INVERTER SERVICE DUE IN 5 DAYS',
                icon: Icons.build_circle_outlined,
                color: Color(0xFFf9a825)),
            const Divider(height: 40),

            // --- THIS IS THE NEW USER REPORTS SECTION ---
            const Text('USER REPORTS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              color: Colors.grey.shade800,
              child: ListTile(
                leading: const Icon(Icons.feedback_outlined, color: Colors.amber),
                title: const Text('View User Issue Reports'),
                subtitle: const Text('See what the community is reporting.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // This navigates to the screen showing all reports
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IssueReportsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build the summary cards
  Widget _buildSummaryCard(DatabaseReference ref, String title, String unit, IconData icon, Color color) {
    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          var value = snapshot.data!.snapshot.value;
          double percent = 0.0;
          if (unit == '%') {
            percent = (double.tryParse(value.toString()) ?? 0) / 100.0;
          } else {
            percent = (double.tryParse(value.toString()) ?? 0) / 5.0; // Assume max 5kW for others
          }
          return SummaryCard(
            title: title,
            value: '$value $unit',
            icon: icon,
            progressColor: color,
            percent: percent,
          );
        }
        return SummaryCard(title: title, value: '-- $unit', icon: icon, progressColor: Colors.grey, percent: 0.0);
      },
    );
  }
}

