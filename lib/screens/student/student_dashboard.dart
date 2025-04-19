import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../provider/auth_provider.dart';
import '../../app/routes/app_routes.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _joinCourse(String courseId) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'joinedStudents': FieldValue.arrayUnion([user.uid]),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Student Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('courses').where('posted', isEqualTo: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data?.docs ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('No posted courses available.'));
          }
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final data = course.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['courseName'] ?? 'No Course Name'),
                  subtitle: Text('Instructor: ${data['instructorName'] ?? ''}\nDepartment: ${data['department'] ?? ''}'),
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
