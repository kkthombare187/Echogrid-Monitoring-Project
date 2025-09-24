import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get a reference to the specific notification message in Firebase
    final DatabaseReference notificationRef =
        FirebaseDatabase.instance.ref('notifications/latest_message');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DatabaseEvent>(
          stream: notificationRef.onValue,
          builder: (context, snapshot) {
            // Show a loading indicator while waiting for the first message
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Handle any potential errors
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load notifications.'));
            }
            // Check if there is data and it's not null
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final message = snapshot.data!.snapshot.value as String;
              
              // If there's a message, display it in a styled card
              if (message.isNotEmpty) {
                return Center(
                  child: Card(
                    color: Colors.amber.shade800,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.campaign, size: 40, color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Latest Announcement',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            }

            // If there are no messages, show a default status
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
          },
        ),
      ),
    );
  }
}
