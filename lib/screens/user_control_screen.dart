import 'package:flutter/material.dart';
// This is the correct import for the report form
import 'package:flutter_project/screens/report_issue_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserControlScreen extends StatefulWidget {
  const UserControlScreen({Key? key}) : super(key: key);

  @override
  _UserControlScreenState createState() => _UserControlScreenState();
}

class _UserControlScreenState extends State<UserControlScreen> {
  // State variables for the notification toggle switches
  bool _maintenanceAlerts = true;
  bool _demandWarnings = true;
  bool _communityAnnouncements = true;
  bool _isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Function to load saved preferences from Firestore
  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        final data = doc.data();
        setState(() {
          // Set the switch state from the database, defaulting to 'true' if not set
          _maintenanceAlerts = data?['notification_preferences']?['maintenance'] ?? true;
          _demandWarnings = data?['notification_preferences']?['demand'] ?? true;
          _communityAnnouncements = data?['notification_preferences']?['community'] ?? true;
          _isLoading = false;
        });
      } else {
         if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Function to update a specific preference in Firestore
  Future<void> _updatePreference(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Use dot notation to update a specific field within the map
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'notification_preferences': {
          key: value,
        }
      }, SetOptions(merge: true)); // 'merge: true' ensures we don't overwrite other settings
    }
  }

  @override
  Widget build(BuildContext context) {
    // The parent dashboard provides the main Scaffold, but this screen
    // has its own AppBar for a clear title when the user navigates here.
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Controls'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // The back button is automatically added by Flutter
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Section 1: Notification Preferences
                _buildSectionHeader('Notification Preferences'),
                _buildNotificationSwitch(
                  'Planned Maintenance Alerts',
                  _maintenanceAlerts,
                  (newValue) {
                    setState(() => _maintenanceAlerts = newValue);
                    _updatePreference('maintenance', newValue);
                  },
                ),
                _buildNotificationSwitch(
                  'High Demand Warnings',
                  _demandWarnings,
                  (newValue) {
                    setState(() => _demandWarnings = newValue);
                    _updatePreference('demand', newValue);
                  },
                ),
                _buildNotificationSwitch(
                  'Community Announcements',
                  _communityAnnouncements,
                  (newValue) {
                    setState(() => _communityAnnouncements = newValue);
                    _updatePreference('community', newValue);
                  },
                ),
                const Divider(height: 40),

                // Section 2: Report an Issue
                _buildSectionHeader('Report an Issue'),
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined, color: Colors.amber),
                  title: const Text('Report a Problem'),
                  subtitle: const Text('Notice a problem with the grid? Let us know.'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // This is the correct navigation to the report form
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                    );
                  },
                ),
              ],
            ),
    );
  }

  // Helper widget for the section titles
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  // Helper widget for the notification toggle switches
  Widget _buildNotificationSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.cyan,
    );
  }
}

