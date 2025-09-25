import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project/screens/user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _currentAdminRole = 'admin';

  @override
  void initState() {
    super.initState();
    _fetchCurrentAdminRole();
  }

  Future<void> _fetchCurrentAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        setState(() {
          _currentAdminRole = doc.data()?['role'] ?? 'admin';
        });
      }
    }
  }

  // This function shows the advanced options menu
  void _showUserOptions(BuildContext context, String targetUserId, String targetUserName, String targetUserRole) {
    if (targetUserId == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You cannot perform actions on your own account.")));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('View Profile / Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetailScreen(userId: targetUserId)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('View User Activity Logs'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Activity log feature coming soon!")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Send Email'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email feature coming soon!")));
              },
            ),
            // Delete User option with permission check
            if ((_currentAdminRole == 'superadmin') || (_currentAdminRole == 'admin' && targetUserRole == 'user'))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete User Permanently', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteUser(context, targetUserId, targetUserName);
                },
              ),
          ],
        );
      },
    );
  }

  // --- Delete functions ---
  void _confirmDeleteUser(BuildContext context, String userId, String userName) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text('Are you sure you want to delete the user "$userName"? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteUser(userId);
                  },
                ),
              ],
            ));
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully.")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete user: $e")));
    }
  }

  // --- Helper to get the correct icon and color for each role ---
  Widget _getRoleIcon(String role) {
    IconData icon;
    Color color;
    switch (role) {
      case 'superadmin':
        icon = Icons.verified_user;
        color = Colors.amber;
        break;
      case 'admin':
        icon = Icons.admin_panel_settings;
        color = Colors.greenAccent;
        break;
      default:
        icon = Icons.person;
        color = Colors.cyan;
    }
    return Icon(icon, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Something went wrong.'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No users found.'));

          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final user = userDoc.data() as Map<String, dynamic>;
              final role = user['role'] ?? 'user';
              final name = user['name'] ?? 'No name';
              final email = user['email'] ?? 'No email';
              final userId = userDoc.id;

              return Card(
                color: Colors.grey.shade800,
                child: ListTile(
                  leading: _getRoleIcon(role),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showUserOptions(context, userId, name, role),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

