import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student_model.dart';
import '../../app/routes/app_routes.dart';

class ManageStudentPage extends StatefulWidget {
  const ManageStudentPage({Key? key}) : super(key: key);

  @override
  State<ManageStudentPage> createState() => _ManageStudentPageState();
}

class _ManageStudentPageState extends State<ManageStudentPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  StudentModel? _selectedStudent;
  Map<String, dynamic>? _selectedStudentData;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteStudent(String studentId) async {
    try {
      await FirebaseFirestore.instance.collection('students').doc(studentId).delete();
      if (_selectedStudent != null && _selectedStudent!.id == studentId) {
        setState(() {
          _selectedStudent = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete student: $e')),
      );
    }
  }

  Future<void> _joinStudentToCourse(String studentId, String courseId) async {
    try {
      final studentRef = FirebaseFirestore.instance.collection('students').doc(studentId);
      await studentRef.update({
        'joinedCourses': FieldValue.arrayUnion([courseId]),
        'recentlyAccessedClasses': FieldValue.arrayUnion([courseId]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student joined to course successfully')),
      );
      // Refresh selected student data
      await _fetchStudentDetails(studentId);
      setState(() {}); // Force UI update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join student to course: $e')),
      );
    }
  }

  Future<void> _deleteRecentlyAccessedClass(String studentId, String classId) async {
    try {
      final studentRef = FirebaseFirestore.instance.collection('students').doc(studentId);
      await studentRef.update({
        'recentlyAccessedClasses': FieldValue.arrayRemove([classId]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recently accessed class deleted successfully')),
      );
      // Refresh selected student data
      _fetchStudentDetails(studentId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recently accessed class: $e')),
      );
    }
  }

  Future<void> _fetchStudentDetails(String studentId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance.collection('students').doc(studentId).get();
      if (doc.exists) {
        setState(() {
          _selectedStudent = StudentModel.fromFirestore(doc);
          _selectedStudentData = doc.data() as Map<String, dynamic>?;
          _nameController.text = _selectedStudentData?['name'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch student details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: \${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.data?.docs ?? [];
        final filteredStudents = students.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final regNum = data['registrationNumber'] ?? '';
          return regNum.toString().toLowerCase().contains(_searchText.toLowerCase());
        }).toList();

        if (filteredStudents.isEmpty) {
          return const Center(child: Text('No students found.'));
        }

        return ListView.builder(
          itemCount: filteredStudents.length,
          itemBuilder: (context, index) {
            final doc = filteredStudents[index];
            final data = doc.data() as Map<String, dynamic>;
            final regNum = data['registrationNumber'] ?? '';
            // Compose full name from available fields or fallback to 'name'
            String name = '';
            if (data.containsKey('firstName') || data.containsKey('lastName')) {
              final firstName = data['firstName'] ?? '';
              final lastName = data['lastName'] ?? '';
              name = (firstName + ' ' + lastName).trim();
            }
            if (name.isEmpty) {
              name = data['name'] ?? 'No Name';
            }
            return ListTile(
              subtitle: Text('Reg#: $regNum'),
              selected: _selectedStudent?.id == doc.id,
              onTap: () => _fetchStudentDetails(doc.id),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteStudent(doc.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentDetails() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_selectedStudent == null) {
      return const Center(child: Text('Select a student to view details.'));
    }
    final student = _selectedStudent!;
    final recentlyAccessed = student.recentlyAccessedClasses ?? [];
    final data = _selectedStudentData;

    String displayName = '';
    if (data != null) {
      if (data.containsKey('firstName') || data.containsKey('lastName')) {
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        displayName = (firstName + ' ' + lastName).trim();
      } else if (data.containsKey('name')) {
        displayName = data['name'];
      }
    }
    if (displayName.isEmpty) {
      displayName = 'No Name Available';
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: $displayName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Registration Number: ${student.registrationNumber}'),
          const SizedBox(height: 12),
          const Text('Recently Accessed Courses:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (recentlyAccessed.isEmpty)
            const Text('No recently accessed courses.'),
          ...recentlyAccessed.map((classId) => FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('course_offerings').doc(classId).get(),
                builder: (context, offeringSnapshot) {
                  if (offeringSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  if (!offeringSnapshot.hasData || !offeringSnapshot.data!.exists) {
                    return ListTile(
                      title: Text('Unknown Course Offering ($classId)'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRecentlyAccessedClass(student.id!, classId),
                      ),
                    );
                  }
                  final offeringData = offeringSnapshot.data!.data() as Map<String, dynamic>?;
                  final courseId = offeringData?['courseId'];
                  if (courseId == null) {
                    return ListTile(
                      title: Text('Unknown Course for Offering ($classId)'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRecentlyAccessedClass(student.id!, classId),
                      ),
                    );
                  }
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('department_course').doc(courseId).get(),
                    builder: (context, courseSnapshot) {
                      if (courseSnapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          title: Text('Loading...'),
                        );
                      }
                      if (!courseSnapshot.hasData || !courseSnapshot.data!.exists) {
                        return ListTile(
                          title: Text('Unknown Course ($courseId)'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRecentlyAccessedClass(student.id!, classId),
                          ),
                        );
                      }
                      final courseData = courseSnapshot.data!.data() as Map<String, dynamic>?;
                      final courseName = courseData?['name'] ?? 'Unnamed Course';
                      return ListTile(
                        title: Text(courseName),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRecentlyAccessedClass(student.id!, classId),
                        ),
                      );
                    },
                  );
                },
              )),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showJoinCourseDialog(student.id!),
            child: const Text('Join Student to Course'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _courseOfferingsWithNames = [];

  Future<void> _fetchCourseOfferingsWithNames() async {
    final courseOfferingsSnapshot = await FirebaseFirestore.instance.collection('course_offerings').get();
    List<Map<String, dynamic>> tempList = [];
    for (var doc in courseOfferingsSnapshot.docs) {
      final data = doc.data();
      final courseId = data['courseId'];
      String courseName = 'Unnamed Course';
      if (courseId != null) {
        final courseDoc = await FirebaseFirestore.instance.collection('department_course').doc(courseId).get();
        if (courseDoc.exists) {
          final courseData = courseDoc.data();
          courseName = courseData?['name'] ?? 'Unnamed Course';
        }
      }
      tempList.add({
        'id': doc.id,
        'courseName': courseName,
      });
    }
    setState(() {
      _courseOfferingsWithNames = tempList;
    });
  }

  void _showJoinCourseDialog(String studentId) {
    selectedCourseId = null;
    _fetchCourseOfferingsWithNames().then((_) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Join Student to Course'),
                content: _courseOfferingsWithNames.isEmpty
                    ? const Text('No courses available.')
                    : DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCourseId,
                        hint: const Text('Select a course'),
                        items: _courseOfferingsWithNames
                            .map((course) => DropdownMenuItem<String>(
                                  value: course['id'],
                                  child: Text(course['courseName']),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedCourseId = value;
                          });
                        },
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedCourseId != null) {
                        _joinStudentToCourse(studentId, selectedCourseId!);
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Join'),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  String? selectedCourseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
      ),
      body: Row(
        children: [
          Flexible(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by Registration Number',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(child: _buildStudentList()),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Flexible(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildStudentDetails(),
            ),
          ),
        ],
      ),
    );
  }
}
