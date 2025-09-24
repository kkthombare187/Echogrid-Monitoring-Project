import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ViewReportsScreen extends StatelessWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DatabaseReference reportsRef = FirebaseDatabase.instance.ref('user_reports');

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Issue Reports'),
      ),
      body: StreamBuilder(
        stream: reportsRef.orderByChild('timestamp').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Improved Error Handling ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'An error occurred. Please check your database rules and internet connection.\n\nError: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No issue reports have been submitted.'));
          }

          final Map<dynamic, dynamic> reportsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<dynamic, dynamic>> reports = reportsMap.entries.map((e) {
            final report = Map<String, dynamic>.from(e.value as Map);
            report['key'] = e.key;
            return report;
          }).toList();
          
          reports.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final DateTime time = DateTime.fromMillisecondsSinceEpoch(report['timestamp']);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    report['status'] == 'resolved' ? Icons.check_circle : Icons.warning_amber,
                    color: report['status'] == 'resolved' ? Colors.green : Colors.orange,
                  ),
                  title: Text(report['title'] ?? 'No Title'),
                  subtitle: Text('Reported by: ${report['userEmail']}\nOn: ${time.toLocal().toString().substring(0, 16)}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // We can create a detail screen here in the future
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

