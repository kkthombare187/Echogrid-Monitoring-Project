import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class MlModelService {
  // --- URLs for your deployed models ---
  static const String _loadFunctionUrl = 'https://predict-load-5f4offyh3q-uc.a.run.app';
  
  // --- 1. PASTE YOUR CORRECT URL HERE (without the extra 'p') ---
  static const String _totalSolarForecastApiUrl = 'https://us-central1-ecogrid-monitor.cloudfunctions.net/predict_total_solar_generation'; 
  
  static const String _anomalyApiUrl = 'https://predict-anomalies-5f4offyh3q-uc.a.run.app';

  // --- MODEL 1: Load Forecasting (Unchanged) ---
  static Future<List<double>> getLoadForecast(Map<String, dynamic> inputData) async {
    try {
      final response = await http.post(
        Uri.parse(_loadFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': inputData}),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return List<double>.from(result['predictions']);
      } else {
        throw Exception('Failed to get load prediction: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling load prediction function: $e');
    }
  }

  // --- 2. THIS IS THE NEW, CORRECT FUNCTION ---
  static Future<String> fetchTotalSolarForecast() async {
    try {
      // The new function does all the work, so we just send a simple GET request.
      final response = await http.get(Uri.parse(_totalSolarForecastApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('total_generation_kwh')) {
          final totalKwh = data['total_generation_kwh'] as num;
          // Return the total value, formatted to two decimal places
          return '${totalKwh.toStringAsFixed(2)} kWh';
        } else {
          throw Exception("Response did not contain 'total_generation_kwh' key.");
        }
      } else {
        throw Exception('Failed to fetch total solar forecast: ${response.body}');
      }
    } catch (e) {
      // Return a user-friendly error message
      return 'Error: ${e.toString()}';
    }
  }

  // --- MODEL 3: Anomaly Detection (Unchanged) ---
  static Future<List<Map<String, dynamic>>> fetchAnomalyPredictions() async {
    try {
      final historyRef = FirebaseDatabase.instance.ref('sensor_history').limitToLast(24);
      final snapshot = await historyRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        throw Exception("No sensor history data found in '/sensor_history'.");
      }
      final data = snapshot.value as Map<dynamic, dynamic>;
      
      List<Map<String, dynamic>> records = [];
      data.forEach((key, value) {
          final record = Map<String, dynamic>.from(value as Map);
          records.add({
              "timestamp": record['timestamp'] ?? DateTime.now().toIso8601String(),
              "solar_gen": record['sensors']?['solar_generation'] ?? 0.0,
              "solar_voltage": record['sensors']?['solar_voltage'] ?? 0.0,
              "solar_current": record['sensors']?['solar_current'] ?? 0.0,
              "consumption": record['controls']?['energy_consumption'] ?? 0.0,
              "battery_voltage": record['sensors']?['battery_voltage'] ?? 0.0,
              "battery_current": record['sensors']?['battery_current'] ?? 0.0,
              "battery_temp": record['sensors']?['ds18b20_temp'] ?? 0.0,
              "soc": record['sensors']?['soc'] ?? 0.0,
              "env_temp": record['sensors']?['dht_temp'] ?? 0.0,
              "env_humidity": record['sensors']?['dht_humidity'] ?? 0.0,
              "relay_state": (record['controls']?['Load'] == true) ? 1 : 0,
          });
      });

      final response = await http.post(
        Uri.parse(_anomalyApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'records': records}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return List<Map<String, dynamic>>.from(result['results']);
      } else {
        throw Exception('Failed to get anomaly predictions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling anomaly prediction function: $e');
    }
  }
}

