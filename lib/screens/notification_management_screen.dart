
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({Key? key}) : super(key: key);

  @override
  _NotificationManagementScreenState createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final TextEditingController _notificationController = TextEditingController();
  bool _isLoading = false;
  // NEW: State for the dropdown menu
  String _selectedNotificationType = 'community'; // Default type

  // A map of notification types for the dropdown
  final Map<String, String> _notificationTypes = {
    'community': 'Community Announcement',
    'maintenance': 'Planned Maintenance',
    'demand': 'High Demand Warning',
  };

  // This function is now smarter and saves the notification type
  Future<void> _sendNotification() async {
    if (_notificationController.text.trim().isEmpty) return;

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': _notificationController.text.trim(),
        'sentBy': user?.email ?? 'Admin',
        'timestamp': FieldValue.serverTimestamp(),
        // NEW: Save the selected type
        'type': _selectedNotificationType, 
      });
      _notificationController.clear();
      FocusScope.of(context).unfocus();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification sent successfully!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send notification: $e")));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _deleteNotification(String docId) async {
    // ... (This function remains the same)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- THIS IS THE NEW, UPDATED FORM ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // NEW: Dropdown to select notification type
                DropdownButtonFormField<String>(
                  value: _selectedNotificationType,
                  items: _notificationTypes.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedNotificationType = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Notification Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notificationController,
                  decoration: const InputDecoration(
                    labelText: 'Notification Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Send Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : _sendNotification,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // The list of sent notifications remains the same
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
               stream: FirebaseFirestore.instance.collection('notifications').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notifications have been sent yet.'));
                }

                final notifications = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final notification = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.campaign_outlined),
                        title: Text(notification['message'] ?? 'No message'),
                        subtitle: Text('Sent by: ${notification['sentBy'] ?? ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteNotification(doc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


