// lib/screens/user_control_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_project/screens/report_issue_screen.dart';
// Note: The import for my_reports_screen.dart is no longer needed.

class UserControlScreen extends StatelessWidget {
  const UserControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'My Controls',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          // The Card now only contains one button
          child: ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: Colors.amber),
            title: const Text('Report & View Issues'), // <-- Renamed for clarity
            subtitle: const Text('Submit a new report or view your history.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // This now navigates to the new combined screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}