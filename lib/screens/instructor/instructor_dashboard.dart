import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import 'profile_picture_manager.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({Key? key}) : super(key: key);

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  String? _selectedCourseId;
  bool _attendanceCreated = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfilePictureManager(),
                const SizedBox(height: 12),
                const Text(
                  'Instructor Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.deepPurple),
            title: Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.of(context).pushNamed('/instructor-profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.deepPurple),
            title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user != null ? "${user.firstName} ${user.lastName}" : "Instructor"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Courses:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('course_offerings')
                    .where('instructorId', isEqualTo: user?.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final courseOfferings = snapshot.data?.docs ?? [];
                  if (courseOfferings.isEmpty) {
                    return const Center(child: Text('No courses assigned.'));
                  }
                  return ListView.builder(
                    itemCount: courseOfferings.length,
                    itemBuilder: (context, index) {
                      final courseOffering = courseOfferings[index];
                      final data = courseOffering.data() as Map<String, dynamic>;
                      final courseId = data['courseId'] as String?;
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('department_course')
                            .doc(courseId)
                            .get(),
                        builder: (context, courseSnapshot) {
                          if (courseSnapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Loading...'),
                            );
                          }
                          if (!courseSnapshot.hasData || !courseSnapshot.data!.exists) {
                            return const ListTile(
                              title: Text('Course not found'),
                            );
                          }
                          final courseData = courseSnapshot.data!.data() as Map<String, dynamic>;
                          final courseName = courseData['name'] ?? 'Unnamed Course';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    courseName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed(
                                            '/attendance-page',
                                            arguments: {'courseOfferingId': courseOffering.id},
                                          ).then((value) {
                                            if (value == true) {
                                              setState(() {
                                                _selectedCourseId = courseOffering.id;
                                                _attendanceCreated = true;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Attendance created for \$courseName')),
                                              );
                                            }
                                          });
                                        },
                                        child: const Text('Create Attendance'),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed('/created-attendance-page');
                                        },
                                        child: const Text('View Attendance'),
                                      ),
                                  const SizedBox(height: 16),
                                      FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('attendance')
                                            .where('courseOfferingId', isEqualTo: courseOffering.id)
                                            .limit(1)
                                            .get(),
                                        builder: (context, snapshot) {
                                          final hasAttendance = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: hasAttendance
                                                    ? () {
                                                        // TODO: Implement fingerprint scanning logic here
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Fingerprint scanning started...')),
                                                        );
                                                      }
                                                    : () {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('No Attendance created')),
                                                        );
                                                      },
                                                icon: const Icon(Icons.fingerprint),
                                                label: const Text('Scan Print'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: hasAttendance ? Colors.deepPurple : Colors.grey,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.of(context).pushNamed(
                                                    '/instructor-course-students',
                                                    arguments: {'courseOfferingId': courseOffering.id},
                                                  );
                                                },
                                                icon: const Icon(Icons.group),
                                                label: const Text('View Students'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
