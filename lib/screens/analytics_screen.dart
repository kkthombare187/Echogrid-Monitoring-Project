import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<double> _predictions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  Future<void> fetchPredictions() async {
    const url = "https://us-central1-ecogrid-monitor.cloudfunctions.net/predict_load";

    final body = jsonEncode({
      "data": {
        "day_of_week": DateTime.now().add(Duration(days: 1)).weekday - 1,
        "day_of_month": DateTime.now().add(Duration(days: 1)).day,
        "month": DateTime.now().add(Duration(days: 1)).month,
        "quarter": ((DateTime.now().add(Duration(days: 1)).month - 1) ~/ 3) + 1,
        "year": DateTime.now().add(Duration(days: 1)).year,
        "is_weekend": DateTime.now().add(Duration(days: 1)).weekday >= 6 ? 1 : 0
      }
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> preds = data['predictions'];

        setState(() {
          _predictions = preds.map((e) => (e as num).toDouble()).toList();
          _loading = false;
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print(e);
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Tomorrow\'s Power Forecast'),
        backgroundColor: Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Expected Power Generation (MW) for Each Hour',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _predictions.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.white24,
                                    strokeWidth: 1,
                                  );
                                },
                                getDrawingVerticalLine: (value) {
                                  return FlLine(
                                    color: Colors.white24,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 2,
                                    getTitlesWidget: (value, meta) {
                                      int hour = value.toInt();
                                      return Text(
                                        '$hour',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 2,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '${value.toInt()}',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                topTitles:
                                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles:
                                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.white24),
                              ),
                              minX: 0,
                              maxX: 23,
                              minY: 0,
                              maxY: (_predictions.reduce(
                                          (a, b) => a > b ? a : b) *
                                      1.2)
                                  .ceilToDouble(),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    _predictions.length,
                                    (index) => FlSpot(index.toDouble(),
                                        _predictions[index]),
                                  ),
                                  isCurved: true,
                                  color: Colors.greenAccent,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
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
}
