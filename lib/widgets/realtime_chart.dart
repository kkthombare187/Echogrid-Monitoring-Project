import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:async/async.dart'; // <-- ADD THIS IMPORT

class RealtimeChart extends StatefulWidget {
  const RealtimeChart({Key? key}) : super(key: key);

  @override
  State<RealtimeChart> createState() => _RealtimeChartState();
}

class _RealtimeChartState extends State<RealtimeChart> {
  // Create references to the historical data lists
  final DatabaseReference _generationRef =
      FirebaseDatabase.instance.ref('history/generation');
  final DatabaseReference _consumptionRef =
      FirebaseDatabase.instance.ref('history/consumption');
  final DatabaseReference _storageRef =
      FirebaseDatabase.instance.ref('history/storage');

  // Helper function to convert a list of numbers into chart data points (FlSpot)
  List<FlSpot> _createSpots(List<dynamic> data) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      // Ensure the data point is treated as a number
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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xff2c4260),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // Use a StreamBuilder to listen for all three data streams at once
          child: StreamBuilder(
            // Use StreamZip for a more reliable way to combine the streams
            stream: StreamZip([       // <-- THIS LINE WAS CHANGED
              _generationRef.onValue,
              _consumptionRef.onValue,
              _storageRef.onValue
            ]),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) { // <-- THIS TYPE WAS CHANGED
              // Show a loading indicator while waiting for data
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading chart data'));
              }
              
              // Extract the data lists from the snapshot
              // The data is now a List<DatabaseEvent>
              final events = snapshot.data as List<DatabaseEvent>;
              final generationData = events[0].snapshot.value as List<dynamic>? ?? [];
              final consumptionData = events[1].snapshot.value as List<dynamic>? ?? [];
              final storageData = events[2].snapshot.value as List<dynamic>? ?? [];

              // Convert the lists into chart spots
              final generationSpots = _createSpots(generationData);
              final consumptionSpots = _createSpots(consumptionData);
              final storageSpots = _createSpots(storageData);

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

  // This function now accepts the live data points as arguments
  LineChartData mainData(List<FlSpot> generationSpots, List<FlSpot> consumptionSpots, List<FlSpot> storageSpots) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
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
      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d))),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 300,
      lineBarsData: [
        // Line 1: Generation (Green) - USES LIVE DATA
        LineChartBarData(
          spots: generationSpots,
          isCurved: true,
          color: Colors.greenAccent,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        // Line 2: Consumption (Blue) - USES LIVE DATA
        LineChartBarData(
          spots: consumptionSpots,
          isCurved: true,
          color: Colors.cyan,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        // Line 3: Storage (Orange) - USES LIVE DATA
        LineChartBarData(
          spots: storageSpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }
}

