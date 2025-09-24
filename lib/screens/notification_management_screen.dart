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

  // Function to send a new notification
  Future<void> _sendNotification() async {
    if (_notificationController.text.trim().isEmpty) return;

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': _notificationController.text.trim(),
        'sentBy': user?.email ?? 'Admin',
        'timestamp': FieldValue.serverTimestamp(),
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

  // Function to delete a notification
  Future<void> _deleteNotification(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification deleted.")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete notification: $e")));
    }
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
          // --- Form to send new notifications ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _notificationController,
                  decoration: const InputDecoration(
                    labelText: 'New Notification Message',
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
          // --- List of previously sent notifications ---
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Sent Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
