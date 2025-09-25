

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_project/screens/auth/welcome_screen.dart';
// import 'package:flutter_project/screens/admin_profile_screen.dart';
// import 'package:flutter_project/screens/user_management_screen.dart';
// import 'package:flutter_project/screens/analytics_screen.dart';
// import 'package:flutter_project/screens/control_screen.dart';
// // This new file holds the content of the "Home" tab. We will create it next.
// import 'package:flutter_project/widgets/admin_home_content.dart';

// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({Key? key}) : super(key: key);

//   @override
//   _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
// }

// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   int _selectedIndex = 0; // Manages which tab is currently selected

//   // A list of the different pages the navigation bar can show.
//   static const List<Widget> _widgetOptions = <Widget>[
//     AdminHomeContent(),     // Index 0: The main dashboard view
//     AnalyticsScreen(),      // Index 1: The Analytics page
//     ControlScreen(),        // Index 2: The Control page
//     UserManagementScreen(), // Index 3: The Users page
//     AdminProfileScreen(),   // Index 4: The Profile page
//   ];

//   // This function is called when a tab is tapped.
//   // It simply updates the index to show the correct page inside the shell.
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   // Function to handle user logout
//   Future<void> _logout() async {
//     await FirebaseAuth.instance.signOut();
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (context) => const WelcomeScreen()),
//       (Route<dynamic> route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           // The logout button remains in the app bar for easy access
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//           ),
//         ],
//       ),
//       // The body of the scaffold now displays the selected page from our list.
//       // It will swap between the pages without navigating away.
//       body: Center(
//         child: _widgetOptions.elementAt(_selectedIndex),
//       ),
//       // The bottom navigation bar is now part of this permanent "shell".
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
//         type: BottomNavigationBarType.fixed, // Ensures all items are visible and have labels
//       ),
//     );
//   }
// }










// lib/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. ADD FIRESTORE IMPORT
import 'package:flutter_project/screens/auth/welcome_screen.dart';
import 'package:flutter_project/screens/admin_profile_screen.dart';
import 'package:flutter_project/screens/user_management_screen.dart';
import 'package:flutter_project/screens/analytics_screen.dart';
import 'package:flutter_project/screens/control_screen.dart';
import 'package:flutter_project/screens/view_reports_screen.dart'; // <-- 2. ADD REPORTS SCREEN IMPORT
import 'package:flutter_project/widgets/admin_home_content.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    AdminHomeContent(),
    AnalyticsScreen(),
    ControlScreen(),
    UserManagementScreen(),
    AdminProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Use a short delay to ensure the UI is built before showing a dialog
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNewReports());
  }

  // --- NEW: FUNCTION TO CHECK FOR REPORTS ---
  Future<void> _checkNewReports() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'new')
        .get();

    final newReportCount = querySnapshot.size;

    if (newReportCount > 0 && mounted) {
      _showNewReportsDialog(newReportCount);
    }
  }

  // --- NEW: FUNCTION TO SHOW THE DIALOG ---
  void _showNewReportsDialog(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Reports Spotted!'),
        content: Text('You have $count unread report(s). Would you like to view them now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ViewReportsScreen()),
              );
            },
            child: const Text('View Now'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
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
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}