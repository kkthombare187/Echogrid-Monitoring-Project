import 'package:flutter/material.dart';
import 'package:flutter_project/screens/submit_report_screen.dart';

class UserControlScreen extends StatelessWidget {
  const UserControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We remove the Scaffold and AppBar from this child screen.
    // The parent (UserDashboardScreen) will provide them.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // This is the new card for reporting issues
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: Colors.amber),
            title: const Text('Report an Issue'),
            subtitle: const Text('Notice a problem? Let us know.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubmitReportScreen()),
              );
            },
          ),
        ),
        
        const SizedBox(height: 20),

        const Center(
          child: Text(
            'More user controls will be available here soon.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

