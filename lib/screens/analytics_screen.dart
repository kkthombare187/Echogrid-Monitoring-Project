import 'package:flutter/material.dart';
import 'package:flutter_project/services/ml_model_service.dart';
import 'package:flutter_project/widgets/forecast_chart.dart';
import 'package:flutter_project/widgets/status_card.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // State for Load Forecast
  List<double>? _loadForecastData;
  bool _isLoadingLoad = true;
  String? _loadErrorMessage;

  // State for Solar Forecast
  String? _solarForecastResult;
  bool _isLoadingSolar = true;
  String? _solarErrorMessage;

  @override
  void initState() {
    super.initState();
    // Automatically fetch forecasts when the screen is loaded
    _fetchAllForecasts();
  }

  // A single function to fetch both forecasts in parallel
  Future<void> _fetchAllForecasts() async {
    // Set loading state to true for both
    if (mounted) {
      setState(() {
        _isLoadingLoad = true;
        _isLoadingSolar = true;
        _loadErrorMessage = null;
        _solarErrorMessage = null;
      });
    }

    await Future.wait([
      _fetchLoadForecast(),
      _fetchSolarForecast(), // This now calls the new total forecast function
    ]);
  }

  Future<void> _fetchLoadForecast() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final inputData = {
        "day_of_week": tomorrow.weekday, "day_of_month": tomorrow.day,
        "month": tomorrow.month, "quarter": (tomorrow.month / 3).ceil(),
        "year": tomorrow.year, "is_weekend": (tomorrow.weekday == 6 || tomorrow.weekday == 7) ? 1 : 0,
      };
      final predictions = await MlModelService.getLoadForecast(inputData);
      if (mounted) setState(() => _loadForecastData = predictions);
    } catch (e) {
      if (mounted) setState(() => _loadErrorMessage = "Load Forecast Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoadingLoad = false);
    }
  }

  // --- THIS FUNCTION IS NOW UPDATED ---
  Future<void> _fetchSolarForecast() async {
    try {
      // It calls the new service method for the total daily forecast
      final result = await MlModelService.fetchTotalSolarForecast();
      if (mounted) {
        // Handle potential errors returned from the service
        if (result.toLowerCase().startsWith('error:')) {
            setState(() => _solarErrorMessage = result);
        } else {
            setState(() => _solarForecastResult = result);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _solarErrorMessage = "Solar Forecast Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoadingSolar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchAllForecasts,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Predictive Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // --- SECTION 1: LOAD FORECAST ---
          _buildSectionHeader('24-Hour Load Forecast', 'Predicted energy demand for the next 24 hours.'),
          _buildLoadForecastContent(),
          const Divider(height: 40),

          // --- SECTION 2: SOLAR GENERATION FORECAST (UI TEXT UPDATED) ---
          _buildSectionHeader('Total Daily Solar Forecast', 'Total predicted solar energy generation for all of tomorrow.'),
          _buildSolarForecastContent(),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadForecastContent() {
    if (_isLoadingLoad) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SpinKitFadingCircle(color: Colors.cyan, size: 50.0)));
    if (_loadErrorMessage != null) return Center(child: Text(_loadErrorMessage!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center));
    if (_loadForecastData != null) return ForecastChart(forecastData: _loadForecastData!);
    return const SizedBox.shrink();
  }

  Widget _buildSolarForecastContent() {
    if (_isLoadingSolar) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SpinKitFadingCircle(color: Colors.orangeAccent, size: 50.0)));
    if (_solarErrorMessage != null) return Center(child: Text(_solarErrorMessage!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center));
    if (_solarForecastResult != null) {
      return StatusCard(
        // --- TITLE UPDATED FOR CLARITY ---
        title: "TOMORROW'S TOTAL FORECAST:",
        subtitle: _solarForecastResult!,
        icon: Icons.wb_sunny,
        color: const Color(0xFFf9a825),
      );
    }
    return const SizedBox.shrink();
  }
}

