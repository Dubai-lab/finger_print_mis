import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstructorCourseStudents extends StatefulWidget {
  final String courseOfferingId;

  const InstructorCourseStudents({Key? key, required this.courseOfferingId}) : super(key: key);

  @override
  _InstructorCourseStudentsState createState() => _InstructorCourseStudentsState();
}

class _InstructorCourseStudentsState extends State<InstructorCourseStudents> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudents();
  }

  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    final firestore = FirebaseFirestore.instance;

    // Get the courseId from the course_offerings document
    final courseOfferingDoc = await firestore.collection('course_offerings').doc(widget.courseOfferingId).get();
    if (!courseOfferingDoc.exists) {
      return [];
    }
    final courseOfferingData = courseOfferingDoc.data();
    if (courseOfferingData == null || courseOfferingData['courseId'] == null) {
      return [];
    }
    final courseId = courseOfferingData['courseId'] as String;

    // Query students who have joined this course by checking their joinedCourses array
    final studentsQuery = await firestore
        .collection('students')
        .where('joinedCourses', arrayContains: courseId)
        .get();

    if (studentsQuery.docs.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> students = [];

      for (final studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        students.add({
          'id': studentDoc.id,
          'firstName': studentData['firstName'] ?? '',
          'lastName': studentData['lastName'] ?? '',
          'registrationNumber': studentData['registrationNumber'] ?? 'N/A',
          'email': studentData['email'] ?? '',
        });
      }

    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Students'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('No students have joined this course.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('S/N')),
                DataColumn(label: Text('Reg. Number')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Attendance/10')),
              ],
              rows: List<DataRow>.generate(
                students.length,
                (index) {
                  final student = students[index];
                  final registrationNumber = student['registrationNumber'] ?? 'N/A';
                  final name = '${student['firstName']} ${student['lastName']}';
                  return DataRow(cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(registrationNumber)),
                    DataCell(Text(name)),
                    DataCell(Text('')), // Placeholder for Attendance/10 column
                  ]);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
