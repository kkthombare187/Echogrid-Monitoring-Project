import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Controllers for the text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = true; // Start in loading state to fetch data

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fetch existing user data from Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? 'No email found';
      try {
        final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && docSnapshot.exists) {
          _nameController.text = docSnapshot.data()?['name'] ?? '';
          _mobileController.text = docSnapshot.data()?['mobile'] ?? '';
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
    if (mounted) setState(() { _isLoading = false; });
  }

  // Function to save the updated name and mobile number
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

  // Function to send a password reset email
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

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This screen content is displayed inside the UserDashboardScreen
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadUserData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.cyan,
                    child: Icon(Icons.person, size: 70, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'Community Member',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    'Role: User',
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
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _updateProfile,
                  child: const Text('Save Changes'),
                ),
                const Divider(height: 40),
                ListTile(
                  leading: const Icon(Icons.lock_reset_outlined),
                  title: const Text('Change Password'),
                  subtitle: const Text('Send a password reset link to your email'),
                  onTap: _changePassword,
                ),
              ],
            ),
          );
  }

  // Helper Widget for text fields
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, bool readOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.grey : null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.withOpacity(0.1) : null,
      ),
    );
  }
}

