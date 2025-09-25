import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({Key? key}) : super(key: key);

  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reportController = TextEditingController();
  bool _isSubmitting = false;

  late final Stream<QuerySnapshot> _myReportsStream;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Set up the stream to fetch the user's reports
    if (_currentUser != null) {
      _myReportsStream = FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: _currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('reports').add({
          'userId': _currentUser!.uid,
          'reportText': _reportController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'new',
        });
        
        _reportController.clear(); // Clear the text field after successful submission
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
  
  Future<void> _confirmDelete(BuildContext context, String docId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this report?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                FirebaseFirestore.instance.collection('reports').doc(docId).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SUBMISSION FORM ---
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _reportController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Problem Description',
                      hintText: 'e.g., The street light on Main Street is flickering.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description of the issue.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Submit Report'),
                          onPressed: _submitReport,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                ],
              ),
            ),
            const Divider(height: 40),

            // --- SUBMITTED REPORTS LIST ---
            const Text('Your Submitted Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _currentUser == null
                  ? const Center(child: Text('Please log in to see your reports.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _myReportsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print('Error fetching reports: ${snapshot.error}'); 
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('You have no submitted reports.'));
                        }
                        
                        return ListView(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data()! as Map<String, dynamic>;
                            final formattedDate = data['timestamp'] != null
                                ? DateFormat.yMMMd().add_jm().format((data['timestamp'] as Timestamp).toDate())
                                : 'Date not available';
                            
                            return Card(
                              child: ListTile(
                                title: Text(data['reportText']),
                                subtitle: Text('Submitted on $formattedDate'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(context, doc.id),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}