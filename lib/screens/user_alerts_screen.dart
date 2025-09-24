import 'package:flutter/material.dart';

class UserAlertsScreen extends StatelessWidget {
  const UserAlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Alerts and notifications will appear here.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}

