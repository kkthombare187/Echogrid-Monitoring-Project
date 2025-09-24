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
        // User is not logged in
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // User is logged in, check their role
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            // Still waiting for data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            // --- IMPROVED ERROR HANDLING ---
            // If there's an error OR the user document does NOT exist, something is wrong.
            // This is an invalid state, so we log them out and show the welcome screen.
            if (userSnapshot.hasError || !userSnapshot.data!.exists) {
              // It's safer to log out a user who is authenticated but has no user data.
              FirebaseAuth.instance.signOut();
              return const WelcomeScreen();
            }

            // --- SUCCESS PATH ---
            // We have the user data, now check the role
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
