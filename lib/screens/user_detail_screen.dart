import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the specific user's document from Firestore
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found or error loading data.'));
          }

          final user = snapshot.data!.data() as Map<String, dynamic>;
          final name = user['name'] ?? 'N/A';
          final email = user['email'] ?? 'N/A';
          final mobile = user['mobile'] ?? 'N/A';
          final role = user['role'] ?? 'user';
          final isBlocked = user['isBlocked'] ?? false;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildDetailCard('Name', name, Icons.person_outline),
              _buildDetailCard('Email', email, Icons.email_outlined),
              _buildDetailCard('Mobile', mobile, Icons.phone_outlined),
              _buildDetailCard('Role', role.toUpperCase(), Icons.security_outlined),
              _buildDetailCard(
                'Account Status',
                isBlocked ? 'Blocked' : 'Active',
                isBlocked ? Icons.block : Icons.check_circle_outline,
                valueColor: isBlocked ? Colors.redAccent : Colors.greenAccent,
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper widget to create a styled card for each piece of user information
  Widget _buildDetailCard(String title, String value, IconData icon, {Color? valueColor}) {
    return Card(
      color: Colors.grey.shade800,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade400),
        title: Text(title, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
