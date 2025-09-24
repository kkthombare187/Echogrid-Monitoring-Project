import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IssueReportsScreen extends StatelessWidget {
  const IssueReportsScreen({Key? key}) : super(key: key);

  // Helper to get a color based on the issue status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blueAccent;
      case 'in_progress':
        return Colors.orangeAccent;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Issue Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Create a stream to listen for real-time changes in the 'issues' collection
        // Order by timestamp to show the newest reports first
        stream: FirebaseFirestore.instance
            .collection('issues')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong. Check Firestore rules.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No issues have been reported yet.'));
          }

          final issues = snapshot.data!.docs;

          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index].data() as Map<String, dynamic>;
              final issueType = issue['issueType'] ?? 'Unknown Type';
              final description = issue['description'] ?? 'No description';
              final reportedBy = issue['reportedBy'] ?? 'Unknown User';
              final status = issue['status'] ?? 'unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade800,
                child: ListTile(
                  isThreeLine: true,
                  leading: const Icon(Icons.report_problem_outlined, color: Colors.amber),
                  title: Text(issueType, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$description\nReported by: $reportedBy'),
                  trailing: Chip(
                    label: Text(status, style: const TextStyle(color: Colors.white)),
                    backgroundColor: _getStatusColor(status),
                  ),
                  onTap: () {
                    // Placeholder for future action to update the status
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

