// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_project/screens/auth/welcome_screen.dart';
// import 'package:flutter_project/screens/admin_profile_screen.dart';
// import 'package:flutter_project/screens/user_management_screen.dart';
// import 'package:flutter_project/screens/analytics_screen.dart';
// // ADD THIS IMPORT to link to the control screen
// import 'package:flutter_project/screens/control_screen.dart'; 
// import 'package:flutter_project/widgets/realtime_chart.dart';
// import 'package:flutter_project/widgets/status_card.dart';
// import 'package:flutter_project/widgets/summary_card.dart';

// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({Key? key}) : super(key: key);

//   @override
//   _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
// }

// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   int _selectedIndex = 0; // State for the bottom navigation bar

//   // Function to handle logout
//   Future<void> _logout() async {
//     await FirebaseAuth.instance.signOut();
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (context) => const WelcomeScreen()),
//       (Route<dynamic> route) => false,
//     );
//   }

//   // THIS FUNCTION IS NOW FULLY CORRECTED
//   void _onItemTapped(int index) {
//     if (index == 4) { // Profile tab
//       Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen()));
//     } else if (index == 3) { // Users tab
//        Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()));
//     } else if (index == 1) { // Analytics tab
//       Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
//     } else if (index == 2) { // Control tab
//       // This is the new line that opens the control screen
//       Navigator.push(context, MaterialPageRoute(builder: (context) => const ControlScreen()));
//     }
//      else {
//       setState(() {
//         _selectedIndex = index; // This will only be for the Home tab (index 0)
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ... (The rest of the file is exactly the same as before)
//     // Define all database references inside the build method
//     final DatabaseReference solarRef = FirebaseDatabase.instance.ref('solar_generation');
//     final DatabaseReference batteryRef = FirebaseDatabase.instance.ref('battery_storage');
//     final DatabaseReference consumptionRef = FirebaseDatabase.instance.ref('energy_consumption');

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.person_outline),
//             onPressed: () {
//               Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen()));
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('LIVE OVERVIEW', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildSummaryCard(solarRef, 'SOLAR GENERATION', 'kW', Icons.wb_sunny, Colors.cyan),
//                   _buildSummaryCard(consumptionRef, 'CONSUMPTION', 'kW', Icons.power, Colors.blueAccent),
//                   _buildSummaryCard(batteryRef, 'BATTERY', '%', Icons.battery_charging_full, Colors.orange),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               const Text('REAL-TIME ENERGY FLOW', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.circle, color: Colors.greenAccent, size: 12),
//                   SizedBox(width: 4),
//                   Text('Generation', style: TextStyle(color: Colors.grey, fontSize: 12)),
//                   SizedBox(width: 16),
//                   Icon(Icons.circle, color: Colors.cyan, size: 12),
//                   SizedBox(width: 4),
//                   Text('Consumption', style: TextStyle(color: Colors.grey, fontSize: 12)),
//                   SizedBox(width: 16),
//                   Icon(Icons.circle, color: Colors.orange, size: 12),
//                   SizedBox(width: 4),
//                   Text('Storage', style: TextStyle(color: Colors.grey, fontSize: 12)),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               const RealtimeChart(),
//               const SizedBox(height: 24),
//               const Text('SYSTEM STATUS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 16),
//               const StatusCard(
//                   title: 'ANOMALY DETECTED:',
//                   subtitle: 'UNEXPECTED DROP IN SOLAR GENERATION',
//                   icon: Icons.warning_amber_rounded,
//                   color: Color(0xFFc62828)),
//               const SizedBox(height: 12),
//               const StatusCard(
//                   title: 'PREDICTIVE MAINTENANCE:',
//                   subtitle: 'INVERTER SERVICE DUE IN 5 DAYS',
//                   icon: Icons.build_circle_outlined,
//                   color: Color(0xFFf9a825)),
//               const SizedBox(height: 12),
//               const StatusCard(
//                   title: 'LOAD SCHEDULING:',
//                   subtitle: 'OPTIMIZED FOR TODAY',
//                   icon: Icons.check_circle_outline,
//                   color: Color(0xFF2e7d32)),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings_remote_outlined), label: 'Control'),
//           BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Users'),
//           BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Colors.greenAccent,
//         unselectedItemColor: Colors.grey,
//         backgroundColor: const Color(0xff2c4260),
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed,
//       ),
//     );
//   }

//   Widget _buildSummaryCard(DatabaseReference ref, String title, String unit, IconData icon, Color color) {
//     return StreamBuilder(
//       stream: ref.onValue,
//       builder: (context, snapshot) {
//         if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//           var value = snapshot.data!.snapshot.value;
//           double percent = 0.0;
//           if (unit == '%') {
//             percent = (double.tryParse(value.toString()) ?? 0) / 100.0;
//           } else {
//             percent = (double.tryParse(value.toString()) ?? 0) / 5.0; 
//           }

//           return SummaryCard(
//             title: title,
//             value: '$value $unit',
//             icon: icon,
//             progressColor: color,
//             percent: percent,
//           );
//         }
//         return SummaryCard(title: title, value: '-- $unit', icon: icon, progressColor: Colors.grey, percent: 0.0);
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project/screens/auth/welcome_screen.dart';
import 'package:flutter_project/screens/admin_profile_screen.dart';
import 'package:flutter_project/screens/user_management_screen.dart';
import 'package:flutter_project/screens/analytics_screen.dart';
import 'package:flutter_project/screens/control_screen.dart';
// This new file holds the content of the "Home" tab. We will create it next.
import 'package:flutter_project/widgets/admin_home_content.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0; // Manages which tab is currently selected

  // A list of the different pages the navigation bar can show.
  static const List<Widget> _widgetOptions = <Widget>[
    AdminHomeContent(),     // Index 0: The main dashboard view
    AnalyticsScreen(),      // Index 1: The Analytics page
    ControlScreen(),        // Index 2: The Control page
    UserManagementScreen(), // Index 3: The Users page
    AdminProfileScreen(),   // Index 4: The Profile page
  ];

  // This function is called when a tab is tapped.
  // It simply updates the index to show the correct page inside the shell.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to handle user logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // The logout button remains in the app bar for easy access
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      // The body of the scaffold now displays the selected page from our list.
      // It will swap between the pages without navigating away.
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // The bottom navigation bar is now part of this permanent "shell".
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_remote_outlined), label: 'Control'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xff2c4260),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible and have labels
      ),
    );
  }
}

