import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({Key? key}) : super(key: key);

  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedFacultyId;
  String? _selectedDepartmentId;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _creditHourController = TextEditingController();

  String? _editingCourseId;

  void _resetForm() {
    _formKey.currentState?.reset();
    _courseNameController.clear();
    _courseCodeController.clear();
    _creditHourController.clear();
    setState(() {
      _editingCourseId = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    final name = _courseNameController.text.trim();
    final code = _courseCodeController.text.trim();
    final creditHour = int.tryParse(_creditHourController.text.trim()) ?? 0;

    try {
      if (_editingCourseId != null) {
        // Remove update operation as per user request
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editing courses is disabled')),
        );
      } else {
        await _firestore.collection('department_course').add({
          'name': name,
          'code': code,
          'creditHour': creditHour,
          'departmentId': _selectedDepartmentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course created successfully')),
        );
      }
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save course: $e')),
      );
    }
  }

  void _startEditing(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _courseNameController.text = data['name'] ?? '';
    _courseCodeController.text = data['code'] ?? '';
    _creditHourController.text = (data['creditHour'] ?? '').toString();
    setState(() {
      _editingCourseId = doc.id;
      _selectedDepartmentId = data['departmentId'];
    });
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully')),
      );
      if (_editingCourseId == courseId) {
        _resetForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete course: $e')),
      );
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _creditHourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('departments').orderBy('name').snapshots(),
              builder: (context, departmentSnapshot) {
                if (departmentSnapshot.hasError) {
                  // Hide error message from UI
                  return const SizedBox.shrink();
                }
                if (!departmentSnapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final departments = departmentSnapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Department',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDepartmentId,
                  items: departments.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'No Name'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value;
                    });
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
                    controller: _courseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Course Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter course name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _courseCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Course Code',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter course code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _creditHourController,
                    decoration: const InputDecoration(
                      labelText: 'Credit Hour',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter credit hour';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(_editingCourseId == null ? 'Add Course' : 'Update Course'),
                      ),
                      const SizedBox(width: 12),
                      if (_editingCourseId != null)
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
              child: _selectedDepartmentId == null
                  ? const Center(child: Text('Select a department to view courses'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('department_course')
                          .where('departmentId', isEqualTo: _selectedDepartmentId)
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
                          return const Center(child: Text('No courses found.'));
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
                                subtitle: Text('Code: ${data['code'] ?? ''} | Credit Hour: ${data['creditHour'] ?? ''}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _startEditing(doc),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteCourse(doc.id),
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
