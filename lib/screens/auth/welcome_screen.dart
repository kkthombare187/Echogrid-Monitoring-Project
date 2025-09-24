import 'package:flutter/material.dart';
import 'package:flutter_project/screens/auth/login_screen.dart';
import 'package:flutter_project/screens/auth/signup_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // App Logo and Title
              const Column(
                children: <Widget>[
                  Icon(Icons.shield_moon_outlined,
                      size: 100, color: Colors.greenAccent),
                  SizedBox(height: 20),
                  Text(
                    "Welcome",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "EcoGrid Monitor: Smart Energy for Rural Communities.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ).animate().fadeIn(duration: 900.ms, delay: 300.ms),

              // Action Buttons with corrected styling
              Column(
                children: <Widget>[
                  // Primary Button: Sign Up
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignupScreen()));
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Secondary Button: Login
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      side: const BorderSide(color: Colors.white70),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()));
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.white),
                    ),
                  ),
                ],
              )
                  .animate()
                  .slideY(begin: 1, duration: 600.ms, delay: 900.ms)
                  .fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
