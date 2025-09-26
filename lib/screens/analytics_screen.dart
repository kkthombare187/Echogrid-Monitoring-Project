// lib/screens/analytics_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/services/ml_model_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // --- MODIFIED state variable to hold a list ---
  List<double>? _predictedLoads;
  bool _isLoadingForecast = true;
  String? _forecastError;

  final _feature1Controller = TextEditingController(text: '10.5');
  final _feature2Controller = TextEditingController(text: '25.0');
  
  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  @override
  void dispose() {
    _feature1Controller.dispose();
    _feature2Controller.dispose();
    super.dispose();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      _isLoadingForecast = true;
      _forecastError = null;
    });

    Map<String, dynamic> modelInput = {
      "feature1": double.tryParse(_feature1Controller.text) ?? 0.0,
      "feature2": double.tryParse(_feature2Controller.text) ?? 0.0,
    };

    try {
      // --- MODIFIED to get a list of forecasts ---
      List<double> forecasts = await MLModelService.getLoadForecast(modelInput);
      setState(() {
        _predictedLoads = forecasts;
        _isLoadingForecast = false;
      });
    } catch (e) {
      setState(() {
        _forecastError = e.toString();
        _isLoadingForecast = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchForecast,
            tooltip: 'Get Forecast',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // This section is now the dynamic chart
            _buildLoadForecastChart(),
            const SizedBox(height: 24),
            
            _buildInputFields(),
            // ... other sections ...
          ],
        ),
      ),
    );
  }

  // --- MODIFIED WIDGET: Now a dynamic bar chart ---
  Widget _buildLoadForecastChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('24-Hour Load Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Card(
            color: Colors.grey.shade800,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoadingForecast
                  ? const Center(child: CircularProgressIndicator())
                  : _forecastError != null
                      ? Center(child: Text('Error: Could not get forecast.', style: TextStyle(color: Colors.red[300])))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barGroups: _generateBarGroups(), // Dynamically generate bars
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles)),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                          ),
                        ),
            ),
          ),
        ),
      ],
    );
  }

  // --- NEW HELPER: To generate chart bars from prediction data ---
  List<BarChartGroupData> _generateBarGroups() {
    if (_predictedLoads == null) return [];
    return List.generate(_predictedLoads!.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: _predictedLoads![index], color: Colors.greenAccent),
        ],
      );
    });
  }

  // --- NEW HELPER: To create labels for the bottom of the chart ---
  Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    String text;
    // Show a label every 6 hours
    if (value.toInt() % 6 == 0) {
      text = '${value.toInt()}h';
    } else {
      text = '';
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }
  
  // Other widgets like _buildInputFields remain the same...
  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forecast Input', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          color: Colors.grey.shade800,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _feature1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Feature 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feature2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Feature 2',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}