import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({Key? key}) : super(key: key);

  @override
  _DepartmentManagementScreenState createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedFacultyId;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _departmentNameController = TextEditingController();

  String? _editingDepartmentId;

  void _resetForm() {
    _formKey.currentState?.reset();
    _departmentNameController.clear();
    setState(() {
      _editingDepartmentId = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFacultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a faculty')),
      );
      return;
    }

    final name = _departmentNameController.text.trim();

    try {
      if (_editingDepartmentId != null) {
        // Update existing department
        await _firestore.collection('departments').doc(_editingDepartmentId).update({
          'name': name,
          'facultyId': _selectedFacultyId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department updated successfully')),
        );
      } else {
        // Create new department
        await _firestore.collection('departments').add({
          'name': name,
          'facultyId': _selectedFacultyId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department created successfully')),
        );
      }
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save department: $e')),
      );
    }
  }

  void _startEditing(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _departmentNameController.text = data['name'] ?? '';
    setState(() {
      _editingDepartmentId = doc.id;
      _selectedFacultyId = data['facultyId'];
    });
  }

  Future<void> _deleteDepartment(String departmentId) async {
    try {
      await _firestore.collection('departments').doc(departmentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department deleted successfully')),
      );
      if (_editingDepartmentId == departmentId) {
        _resetForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete department: $e')),
      );
    }
  }

  @override
  void dispose() {
    _departmentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('faculties').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Hide error message from UI
                  return const SizedBox.shrink();
                }
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final faculties = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Faculty',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedFacultyId,
                  items: faculties.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'No Name'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFacultyId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a faculty';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _departmentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Department Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter department name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(_editingDepartmentId == null ? 'Add Department' : 'Update Department'),
                      ),
                      const SizedBox(width: 12),
                      if (_editingDepartmentId != null)
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
              child: _selectedFacultyId == null
                  ? const Center(child: Text('Select a faculty to view departments'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('departments')
                          .where('facultyId', isEqualTo: _selectedFacultyId)
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          // Hide error message from UI
                          return const SizedBox.shrink();
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No departments found.'));
                        }
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(data['name'] ?? 'No Name'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _startEditing(doc),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteDepartment(doc.id),
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
