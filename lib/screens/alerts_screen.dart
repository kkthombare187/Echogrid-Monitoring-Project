import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The parent dashboard screen provides the Scaffold and AppBar,
    // so this widget only needs to return the content for the body.
    return StreamBuilder<QuerySnapshot>(
      // Listen to the 'notifications' collection in Firestore,
      // and order the messages by timestamp to show the newest first.
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Show a loading indicator while the data is being fetched
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Show an error message if something goes wrong
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load notifications.'));
        }
        // Show a friendly message if there are no notifications
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.greenAccent),
                SizedBox(height: 16),
                Text(
                  'No new notifications.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // If we have data, get the list of notification documents
        final notifications = snapshot.data!.docs;
        
        // Display the notifications in a scrollable list
        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index].data() as Map<String, dynamic>;
            final message = notification['message'] ?? 'No message content';
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.campaign, color: Colors.white, size: 30),
                title: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

