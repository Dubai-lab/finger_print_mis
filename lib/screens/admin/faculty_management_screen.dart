import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyManagementScreen extends StatefulWidget {
  const FacultyManagementScreen({Key? key}) : super(key: key);

  @override
  _FacultyManagementScreenState createState() => _FacultyManagementScreenState();
}

class _FacultyManagementScreenState extends State<FacultyManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _facultyNameController = TextEditingController();
  final TextEditingController _facultyDescriptionController = TextEditingController();

  String? _editingFacultyId;

  // Store IDs of newly created faculties to filter them out from display
  final Set<String> _newlyCreatedFacultyIds = {};

  void _resetForm() {
    _formKey.currentState?.reset();
    _facultyNameController.clear();
    _facultyDescriptionController.clear();
    setState(() {
      _editingFacultyId = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _facultyNameController.text.trim();
    final description = _facultyDescriptionController.text.trim();

      try {
        if (_editingFacultyId != null) {
          // Remove update operation as per user request
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Editing faculties is disabled')),
          );
        } else {
          final docRef = await _firestore.collection('faculties').add({
            'name': name,
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
          });
          // Add newly created faculty ID to the set to filter it out
          setState(() {
            _newlyCreatedFacultyIds.add(docRef.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Faculty created successfully')),
          );
        }
        _resetForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save faculty: $e')),
        );
      }
  }

  void _startEditing(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _facultyNameController.text = data['name'] ?? '';
    _facultyDescriptionController.text = data['description'] ?? '';
    setState(() {
      _editingFacultyId = doc.id;
    });
  }

  Future<void> _deleteFaculty(String facultyId) async {
    try {
      await _firestore.collection('faculties').doc(facultyId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty deleted successfully')),
      );
      if (_editingFacultyId == facultyId) {
        _resetForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete faculty: $e')),
      );
    }
  }

  @override
  void dispose() {
    _facultyNameController.dispose();
    _facultyDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _facultyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Faculty Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter faculty name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _facultyDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(_editingFacultyId == null ? 'Create Faculty' : 'Update Faculty'),
                      ),
                      const SizedBox(width: 12),
                      if (_editingFacultyId != null)
                        TextButton(
                          onPressed: _resetForm,
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('faculties').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No faculties found.'));
                  }
            final filteredDocs = docs.where((doc) => !_newlyCreatedFacultyIds.contains(doc.id)).toList();
            return ListView.builder(
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(data['name'] ?? 'No Name'),
                    subtitle: Text(data['description'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _startEditing(doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteFaculty(doc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
