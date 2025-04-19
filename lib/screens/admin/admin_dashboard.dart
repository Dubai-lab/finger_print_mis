import 'package:finger_print_mis/screens/admin/instructor_register_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../provider/auth_provider.dart';
import '../../app/routes/app_routes.dart';
import 'register_page.dart';
import '../student/student_register_page.dart';
import 'create_course_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? _selectedRole;

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _onRoleSelected(String? role) {
    setState(() {
      _selectedRole = role;
    });
    if (role == 'instructor') {
      Navigator.of(context).pop(); // Close the drawer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const InstructorRegisterPage(),
        ),
      );
    } else if (role == 'invigilator' || role == 'admin') {
      Navigator.of(context).pop(); // Close the drawer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RegisterPage(),
        ),
      );
    } else if (role == 'student') {
      Navigator.of(context).pop(); // Close the drawer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const StudentRegisterPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
                'Admin Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ExpansionTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Register User'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select Role'),
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'instructor', child: Text('Instructor')),
                      DropdownMenuItem(value: 'invigilator', child: Text('Invigilator')),
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                    ],
                    onChanged: _onRoleSelected,
                  ),
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Create Course'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).pushNamed('/create-course');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree),
              title: const Text('Faculty Session'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).pushNamed('/faculty-management');
              },
            ),
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Department Session'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).pushNamed('/department-management');
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Course Session'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).pushNamed('/course-management');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Session Manager'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).pushNamed('/session-manager');
              },
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
        stream: FirebaseFirestore.instance.collection('created_courses').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data?.docs ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final data = course.data() as Map<String, dynamic>;
              final posted = data['posted'] ?? false;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['courseName'] ?? 'No Course Name'),
                  subtitle: Text('Instructor: ${data['instructorName'] ?? ''}\nDepartment: ${data['department'] ?? ''}\nPosted: $posted'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreateCoursePage(
                              courseId: course.id,
                              courseData: data,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        await FirebaseFirestore.instance.collection('created_courses').doc(course.id).delete();
                      } else if (value == 'post') {
                        await FirebaseFirestore.instance.collection('created_courses').doc(course.id).update({'posted': true});
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      if (!posted) const PopupMenuItem(value: 'post', child: Text('Post to Students')),
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
