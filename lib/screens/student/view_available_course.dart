import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class ViewAvailableCourse extends StatefulWidget {
  const ViewAvailableCourse({Key? key}) : super(key: key);

  @override
  State<ViewAvailableCourse> createState() => _ViewAvailableCourseState();
}

class _ViewAvailableCourseState extends State<ViewAvailableCourse> {
  Future<void> _joinCourse(String courseId) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('courses').doc(courseId).update({
        'joinedStudents': FieldValue.arrayUnion([user.uid]),
      });
      // Update student's joinedCourses list
      await firestore.collection('students').doc(user.uid).update({
        'joinedCourses': FieldValue.arrayUnion([courseId]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined course successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join course: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Available Courses'),
        ),
        body: const Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Courses'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('posted', isEqualTo: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allCourses = snapshot.data?.docs ?? [];
          final courses = allCourses.where((course) {
            final data = course.data() as Map<String, dynamic>;
            final joinedStudents = data['joinedStudents'] as List<dynamic>? ?? [];
            return !joinedStudents.contains(user.uid);
          }).toList();

          if (courses.isEmpty) {
            return Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No Class Available !',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final data = course.data() as Map<String, dynamic>;
              return Card(
                elevation: 8,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    data['courseName'] ?? 'No Course Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Instructor: ${data['instructorName'] ?? ''}\nDepartment: ${data['department'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () => _joinCourse(course.id),
                    child: const Text('Join'),
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
