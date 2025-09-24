import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project/screens/auth/signup_screen.dart';
import 'package:flutter_project/widgets/custom_textfield.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // Pop all screens until we get back to the root (the AuthWrapper)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
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
                "Login",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Welcome back! Login to your account.",
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
              const SizedBox(height: 40),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _errorMessage!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              MaterialButton(
                minWidth: double.infinity,
                height: 60,
                onPressed: _isLoading ? null : _login,
                color: Colors.greenAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Login",
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
                  const Text("Don't have an account?"),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignupScreen()));
                    },
                    child: const Text(
                      " Sign up",
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
