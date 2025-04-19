import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateCoursePage extends StatefulWidget {
  final String? courseId;
  final Map<String, dynamic>? courseData;

  const CreateCoursePage({Key? key, this.courseId, this.courseData}) : super(key: key);

  @override
  _CreateCoursePageState createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  String? _selectedInstructorId;
  String? _selectedDepartmentId;
  String? _selectedCourseId;

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date cannot be after end date')),
      );
      return;
    }

    if (_selectedInstructorId == null ||
        _selectedDepartmentId == null ||
        _selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select instructor, department, and course')),
      );
      return;
    }

    try {
      await _firestore.collection('course_offerings').add({
        'instructorId': _selectedInstructorId,
        'departmentId': _selectedDepartmentId,
        'courseId': _selectedCourseId,
        'startDate': _startDate,
        'endDate': _endDate,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course offering created successfully')),
      );
      _formKey.currentState?.reset();
      setState(() {
        _selectedInstructorId = null;
        _selectedDepartmentId = null;
        _selectedCourseId = null;
        _startDate = null;
        _endDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create course offering: \$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Course Offering'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('instructors').orderBy('firstName').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading instructors');
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final instructors = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Instructor',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedInstructorId,
                    items: instructors.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text('${data['firstName'] ?? ''} ${data['middleName'] ?? ''} ${data['lastName'] ?? ''}'.trim()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedInstructorId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select an instructor' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('departments').orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading departments');
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final departments = snapshot.data!.docs;
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
                        _selectedCourseId = null; // reset course selection
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a department' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_selectedDepartmentId != null)
                StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('department_course')
                    .where('departmentId', isEqualTo: _selectedDepartmentId)
                    //.orderBy('name') // Removed to avoid Firestore composite index error
                    .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading courses');
                    }
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final courses = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCourseId,
                      items: courses.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(data['name'] ?? 'No Name'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourseId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a course' : null,
                    );
                  },
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate == null
                              ? 'Select start date'
                              : '${_startDate!.toLocal()}'.split(' ')[0],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endDate == null
                              ? 'Select end date'
                              : '${_endDate!.toLocal()}'.split(' ')[0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Create Course Offering'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
