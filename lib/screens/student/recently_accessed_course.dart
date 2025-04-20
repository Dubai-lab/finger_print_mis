import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class RecentlyAccessedCourse extends StatefulWidget {
  const RecentlyAccessedCourse({Key? key}) : super(key: key);

  @override
  State<RecentlyAccessedCourse> createState() => _RecentlyAccessedCourseState();
}

class _RecentlyAccessedCourseState extends State<RecentlyAccessedCourse> {
  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Accessed Courses'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('joinedStudents', arrayContains: user.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data?.docs ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('No recently accessed courses.'));
          }
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final data = course.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('course_offerings').doc(data['courseId']).get(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> offeringSnapshot) {
                    if (offeringSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Loading...'),
                      );
                    }
                    if (offeringSnapshot.hasError || !offeringSnapshot.hasData || !offeringSnapshot.data!.exists) {
                      return ListTile(
                        title: Text(data['courseName'] ?? 'No Course Name'),
                        subtitle: Text(
                          'Instructor: ${data['instructorName'] ?? ''}\n'
                          'Department: ${data['department'] ?? ''}\n'
                          'Start Date: N/A\n'
                          'End Date: N/A',
                        ),
                        isThreeLine: true,
                      );
                    }
                    final offeringData = offeringSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                    String startDateStr = 'N/A';
                    String endDateStr = 'N/A';
                    if (offeringData['startDate'] != null && offeringData['startDate'] is Timestamp) {
                      final Timestamp startTimestamp = offeringData['startDate'] as Timestamp;
                      final DateTime startDate = startTimestamp.toDate();
                      startDateStr = '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
                    }
                    if (offeringData['endDate'] != null && offeringData['endDate'] is Timestamp) {
                      final Timestamp endTimestamp = offeringData['endDate'] as Timestamp;
                      final DateTime endDate = endTimestamp.toDate();
                      endDateStr = '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
                    }
                    return ListTile(
                      title: Text(data['courseName'] ?? 'No Course Name'),
                      subtitle: Text(
                        'Instructor: ${data['instructorName'] ?? ''}\n'
                        'Department: ${data['department'] ?? ''}\n'
                        'Start Date: $startDateStr\n'
                        'End Date: $endDateStr',
                      ),
                      isThreeLine: true,
                    );
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
