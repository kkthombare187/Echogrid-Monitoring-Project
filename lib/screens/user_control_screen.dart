import 'package:flutter/material.dart';
// Import the screen that the button will navigate to
import 'package:flutter_project/screens/report_issue_screen.dart';

class UserControlScreen extends StatefulWidget {
  const UserControlScreen({Key? key}) : super(key: key);

  @override
  _UserControlScreenState createState() => _UserControlScreenState();
}

class _UserControlScreenState extends State<UserControlScreen> {
  // State variables for the toggle switches
  bool _maintenanceAlerts = true;
  bool _demandWarnings = true;
  bool _communityAnnouncements = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Controls'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Notification Preferences
          _buildSectionHeader('Notification Preferences'),
          _buildNotificationSwitch(
            'Planned Maintenance Alerts',
            _maintenanceAlerts,
            (newValue) => setState(() => _maintenanceAlerts = newValue),
          ),
          _buildNotificationSwitch(
            'High Demand Warnings',
            _demandWarnings,
            (newValue) => setState(() => _demandWarnings = newValue),
          ),
          _buildNotificationSwitch(
            'Community Announcements',
            _communityAnnouncements,
            (newValue) => setState(() => _communityAnnouncements = newValue),
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
              // This is the navigation that opens the report form
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

  // Helper widget for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  // Helper widget for notification switches
  Widget _buildNotificationSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.cyan,
    );
  }
}