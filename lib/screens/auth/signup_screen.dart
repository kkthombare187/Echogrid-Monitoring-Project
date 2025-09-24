import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/screens/dashboard/admin_dashboard_screen.dart';
import 'package:flutter_project/screens/dashboard/dashboard_screen.dart';

// Enum to manage the selected user role
enum UserRole { user, admin }

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  UserRole? _selectedRole = UserRole.user; // Default to User
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedRole == UserRole.admin) {
        // --- ADMIN REGISTRATION WITH FIREBASE EXTENSION ---
        // 1. Create the pending request in Firestore.
        final pendingAdminDoc =
            await FirebaseFirestore.instance.collection('pendingAdmins').add({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        });

        // 2. Create a document in the 'mail' collection to trigger the email extension.
        // --- IMPORTANT: UPDATE YOUR PROJECT DETAILS ---
        const region =
            "us-central1"; // The region of your handleAdminApproval function
        const projectId = "ecogrid-monitor"; // Your project ID
        final functionUrl =
            "https://${region}-${projectId}.cloudfunctions.net/handleAdminApproval";

        final approveUrl =
            "$functionUrl?id=${pendingAdminDoc.id}&action=approve";
        final denyUrl = "$functionUrl?id=${pendingAdminDoc.id}&action=deny";

        await FirebaseFirestore.instance.collection('mail').add({
          'to': [
            'karanthombre06@gmail.com'
          ], // The email that receives the approval request
          'message': {
            'subject': 'New Admin Registration Request!',
            'html': '''
              <p>A new admin registration request has been submitted for the email: ${_emailController.text.trim()}</p>
              <p>Please review and take action:</p>
              <a href="$approveUrl" style="padding: 10px; background-color: green; color: white; text-decoration: none;">Approve</a>
              <br/><br/>
              <a href="$denyUrl" style="padding: 10px; background-color: red; color: white; text-decoration: none;">Deny</a>
            ''',
          },
        });

        // 3. Inform the user and navigate back.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Admin registration submitted for approval.')),
          );
          Navigator.pop(context);
        }
      } else {
        // --- REGULAR USER REGISTRATION ---
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'role': 'user',
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    } finally {
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
      resizeToAvoidBottomInset: true,
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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          height: MediaQuery.of(context).size.height - 100,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Column(
                children: <Widget>[
                  Text(
                    "Sign up",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Create an account, it's free",
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  )
                ],
              ),
              Column(
                children: <Widget>[
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: "Confirm Password"),
                  ),
                ],
              ),
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
              MaterialButton(
                minWidth: double.infinity,
                height: 60,
                onPressed: _isLoading ? null : _signup,
                color: Colors.greenAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Sign up",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.black),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already have an account?"),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Go back to the login screen
                    },
                    child: const Text(
                      " Login",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
