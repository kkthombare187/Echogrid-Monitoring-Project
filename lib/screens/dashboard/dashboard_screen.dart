
// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project/screens/auth/welcome_screen.dart';
import 'package:flutter_project/screens/user_profile_screen.dart';
import 'package:flutter_project/screens/alerts_screen.dart';
import 'package:flutter_project/widgets/user_home_content.dart';
import 'package:flutter_project/screens/user_control_screen.dart'; // <-- 1. ADD THIS IMPORT

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // The list of widgets that correspond to the bottom navigation bar items
  static const List<Widget> _widgetOptions = <Widget>[
    UserHomeContent(),
    UserControlScreen(), // <-- 2. REPLACE SizedBox() WITH THIS
    AlertsScreen(),
    UserProfileScreen(),
  ];

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
        title: const Text('EcoGrid Monitor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_remote_outlined), label: 'Control'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xff2c4260),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
