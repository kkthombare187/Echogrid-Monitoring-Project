// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_project/screens/notification_management_screen.dart';
// import '../services/weather_service.dart'; // Adjust path if needed

// class ControlScreen extends StatefulWidget {
//   const ControlScreen({Key? key}) : super(key: key);

//   @override
//   _ControlScreenState createState() => _ControlScreenState();
// }

// class _ControlScreenState extends State<ControlScreen> {
//   String _selectedBatteryMode = 'normal';
//   late Future<Map<String, dynamic>> _weatherFuture;

//   @override
//   void initState() {
//     super.initState();
//     _weatherFuture = WeatherService.fetchWeather();
//   }

//   void _refreshWeather() {
//     setState(() {
//       _weatherFuture = WeatherService.fetchWeather();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // A dark background for the whole screen
//     return Theme(
//       data: ThemeData.dark(), // This ensures all default text and icons are light
//       child: Container(
//         color: const Color(0xFF121212), // Material Design standard dark background
//         child: ListView(
//           padding: const EdgeInsets.all(16.0),
//           children: [
//             // Section 0: Live Weather
//             _buildWeatherCard(),
//             const SizedBox(height: 24),

//             // Section 1: Remote Load Management
//             _buildSectionHeader('Remote Load Management'),
//             Card(
//               elevation: 2,
//               color: const Color(0xFF1E1E1E), // Slightly lighter than background
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(
//                 children: [
//                   _buildControlSwitch('Agricultural Water Pumps', 'waterPumps', Icons.water_drop, Colors.blueAccent),
//                   const Divider(height: 1, indent: 16, endIndent: 16),
//                   _buildControlSwitch('Village Street Lights', 'streetLights', Icons.lightbulb, Colors.amberAccent),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Section 2: System Component Control
//             _buildSectionHeader('System Component Control'),
//             Card(
//               elevation: 2,
//               color: const Color(0xFF1E1E1E),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(
//                 children: [
//                   _buildRebootButton('Reboot Main Inverter', 'inverter'),
//                   const Divider(height: 1, indent: 16, endIndent: 16),
//                   _buildRebootButton('Reboot IoT Gateway', 'iot_gateway'),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Section 3: Battery & Power Mode
//             _buildSectionHeader('Battery & Power Mode'),
//             Card(
//               elevation: 2,
//               color: const Color(0xFF1E1E1E),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: _buildBatteryModeSelector(),
//             ),
//             const SizedBox(height: 24),

//             // Section 4: Manual Alert & Notification
//             _buildSectionHeader('Manual Alerts'),
//             Card(
//               elevation: 2,
//               color: const Color(0xFF1E1E1E),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: ListTile(
//                 leading: const Icon(Icons.campaign_outlined, color: Colors.purpleAccent),
//                 title: const Text('Manage Notifications'),
//                 subtitle: const Text('Create, view, and delete user alerts.'),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const NotificationManagementScreen()),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- STYLED HELPER WIDGETS ---

//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Colors.grey[400],
//         ),
//       ),
//     );
//   }

//   Widget _buildWeatherCard() {
//     return FutureBuilder<Map<String, dynamic>>(
//       future: _weatherFuture,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Card(
//             color: Colors.red[900]?.withOpacity(0.5),
//             child: ListTile(
//               leading: const Icon(Icons.error_outline, color: Colors.redAccent),
//               title: const Text('Failed to load weather'),
//               trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshWeather),
//             ),
//           );
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Card(
//             color: const Color(0xFF1E1E1E),
//             child: const ListTile(
//               leading: CircularProgressIndicator(),
//               title: Text('Fetching weather...'),
//             ),
//           );
//         }

//         if (snapshot.hasData) {
//           final weatherData = snapshot.data!;
//           final double temp = (weatherData['temperature'] as num?)?.toDouble() ?? 0.0;
//           final int weatherCode = (weatherData['weathercode'] as num?)?.toInt() ?? 0;
//           final String interpretation = WeatherService.getWeatherInterpretation(weatherCode);

//           return Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             clipBehavior: Clip.antiAlias,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.blue.shade800, Colors.deepPurple.shade700],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Icon(_getWeatherIcon(weatherCode), color: Colors.white, size: 50),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           '${temp.toStringAsFixed(1)}°C',
//                           style: const TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           interpretation,
//                           style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
//                         ),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.refresh, color: Colors.white),
//                     onPressed: _refreshWeather,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }

//   IconData _getWeatherIcon(int code) {
//     switch (code) {
//       case 0: return Icons.wb_sunny;
//       case 1:
//       case 2:
//       case 3: return Icons.cloud_outlined;
//       case 45:
//       case 48: return Icons.foggy;
//       case 51:
//       case 53:
//       case 55: return Icons.grain;
//       case 61:
//       case 63:
//       case 65: return Icons.water_drop;
//       case 71:
//       case 73:
//       case 75: return Icons.ac_unit;
//       case 80:
//       case 81:
//       case 82: return Icons.shower;
//       case 95: return Icons.thunderstorm;
//       default: return Icons.help_outline;
//     }
//   }

//   Widget _buildControlSwitch(String title, String dbNode, IconData icon, Color color) {
//     final DatabaseReference controlRef = FirebaseDatabase.instance.ref('controls/$dbNode');
//     return StreamBuilder<DatabaseEvent>(
//       stream: controlRef.onValue,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Padding(
//             padding: EdgeInsets.symmetric(vertical: 24.0),
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }
//         final bool isEnabled = (snapshot.data?.snapshot.value as bool?) ?? false;
//         return SwitchListTile(
//           title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//           value: isEnabled,
//           onChanged: (bool newValue) => controlRef.set(newValue),
//           secondary: Icon(icon, color: color),
//           activeColor: color,
//         );
//       },
//     );
//   }

//   Widget _buildRebootButton(String title, String dbNode) {
//     return ListTile(
//       leading: const Icon(Icons.power_settings_new, color: Colors.redAccent),
//       title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//       trailing: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red.shade900.withOpacity(0.5),
//           foregroundColor: Colors.red.shade200,
//           elevation: 0,
//         ),
//         child: const Text('Reboot'),
//         onPressed: () => _confirmActionDialog(context, 'Confirm Reboot',
//             'Are you sure you want to reboot the $title? This may cause a brief service interruption.',
//             () { /* Placeholder */ }),
//       ),
//     );
//   }

//   Widget _buildBatteryModeSelector() {
//     final DatabaseReference modeRef = FirebaseDatabase.instance.ref('battery_mode');
//     return StreamBuilder(
//         stream: modeRef.onValue,
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
//           _selectedBatteryMode = (snapshot.data!.snapshot.value as String?) ?? 'normal';
//           return Column(
//             children: [
//               RadioListTile<String>(
//                 title: const Text('Normal Mode'),
//                 subtitle: const Text('Balanced charging and discharging.'),
//                 value: 'normal',
//                 groupValue: _selectedBatteryMode,
//                 onChanged: (value) => modeRef.set(value),
//               ),
//               RadioListTile<String>(
//                 title: const Text('Conservation Mode'),
//                 subtitle: const Text('Prioritizes essential loads to save power.'),
//                 value: 'conservation',
//                 groupValue: _selectedBatteryMode,
//                 onChanged: (value) => modeRef.set(value),
//               ),
//               RadioListTile<String>(
//                 title: const Text('Backup Priority Mode'),
//                 subtitle: const Text('Keeps battery full for emergencies.'),
//                 value: 'backup',
//                 groupValue: _selectedBatteryMode,
//                 onChanged: (value) => modeRef.set(value),
//               ),
//             ],
//           );
//         });
//   }

//   void _confirmActionDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(content),
//         actions: [
//           TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               onConfirm();
//             },
//             child: const Text('Confirm', style: TextStyle(color: Colors.redAccent)),
//           ),
//         ],
//       ),
//     );
//   }
// }















import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_project/screens/notification_management_screen.dart';
import '../services/weather_service.dart'; // Adjust path if needed
import 'package:flutter_project/screens/view_reports_screen.dart'; // <-- ADD THIS IMPORT

class ControlScreen extends StatefulWidget {
  const ControlScreen({Key? key}) : super(key: key);

  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  String _selectedBatteryMode = 'normal';
  late Future<Map<String, dynamic>> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = WeatherService.fetchWeather();
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = WeatherService.fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Container(
        color: const Color(0xFF121212),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ... (Weather Card code remains the same)
            _buildWeatherCard(),
            const SizedBox(height: 24),
            
            // ... (Remote Load Management code remains the same)
             _buildSectionHeader('Remote Load Management'),
            Card(
              elevation: 2,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildControlSwitch('Agricultural Water Pumps', 'waterPumps', Icons.water_drop, Colors.blueAccent),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildControlSwitch('Village Street Lights', 'streetLights', Icons.lightbulb, Colors.amberAccent),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ... (System Component Control code remains the same)
             _buildSectionHeader('System Component Control'),
            Card(
              elevation: 2,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildRebootButton('Reboot Main Inverter', 'inverter'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildRebootButton('Reboot IoT Gateway', 'iot_gateway'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ... (Battery & Power Mode code remains the same)
             _buildSectionHeader('Battery & Power Mode'),
            Card(
              elevation: 2,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _buildBatteryModeSelector(),
            ),
            const SizedBox(height: 24),
            
            // --- MODIFIED SECTION ---
            _buildSectionHeader('System Management'),
            Card(
              elevation: 2,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.campaign_outlined, color: Colors.purpleAccent),
                    title: const Text('Manage Notifications'),
                    subtitle: const Text('Create, view, and delete user alerts.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationManagementScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16), // Divider
                  // --- NEW BUTTON ADDED HERE ---
                  ListTile(
                    leading: const Icon(Icons.report_problem_outlined, color: Colors.amberAccent),
                    title: const Text('View User Reports'),
                    subtitle: const Text('See issues submitted by users.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ViewReportsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (All other helper widgets like _buildSectionHeader, _buildWeatherCard, etc., remain exactly the same)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            color: Colors.red[900]?.withOpacity(0.5),
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.redAccent),
              title: const Text('Failed to load weather'),
              trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshWeather),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            color: const Color(0xFF1E1E1E),
            child: const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Fetching weather...'),
            ),
          );
        }

        if (snapshot.hasData) {
          final weatherData = snapshot.data!;
          final double temp = (weatherData['temperature'] as num?)?.toDouble() ?? 0.0;
          final int weatherCode = (weatherData['weathercode'] as num?)?.toInt() ?? 0;
          final String interpretation = WeatherService.getWeatherInterpretation(weatherCode);

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.deepPurple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(_getWeatherIcon(weatherCode), color: Colors.white, size: 50),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${temp.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          interpretation,
                          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _refreshWeather,
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  IconData _getWeatherIcon(int code) {
    switch (code) {
      case 0: return Icons.wb_sunny;
      case 1:
      case 2:
      case 3: return Icons.cloud_outlined;
      case 45:
      case 48: return Icons.foggy;
      case 51:
      case 53:
      case 55: return Icons.grain;
      case 61:
      case 63:
      case 65: return Icons.water_drop;
      case 71:
      case 73:
      case 75: return Icons.ac_unit;
      case 80:
      case 81:
      case 82: return Icons.shower;
      case 95: return Icons.thunderstorm;
      default: return Icons.help_outline;
    }
  }

  Widget _buildControlSwitch(String title, String dbNode, IconData icon, Color color) {
    final DatabaseReference controlRef = FirebaseDatabase.instance.ref('controls/$dbNode');
    return StreamBuilder<DatabaseEvent>(
      stream: controlRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final bool isEnabled = (snapshot.data?.snapshot.value as bool?) ?? false;
        return SwitchListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          value: isEnabled,
          onChanged: (bool newValue) => controlRef.set(newValue),
          secondary: Icon(icon, color: color),
          activeColor: color,
        );
      },
    );
  }

  Widget _buildRebootButton(String title, String dbNode) {
    return ListTile(
      leading: const Icon(Icons.power_settings_new, color: Colors.redAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade900.withOpacity(0.5),
          foregroundColor: Colors.red.shade200,
          elevation: 0,
        ),
        child: const Text('Reboot'),
        onPressed: () => _confirmActionDialog(context, 'Confirm Reboot',
            'Are you sure you want to reboot the $title? This may cause a brief service interruption.',
            () { /* Placeholder */ }),
      ),
    );
  }

  Widget _buildBatteryModeSelector() {
    final DatabaseReference modeRef = FirebaseDatabase.instance.ref('battery_mode');
    return StreamBuilder(
        stream: modeRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
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