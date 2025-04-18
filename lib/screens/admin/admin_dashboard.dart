import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../app/routes/app_routes.dart';
import 'register_page.dart';
import '../student/student_register_page.dart';

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
    if (role == 'instructor' || role == 'invigilator' || role == 'admin') {
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
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Admin Dashboard',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
