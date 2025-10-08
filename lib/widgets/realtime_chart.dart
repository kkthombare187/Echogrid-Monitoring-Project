import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:async/async.dart'; // Used for combining streams

class RealtimeChart extends StatefulWidget {
  const RealtimeChart({Key? key}) : super(key: key);

  @override
  State<RealtimeChart> createState() => _RealtimeChartState();
}

class _RealtimeChartState extends State<RealtimeChart> {
  // References to the historical data lists in Firebase
  final DatabaseReference _generationRef = FirebaseDatabase.instance.ref('history/generation');
  final DatabaseReference _consumptionRef = FirebaseDatabase.instance.ref('history/consumption');
  final DatabaseReference _storageRef = FirebaseDatabase.instance.ref('history/storage');

  // Helper function to safely convert a list of data into chart points (FlSpot)
  List<FlSpot> _createSpots(List<dynamic>? data) {
    List<FlSpot> spots = [];
    if (data == null) return spots; // Return empty list if data is null

    for (int i = 0; i < data.length; i++) {
      // Safely parse the data point to a double, defaulting to 0.0 if invalid
      double yValue = double.tryParse(data[i].toString()) ?? 0.0;
      spots.add(FlSpot(i.toDouble(), yValue));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.70,
      child: Card(
        clipBehavior: Clip.antiAlias, // This prevents the chart from drawing outside the card
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          // Use a StreamBuilder to listen for all three data streams at once
          child: StreamBuilder(
            stream: StreamZip([
              _generationRef.onValue,
              _consumptionRef.onValue,
              _storageRef.onValue
            ]),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              // Show a loading indicator while waiting for data
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading chart data.\nCheck database rules.',
                    style: TextStyle(color: Colors.redAccent.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              // Extract the data lists from the snapshot
              final events = snapshot.data as List<DatabaseEvent>;
              final generationSpots = _createSpots(events[0].snapshot.value as List<dynamic>?);
              final consumptionSpots = _createSpots(events[1].snapshot.value as List<dynamic>?);
              final storageSpots = _createSpots(events[2].snapshot.value as List<dynamic>?);

              // Return the LineChart with the live data
              return LineChart(
                mainData(generationSpots, consumptionSpots, storageSpots),
              );
            },
          ),
        ),
      ),
    );
  }

  // This function now includes the interactive touch data
  LineChartData mainData(List<FlSpot> generationSpots, List<FlSpot> consumptionSpots, List<FlSpot> storageSpots) {
    return LineChartData(
      // --- UPDATED: Interactive Tooltips ---
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          // The 'tooltipBgColor' property is replaced by 'getTooltipColor'
          getTooltipColor: (touchedSpot) {
            return Colors.blueGrey.withOpacity(0.8);
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 100,
        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xff37434d), strokeWidth: 1),
        getDrawingVerticalLine: (value) => const FlLine(color: Color(0xff37434d), strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42, interval: 100)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 11,
      minY: -50, // Added padding at the bottom
      maxY: 300,
      lineBarsData: [
        _buildLineChartBarData(generationSpots, Colors.greenAccent, [Colors.greenAccent.withOpacity(0.3), Colors.transparent]),
        _buildLineChartBarData(consumptionSpots, Colors.cyan, [Colors.cyan.withOpacity(0.3), Colors.transparent]),
        _buildLineChartBarData(storageSpots, Colors.orange, [Colors.orange.withOpacity(0.3), Colors.transparent]),
      ],
    );
  }

  // Helper function to create a styled line with a gradient
  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color, List<Color> gradientColors) {
    return LineChartBarData(
      
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

