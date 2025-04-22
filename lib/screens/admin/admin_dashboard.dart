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

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      horizontalTitleGap: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: Colors.deepPurple.shade50,
    );
  }

  Widget _buildSummaryCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        width: double.infinity,
        height: 140,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 36),
              radius: 30,
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(count.toString(), style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                ),
                child: const Center(
                  child: Text(
                    'Admin Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              ExpansionTile(
                leading: const Icon(Icons.person_add, color: Colors.deepPurple),
                title: const Text('Register User', style: TextStyle(fontWeight: FontWeight.w600)),
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
              _buildDrawerItem(Icons.book, 'Create Course', () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.createCourse);
              }),
              _buildDrawerItem(Icons.account_tree, 'Faculty Session', () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.facultyManagement);
              }),
              _buildDrawerItem(Icons.apartment, 'Department Session', () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.departmentManagement);
              }),
              _buildDrawerItem(Icons.menu_book, 'Course Session', () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.courseManagement);
              }),
              _buildDrawerItem(Icons.settings, 'Session Manager', () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.sessionManager);
              }),
              _buildDrawerItem(Icons.manage_accounts, 'Manage Course', () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.manageCourseOfferings);
              }),
              _buildDrawerItem(Icons.group, 'Manage Students', () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.manageStudents);
              }),
              _buildDrawerItem(Icons.delete, 'Delete Recently Accessed Courses', () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.deleteRecentlyAccessedCourses);
              }),
              const Divider(thickness: 1, indent: 20, endIndent: 20),
              _buildDrawerItem(Icons.logout, 'Logout', () => _logout(context)),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Summary cards row
                  // Removed Total Courses and Total Students summary cards as per user request
                  const SizedBox(height: 20),
                  // Manage Students button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.manage_accounts),
                      label: const Text('Manage Students'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white, // Ensure text and icon are white for contrast
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.manageStudents);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Courses list
                  Expanded(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('created_courses').snapshots(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: \${snapshot.error}'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final courses = snapshot.data?.docs ?? [];
                  if (courses.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final data = course.data() as Map<String, dynamic>;
                      final posted = data['posted'] ?? false;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: ListTile(
                          title: Text(data['courseName'] ?? 'No Course Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Instructor: ' + (data['instructorName'] ?? '') + '\\nDepartment: ' + (data['department'] ?? '') + '\\nPosted: ' + posted.toString()),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
