import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // State to manage which date range is selected
  String _selectedRange = 'Last 7 Days';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Date Range Selector
          _buildDateRangeSelector(),
          const SizedBox(height: 24),

          // Section 2: Historical Performance Summary
          _buildHistoricalSummary(),
          const SizedBox(height: 24),
          
          // Section 3: Peak Usage Times
          _buildPeakUsageCard(),
          const SizedBox(height: 24),

          // Section 4: Predictive Analytics (Forecast)
          _buildForecastSection(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDateRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _dateButton('Last 7 Days'),
        _dateButton('Last 30 Days'),
        _dateButton('Custom'),
      ],
    );
  }

  Widget _dateButton(String title) {
    final isSelected = _selectedRange == title;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedRange = title;
          // In the future, this will trigger a data refresh
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.greenAccent : Colors.grey.shade800,
        foregroundColor: isSelected ? Colors.black : Colors.white,
      ),
      child: Text(title),
    );
  }

  Widget _buildHistoricalSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historical Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _summaryCard('Total Generated', '452 kWh', Icons.flash_on, Colors.cyan),
            _summaryCard('Total Consumed', '418 kWh', Icons.power, Colors.blueAccent),
            _summaryCard('Grid Uptime', '99.8%', Icons.check_circle, Colors.greenAccent),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: Colors.grey.shade800,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeakUsageCard() {
    return Card(
      color: Colors.grey.shade800,
      child: const ListTile(
        leading: Icon(Icons.timer_outlined, color: Colors.orange),
        title: Text('Peak Usage Time'),
        subtitle: Text('Highest energy consumption typically occurs between 6 PM - 8 PM on weekdays.'),
      ),
    );
  }

  Widget _buildForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('24-Hour Solar Generation Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: Card(
            color: Colors.grey.shade800,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // Using a BarChart from fl_chart for the forecast
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20, // Max predicted kWh in a given hour
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    // Placeholder data for the next 24 hours
                    _forecastBar(0, 2), _forecastBar(1, 5), _forecastBar(2, 10),
                    _forecastBar(3, 15), _forecastBar(4, 18), _forecastBar(5, 16),
                    _forecastBar(6, 12), _forecastBar(7, 8), _forecastBar(8, 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper for creating a single bar in the forecast chart
  BarChartGroupData _forecastBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: Colors.greenAccent, width: 12, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }
}
