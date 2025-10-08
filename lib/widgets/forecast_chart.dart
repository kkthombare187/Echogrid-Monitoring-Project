import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ForecastChart extends StatelessWidget {
  final List<double> forecastData;

  const ForecastChart({Key? key, required this.forecastData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (forecastData.isEmpty) {
      return const Center(child: Text("Not enough data to display chart."));
    }

    final List<FlSpot> spots = forecastData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final double maxY = (forecastData.reduce((a, b) => a > b ? a : b) * 1.2);

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: LineChart(
            LineChartData(
              // --- NEW: Interactive Tooltips ---
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) {
                    return Colors.blueGrey.withOpacity(0.8);
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: maxY / 5,
                getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xff37434d), strokeWidth: 1),
                getDrawingVerticalLine: (value) => const FlLine(color: Color(0xff37434d), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 4,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text('${value.toInt()}h', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: maxY / 5,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 23,
              minY: -(maxY * 0.1),
              maxY: maxY.ceilToDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent.withOpacity(0.4), Colors.blueAccent.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

