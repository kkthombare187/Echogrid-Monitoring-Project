import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_project/screens/dashboard/admin_dashboard_screen.dart';
import 'package:flutter_project/screens/auth/signup_screen.dart';

// Enum to manage the selected user role
enum UserRole { user, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to manage the text in the email and password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Variable to keep track of the selected role
  UserRole? _selectedRole = UserRole.user; // Default to User
  bool _isLoading = false;

  // Function to handle the login logic
  Future<void> _login() async {
    // Show a loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Use Firebase to sign in with email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Navigate based on the selected role after successful login
      if (mounted) { // Check if the widget is still in the tree
        if (_selectedRole == UserRole.admin) {
          Navigator.of(context).pushReplacement(
            // CORRECTED: Removed 'const'
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            // CORRECTED: Removed 'const'
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle login errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } finally {
      // Hide the loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Column(
              children: <Widget>[
                Text(
                  "Login",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  "Login to your account",
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                )
              ],
            ),
            Column(
              children: <Widget>[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                ),
              ],
            ),
            // Role selection radio buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<UserRole>(
                  value: UserRole.user,
                  groupValue: _selectedRole,
                  onChanged: (UserRole? value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                const Text('User'),
                const SizedBox(width: 20),
                Radio<UserRole>(
                  value: UserRole.admin,
                  groupValue: _selectedRole,
                  onChanged: (UserRole? value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                const Text('Admin'),
              ],
            ),
            // Login button with loading indicator
            MaterialButton(
              minWidth: double.infinity,
              height: 60,
              onPressed: _isLoading ? null : _login,
              color: Colors.greenAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      "Login",
                      // CORRECTED: Used FontWeight.w600 instead of a string
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black),
                    ),
            ),
            // This is the CORRECT location for the "Sign up" navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text("Don't have an account?"),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                  },
                  child: const Text(
                    " Sign up",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

