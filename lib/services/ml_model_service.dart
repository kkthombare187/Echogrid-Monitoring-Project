// lib/services/ml_model_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MLModelService {
  static const String _functionUrl = 'https://us-central1-ecogrid-monitor.cloudfunctions.net/predict_load';

  // --- MODIFIED to return a List<double> ---
  static Future<List<double>> getLoadForecast(Map<String, dynamic> inputData) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': inputData}), // Match the python function
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        // Convert the list of dynamic to a list of double
        List<double> predictions = List<double>.from(result['predictions']);
        return predictions;
      } else {
        throw Exception('Failed to get prediction: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling prediction function: $e');
    }
  }
}