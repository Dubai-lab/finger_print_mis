import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class RecentlyAccessedCourses extends StatefulWidget {
  const RecentlyAccessedCourses({Key? key}) : super(key: key);

  @override
  State<RecentlyAccessedCourses> createState() => _RecentlyAccessedCoursesState();
}

class _RecentlyAccessedCoursesState extends State<RecentlyAccessedCourses> {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DocumentSnapshot>> _fetchJoinedCourses() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // Fetch student document to get joinedCourses list
    final studentDoc = await _firestore.collection('students').doc(user.uid).get();
    if (!studentDoc.exists) return [];

    final data = studentDoc.data() as Map<String, dynamic>? ?? {};
    final List<dynamic> joinedCourses = data['joinedCourses'] ?? [];

    if (joinedCourses.isEmpty) return [];

    // Fetch course documents for joinedCourses
    final coursesQuery = await _firestore
        .collection('courses')
        .where(FieldPath.documentId, whereIn: joinedCourses)
        .get();

    return coursesQuery.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Accessed Courses'),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchJoinedCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('No recently accessed courses found.'));
          }
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final data = course.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['courseName'] ?? 'No Course Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instructor: ' + (data['instructorName'] ?? '')),
                      Text('Department: ' + (data['department'] ?? '')),
                    ],
                  ),
                  onTap: () {
                    // TODO: Implement course access logic, e.g., navigate to course details
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
