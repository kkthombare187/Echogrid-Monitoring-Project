import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_project/services/weather_service.dart';
import 'package:flutter_project/screens/view_reports_screen.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({Key? key}) : super(key: key);

  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final TextEditingController _notificationController = TextEditingController();
  String _selectedBatteryMode = 'normal';
  bool _isLoadingWeather = false;
  String? _weatherErrorMessage;
  Map<String, dynamic>? _weatherData;

  @override
  Widget build(BuildContext context) {
    // --- Scaffold and AppBar have been removed from this file ---
    // The parent dashboard screen provides them.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Local Weather & Conditions', 'Get real-time weather data for the microgrid location.'),
          _buildWeatherCard(),
          const Divider(height: 40),

          _buildSectionHeader('User Reports', 'See what the community is reporting.'),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.feedback_outlined, color: Colors.cyan),
              title: const Text('View User Issue Reports'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewReportsScreen()),
                );
              },
            ),
          ),
          const Divider(height: 40),

          _buildSectionHeader('Remote Load Management', 'Remotely turn non-essential loads on or off.'),
          _buildControlSwitch('Agricultural Water Pumps', 'waterPumps', Icons.water_drop),
          _buildControlSwitch('Village Street Lights', 'streetLights', Icons.lightbulb),
          const Divider(height: 40),

          _buildSectionHeader('System Component Control', 'Remotely reboot critical system components.'),
          _buildRebootButton('Reboot Main Inverter', 'inverter'),
          _buildRebootButton('Reboot IoT Gateway', 'iot_gateway'),
          const Divider(height: 40),

          _buildSectionHeader('Battery & Power Mode', 'Set the operational strategy for the battery system.'),
          _buildBatteryModeSelector(),
          const Divider(height: 40),

          _buildSectionHeader('Manual Alert & Notification', 'Send a push notification to all users.'),
          _buildNotificationSender(),
        ],
      ),
    );
  }

  // --- ALL HELPER FUNCTIONS REMAIN THE SAME ---
  // [Omitted for brevity, but they should remain in your file]

  Future<void> _fetchWeatherData() async {
    // Added a check for 'mounted' to ensure the widget is still in the tree
    if (!mounted) return;
    setState(() {
      _isLoadingWeather = true;
      _weatherErrorMessage = null;
    });

    try {
      final data = await WeatherService.fetchWeather();
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherErrorMessage = e.toString();
          _isLoadingWeather = false;
        });
      }
    }
  }

  Widget _buildWeatherCard() {
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoadingWeather)
              const CircularProgressIndicator(),
            
            if (_weatherErrorMessage != null)
              Text('Error: $_weatherErrorMessage', style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),

            if (_weatherData != null)
              _buildWeatherDataDisplay(),

            if (!_isLoadingWeather && _weatherData == null)
              const Text("Press the button to get local weather.", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoadingWeather ? null : _fetchWeatherData,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Get Current Weather'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
    
    
      
  }

  

  Widget _buildWeatherDataDisplay() {
    if (_weatherData == null) return const SizedBox.shrink();

    final temperature = _weatherData!['temperature'];
    final weatherCode = _weatherData!['weathercode'];
    final interpretation = WeatherService.getWeatherInterpretation(weatherCode);

    return Column(
      children: [
        Text(
          '$temperature°C',
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
        ),
        Text(
          interpretation,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

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

  Widget _buildControlSwitch(String title, String dbNode, IconData icon) {
    final DatabaseReference controlRef = FirebaseDatabase.instance.ref('controls/$dbNode');
    return StreamBuilder<DatabaseEvent>(
      stream: controlRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final bool isEnabled = (snapshot.data!.snapshot.value as bool?) ?? false;
        return SwitchListTile(
          title: Text(title),
          value: isEnabled,
          onChanged: (bool newValue) => controlRef.set(newValue),
          secondary: Icon(icon, color: isEnabled ? Colors.greenAccent : Colors.grey),
          activeColor: Colors.greenAccent,
        );
      },
    );
  }

  Widget _buildRebootButton(String title, String dbNode) {
    return ListTile(
      leading: const Icon(Icons.power_settings_new, color: Colors.orangeAccent),
      title: Text(title),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
        child: const Text('Reboot'),
        onPressed: () => _confirmActionDialog(context, 'Confirm Reboot',
            'Are you sure you want to reboot the $title? This may cause a brief service interruption.',
            () { /* Add reboot logic here */ }),
      ),
    );
  }

  Widget _buildBatteryModeSelector() {
    final DatabaseReference modeRef = FirebaseDatabase.instance.ref('battery_mode');
    return StreamBuilder(
        stream: modeRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          _selectedBatteryMode = (snapshot.data!.snapshot.value as String?) ?? 'normal';
          return Column(
            children: [
              RadioListTile<String>(
                title: const Text('Normal Mode'),
                subtitle: const Text('Balanced charging and discharging.'),
                value: 'normal',
                groupValue: _selectedBatteryMode,
                onChanged: (value) => modeRef.set(value),
              ),
              RadioListTile<String>(
                title: const Text('Conservation Mode'),
                subtitle: const Text('Prioritizes essential loads to save power.'),
                value: 'conservation',
                groupValue: _selectedBatteryMode,
                onChanged: (value) => modeRef.set(value),
              ),
              RadioListTile<String>(
                title: const Text('Backup Priority Mode'),
                subtitle: const Text('Keeps battery full for emergencies.'),
                value: 'backup',
                groupValue: _selectedBatteryMode,
                onChanged: (value) => modeRef.set(value),
              ),
            ],
          );
        });
  }

  Widget _buildNotificationSender() {
    return Column(
      children: [
        TextField(
          controller: _notificationController,
          decoration: const InputDecoration(
            labelText: 'Notification Message',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Send Notification to All Users'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              if (_notificationController.text.trim().isNotEmpty) {
                FirebaseDatabase.instance.ref('notifications/latest_message').set(_notificationController.text.trim());
                _notificationController.clear();
                FocusScope.of(context).unfocus();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification sent!")));
              }
            },
          ),
        ),
      ],
    );
  }

  void _confirmActionDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

