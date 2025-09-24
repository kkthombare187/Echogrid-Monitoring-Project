import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_project/widgets/realtime_chart.dart';
import 'package:flutter_project/widgets/summary_card.dart';

class UserHomeContent extends StatelessWidget {
  const UserHomeContent({Key? key}) : super(key: key);

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

