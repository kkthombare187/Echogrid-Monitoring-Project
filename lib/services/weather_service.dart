import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // We are using the Open-Meteo API, which is free and does not require an API key.
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Fetches the current weather for the device's location.
  static Future<Map<String, dynamic>> fetchWeather() async {
    // First, get the user's location permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    // Get the current position (latitude and longitude).
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // Construct the API URL with the location and desired weather data.
    final url = Uri.parse(
        '$_baseUrl?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true');

    // Make the HTTP request to the API.
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // If the request is successful, parse the JSON and return the current weather data.
      return json.decode(response.body)['current_weather'];
    } else {
      // If the request fails, throw an error.
      throw Exception('Failed to load weather data');
    }
  }

  // Helper function to turn the weather code from the API into a human-readable string.
  static String getWeatherInterpretation(int code) {
    switch (code) {
      case 0: return 'Clear sky';
      case 1:
      case 2:
      case 3: return 'Mainly clear';
      case 45:
      case 48: return 'Fog';
      case 51:
      case 53:
      case 55: return 'Drizzle';
      case 61:
      case 63:
      case 65: return 'Rain';
      case 71:
      case 73:
      case 75: return 'Snowfall';
      case 80:
      case 81:
      case 82: return 'Rain showers';
      case 95: return 'Thunderstorm';
      default: return 'Unknown';
    }
  }
}

