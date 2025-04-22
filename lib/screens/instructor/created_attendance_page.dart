import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/auth_provider.dart';

class CreatedAttendancePage extends StatefulWidget {
  const CreatedAttendancePage({Key? key}) : super(key: key);

  @override
  State<CreatedAttendancePage> createState() => _CreatedAttendancePageState();
}

class _CreatedAttendancePageState extends State<CreatedAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _courseNames = {};
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _fetchCourseNames();
  }

  Future<void> _fetchCourseNames() async {
    try {
      final querySnapshot = await _firestore.collection('created_courses').get();
      final Map<String, String> courseMap = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('courseName')) {
          courseMap[doc.id] = data['courseName'] as String;
        }
      }
      setState(() {
        _courseNames = courseMap;
        _isLoadingCourses = false;
      });
      print('Course names loaded: \$_courseNames');
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
      print('Error fetching course names: \$e');
    }
  }

  Future<void> _deleteAttendance(String attendanceId) async {
    await _firestore.collection('attendance').doc(attendanceId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance deleted successfully')),
    );
  }

  void _editAttendance(String attendanceId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit attendance \$attendanceId - feature to be implemented')),
    );
  }

  String _formatDate(dynamic dateField) {
    try {
      if (dateField is Timestamp) {
        final dateTime = dateField.toDate();
        return DateFormat.yMMMMd().format(dateTime);
      } else if (dateField is String) {
        final dateTime = DateTime.parse(dateField);
        return DateFormat.yMMMMd().format(dateTime);
      } else {
        return 'Unknown Date';
      }
    } catch (e) {
      return 'Unknown Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Created Attendance'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(
          child: Text('User not logged in'),
        ),
      );
    }

    if (_isLoadingCourses) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Created Attendance'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Created Attendance'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('attendance')
            .where('instructorId', isEqualTo: user.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final attendanceDocs = snapshot.data?.docs ?? [];
          if (attendanceDocs.isEmpty) {
            return const Center(child: Text('No attendance records found.'));
          }
          return ListView.builder(
            itemCount: attendanceDocs.length,
            itemBuilder: (context, index) {
              final doc = attendanceDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final courseOfferingId = data['courseOfferingId'] ?? '';
              final dateField = data['date'];

              final courseName = courseOfferingId.isNotEmpty && _courseNames.containsKey(courseOfferingId)
                  ? _courseNames[courseOfferingId]!
                  : 'Unknown Course';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text("Course: \$courseName"),
                  subtitle: Text("Date: \${_formatDate(dateField)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () => _editAttendance(doc.id),
                        tooltip: 'Edit Attendance',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAttendance(doc.id),
                        tooltip: 'Delete Attendance',
                      ),
                    ],
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
