import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../provider/auth_provider.dart';
import '../../app/routes/app_routes.dart';
import 'view_available_course.dart';
import 'recently_accessed_dropdown.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _showRecentlyAccessed = false;

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // New design widget added here
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Student Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 4),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=3',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('students')
                            .doc(fb_auth.FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            );
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text(
                              'Unknown Registration Number',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            );
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final regNum = data?['registrationNumber'] ?? 'No Reg Number';
                          return Text(
                            regNum,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('students')
                                .doc(fb_auth.FirebaseAuth.instance.currentUser?.uid)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  'Loading...',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                );
                              }
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return const Text(
                                  'Unknown Name',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                );
                              }
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              final firstName = data?['firstName'] ?? '';
                              final lastName = data?['lastName'] ?? '';
                              final fullName = (firstName + ' ' + lastName).trim();
                              return Text(
                                fullName.isEmpty ? 'No Name' : fullName,
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                            onPressed: () {
                              // TODO: Implement edit profile name
                            },
                          ),
                        ],
                      ),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('students')
                            .doc(fb_auth.FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            );
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text(
                              'Unknown Campus',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            );
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final campus = data?['campus'] ?? 'No Campus';
                          final campusText = '$campus Campus';
                          return Text(
                            campusText,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        ),
                        child: const Text('Logout'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('students')
                            .doc(fb_auth.FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildInfoRow('Faculty', 'Loading...');
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return _buildInfoRow('Faculty', 'Unknown Faculty');
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final faculty = data?['faculty'] ?? 'No Faculty';
                          return _buildInfoRow('Faculty', faculty);
                        },
                      ),
                      const Divider(),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('students')
                            .doc(fb_auth.FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildInfoRow('Programme', 'Loading...');
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return _buildInfoRow('Programme', 'Unknown Programme');
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final programme = data?['programme'] ?? 'No Programme';
                          return _buildInfoRow('Programme', programme);
                        },
                      ),
                      const Divider(),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('students')
                            .doc(fb_auth.FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildInfoRow('Department', 'Loading...', isLast: true);
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return _buildInfoRow('Department', 'Unknown Department', isLast: true);
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final department = data?['department'] ?? 'No Department';
                          return _buildInfoRow('Department', department, isLast: true);
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Tuition Fee Due',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '0',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement Installments action
                            },
                            icon: const Icon(Icons.list_alt, color: Colors.black),
                            label: const Text(
                              'Installments',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement Pay History action
                            },
                            icon: const Icon(Icons.list_alt, color: Colors.black),
                            label: const Text(
                              'Pay History',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'My Class',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.studentAvailableCourses);
                          },
                          child: const Text(
                            'View Available Class',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showRecentlyAccessed = true;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Recently Accessed Classes',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(width: 8),
                              Text('👍', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                      if (_showRecentlyAccessed) ...[
                        const SizedBox(height: 12),
                        const RecentlyAccessedDropdown(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
