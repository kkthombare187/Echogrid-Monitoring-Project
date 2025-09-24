import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({Key? key}) : super(key: key);

  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  // State variables for the form
  String? _selectedIssueType = 'Power Outage';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  final List<String> _issueTypes = ['Power Outage', 'Flickering Lights', 'Damaged Power Line', 'Other'];

  // Function to handle submitting the report
  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      // Add the report to the 'issues' collection in Firestore
      await FirebaseFirestore.instance.collection('issues').add({
        'issueType': _selectedIssueType,
        'description': _descriptionController.text.trim(),
        'reportedBy': user?.email ?? 'Unknown User',
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'submitted', // Default status
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully. Thank you!')),
        );
        Navigator.pop(context); // Go back to the previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Please provide details about the problem you are experiencing.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Dropdown for issue type
                DropdownButtonFormField<String>(
                  value: _selectedIssueType,
                  items: _issueTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedIssueType = newValue;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type of Issue',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Text field for description
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Please describe the issue in detail...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),

                // Submit button
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submitReport,
                ),
              ],
            ),
    );
  }
}

