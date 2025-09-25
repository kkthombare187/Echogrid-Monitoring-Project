// lib/screens/view_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  _ViewReportsScreenState createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  final Stream<QuerySnapshot> _reportsStream = FirebaseFirestore.instance
      .collection('reports')
      .orderBy('timestamp', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _markReportsAsViewed();
  }

  // This function finds all 'new' reports and updates their status to 'viewed'
  // so the admin isn't notified about them again.
  Future<void> _markReportsAsViewed() async {
    final newReports = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'new')
        .get();

    for (var doc in newReports.docs) {
      await doc.reference.update({'status': 'viewed'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Reports'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reportsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No reports have been submitted yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              return ReportCard(document: document);
            }).toList(),
          );
        },
      ),
    );
  }
}

// NEW WIDGET to handle fetching user data for each report
class ReportCard extends StatelessWidget {
  final DocumentSnapshot document;

  const ReportCard({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> reportData = document.data()! as Map<String, dynamic>;
    String userId = reportData['userId'];

    // Use a FutureBuilder to fetch the user's document
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
        
        // --- Handle loading and error states for the user lookup ---
        if (userSnapshot.hasError) {
          return Card(
              child: ListTile(title: Text(reportData['reportText']), subtitle: const Text('Could not load user data.')));
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: ListTile(title: LinearProgressIndicator()));
        }
        
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
           return Card(
              child: ListTile(title: Text(reportData['reportText']), subtitle: const Text('User not found.')));
        }

        // --- Display the report with user details ---
        Map<String, dynamic> userData = userSnapshot.data!.data()! as Map<String, dynamic>;
        String userName = userData['name'] ?? 'Unknown Name';
        String userEmail = userData['email'] ?? 'No Email';

        String formattedDate = 'Date not available';
        if (reportData['timestamp'] != null) {
          Timestamp t = reportData['timestamp'] as Timestamp;
          DateTime d = t.toDate();
          formattedDate = DateFormat.yMMMd().add_jm().format(d);
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: ListTile(
            title: Text(reportData['reportText']),
            subtitle: Text('By: $userName ($userEmail)\nOn: $formattedDate'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}