import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_project/screens/notification_management_screen.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({Key? key}) : super(key: key);

  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  String _selectedBatteryMode = 'normal'; // To hold the current battery mode

  @override
  Widget build(BuildContext context) {
    // The parent dashboard screen provides the Scaffold and AppBar,
    // so this widget only needs to return the content.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Section 1: Remote Load Management
        _buildSectionHeader('Remote Load Management', 'Remotely turn non-essential loads on or off.'),
        _buildControlSwitch('Agricultural Water Pumps', 'waterPumps', Icons.water_drop),
        _buildControlSwitch('Village Street Lights', 'streetLights', Icons.lightbulb),
        const Divider(height: 40),

        // Section 2: System Component Control
        _buildSectionHeader('System Component Control', 'Remotely reboot critical system components.'),
        _buildRebootButton('Reboot Main Inverter', 'inverter'),
        _buildRebootButton('Reboot IoT Gateway', 'iot_gateway'),
        const Divider(height: 40),

        // Section 3: Battery & Power Mode
        _buildSectionHeader('Battery & Power Mode', 'Set the operational strategy for the battery system.'),
        _buildBatteryModeSelector(),
        const Divider(height: 40),

        // Section 4: Manual Alert & Notification
        _buildSectionHeader('Manual Alert & Notification', 'Send and manage announcements for all users.'),
        ListTile(
          leading: const Icon(Icons.campaign_outlined, color: Colors.blueAccent),
          title: const Text('Manage Notifications'),
          subtitle: const Text('Create, view, and delete user alerts.'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationManagementScreen()),
            );
          },
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---

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
            () { /* Placeholder for actual reboot logic */ }),
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
                activeColor: Colors.greenAccent,
              ),
              RadioListTile<String>(
                title: const Text('Conservation Mode'),
                subtitle: const Text('Prioritizes essential loads to save power.'),
                value: 'conservation',
                groupValue: _selectedBatteryMode,
                onChanged: (value) => modeRef.set(value),
                activeColor: Colors.greenAccent,
              ),
              RadioListTile<String>(
                title: const Text('Backup Priority Mode'),
                subtitle: const Text('Keeps battery full for emergencies.'),
                value: 'backup',
                groupValue: _selectedBatteryMode,
                onChanged: (value) => modeRef.set(value),
                activeColor: Colors.greenAccent,
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

