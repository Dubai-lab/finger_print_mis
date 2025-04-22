import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student_model.dart';

class DeleteRecentlyAccessedCourses extends StatefulWidget {
  const DeleteRecentlyAccessedCourses({Key? key}) : super(key: key);

  @override
  State<DeleteRecentlyAccessedCourses> createState() => _DeleteRecentlyAccessedCoursesState();
}

class _DeleteRecentlyAccessedCoursesState extends State<DeleteRecentlyAccessedCourses> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedStudentId;
  List<DocumentSnapshot> _studentCourses = [];
  bool _loadingCourses = false;

  Future<List<DocumentSnapshot>> _fetchStudents() async {
    final snapshot = await _firestore.collection('students').get();
    return snapshot.docs;
  }

  Future<void> _fetchStudentCourses(String studentId) async {
    setState(() {
      _loadingCourses = true;
      _studentCourses = [];
    });

    final studentDoc = await _firestore.collection('students').doc(studentId).get();
    if (!studentDoc.exists) {
      setState(() {
        _loadingCourses = false;
      });
      return;
    }

    final data = studentDoc.data() as Map<String, dynamic>? ?? {};
    final List<dynamic> joinedCourses = data['joinedCourses'] ?? [];

    if (joinedCourses.isEmpty) {
      setState(() {
        _studentCourses = [];
        _loadingCourses = false;
      });
      return;
    }

    final coursesQuery = await _firestore
        .collection('courses')
        .where(FieldPath.documentId, whereIn: joinedCourses)
        .get();

    setState(() {
      _studentCourses = coursesQuery.docs;
      _loadingCourses = false;
    });
  }

  Future<void> _deleteCourseFromStudent(String studentId, String courseId) async {
    final studentRef = _firestore.collection('students').doc(studentId);

    await studentRef.update({
      'joinedCourses': FieldValue.arrayRemove([courseId]),
    });

    // Refresh the courses list
    await _fetchStudentCourses(studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Recently Accessed Courses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error loading students: \${snapshot.error}');
                }
                final students = snapshot.data ?? [];
                if (students.isEmpty) {
                  return const Text('No students found.');
                }
                return DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select Student'),
                  value: _selectedStudentId,
                  items: students.map((student) {
                    final studentModel = StudentModel.fromFirestore(student);
                    final regNumber = studentModel.registrationNumber.isNotEmpty ? studentModel.registrationNumber : 'No Registration Number';
                    return DropdownMenuItem<String>(
                      value: student.id,
                      child: Text(regNumber),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStudentId = value;
                    });
                    if (value != null) {
                      _fetchStudentCourses(value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            _loadingCourses
                ? const CircularProgressIndicator()
                : Expanded(
                    child: _studentCourses.isEmpty
                        ? const Text('No recently accessed courses for this student.')
                        : ListView.builder(
                            itemCount: _studentCourses.length,
                            itemBuilder: (context, index) {
                              final course = _studentCourses[index];
                              final data = course.data() as Map<String, dynamic>;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(data['courseName'] ?? 'No Course Name'),
                                  subtitle: Text('Instructor: ' + (data['instructorName'] ?? '') + '\nDepartment: ' + (data['department'] ?? '')),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      if (_selectedStudentId != null) {
                                        await _deleteCourseFromStudent(_selectedStudentId!, course.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Course deleted from student\'s recently accessed list')),
                                        );
                                      }
                                    },
                                  ),
                                ),
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
