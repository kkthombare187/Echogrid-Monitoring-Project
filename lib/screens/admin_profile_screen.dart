import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/screens/auth/welcome_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = true; // Start in loading state to fetch data

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() { _isLoading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? 'No email found';
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && docSnapshot.exists) {
        setState(() {
          _nameController.text = docSnapshot.data()?['name'] ?? '';
          _mobileController.text = docSnapshot.data()?['mobile'] ?? '';
        });
      }
    }
    if (mounted) setState(() { _isLoading = false; });
  }

  Future<void> _updateProfile() async {
    setState(() { _isLoading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'mobile': _mobileController.text.trim(),
        }, SetOptions(merge: true));

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile details saved successfully!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save details: $e')));
      }
    }
    if (mounted) setState(() { _isLoading = false; });
  }
  
  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset link sent to your email.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send reset email: ${e.toString()}')),
          );
        }
      }
    }
  }

  // --- NEW: LOGOUT FUNCTION ---
  Future<void> _logout() async {
    if (!mounted) return;
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold and AppBar have been removed to fit into the dashboard view
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.greenAccent,
                  child: Icon(Icons.admin_panel_settings, size: 70, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Administrator',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  'Role: Admin',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'Full Name', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email Address', Icons.email, readOnly: true),
              const SizedBox(height: 16),
              _buildTextField(_mobileController, 'Mobile Number', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
              const Divider(height: 40),
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Change Password'),
                onTap: _changePassword,
              ),
              const Divider(),
              // --- NEW: LOGOUT BUTTON ---
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                onTap: _logout,
              ),
            ],
          );
  }

  // Helper Widget for text fields
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, bool readOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.grey : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade800 : null,
      ),
    );
  }
}

