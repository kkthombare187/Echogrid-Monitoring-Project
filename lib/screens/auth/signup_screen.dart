import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_project/widgets/custom_textfield.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;
  String? _errorMessage;

  // Your signup logic remains the same
  Future<void> _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedRole == UserRole.admin) {
        final pendingAdminDoc =
            await FirebaseFirestore.instance.collection('pendingAdmins').add({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        });

        const region = "us-central1";
        const projectId = "ecogrid-monitor";
        final functionUrl =
            "https://${region}-${projectId}.cloudfunctions.net/handleAdminApproval";
        final approveUrl =
            "$functionUrl?id=${pendingAdminDoc.id}&action=approve";
        final denyUrl = "$functionUrl?id=${pendingAdminDoc.id}&action=deny";

        await FirebaseFirestore.instance.collection('mail').add({
          'to': ['karanthombre06@gmail.com'],
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Admin registration submitted for approval.')),
          );
          Navigator.pop(context);
        }
      } else {
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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.shield_moon_outlined,
                  size: 80, color: Colors.greenAccent),
              const SizedBox(height: 30),
              const Text(
                "Sign Up",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Create a new account. It's free!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),

              CustomTextField(
                controller: _emailController,
                labelText: "Email",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                labelText: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: "Confirm Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              // Improved Role Selection
              ToggleButtons(
                isSelected: [
                  _selectedRole == UserRole.user,
                  _selectedRole == UserRole.admin
                ],
                onPressed: (index) {
                  setState(() {
                    _selectedRole = index == 0 ? UserRole.user : UserRole.admin;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.black,
                color: Colors.white,
                fillColor: Colors.greenAccent,
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("User")),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("Admin")),
                ],
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already have an account?"),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      " Login",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.greenAccent),
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 600.ms),
        ),
      ),
    );
  }
}
