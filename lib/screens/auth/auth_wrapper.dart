import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/screens/auth/welcome_screen.dart';
import 'package:flutter_project/screens/dashboard/admin_dashboard_screen.dart';
import 'package:flutter_project/screens/dashboard/dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is not logged in, show the welcome screen
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // User is logged in, now check their role from Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            // Still waiting to get the user's role
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            // Error fetching role, default to user dashboard or show error screen
            if (userSnapshot.hasError || !userSnapshot.data!.exists) {
              return const DashboardScreen(); // Fallback to user dashboard
            }

            // Check the role and navigate accordingly
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            if (userData['role'] == 'admin') {
              return const AdminDashboardScreen();
            } else {
              return const DashboardScreen();
            }
          },
        );
      },
    );
  }
}
