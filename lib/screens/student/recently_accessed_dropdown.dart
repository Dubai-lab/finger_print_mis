import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class RecentlyAccessedDropdown extends StatefulWidget {
  const RecentlyAccessedDropdown({Key? key}) : super(key: key);

  @override
  State<RecentlyAccessedDropdown> createState() => _RecentlyAccessedDropdownState();
}

class _RecentlyAccessedDropdownState extends State<RecentlyAccessedDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('User not logged in');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: const Text(
            'Recently accessed course',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue),
          ),
        ),
        if (_isExpanded)
          SizedBox(
            height: 200,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .where('joinedStudents', arrayContains: user.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final courses = snapshot.data?.docs ?? [];
                if (courses.isEmpty) {
                  return const Text('No recently accessed courses.');
                }
                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final data = course.data() as Map<String, dynamic>;

                    // Extract date range if available, else empty string
                    String dateRange = '';
                    if (data.containsKey('startDate') && data.containsKey('endDate')) {
                      dateRange = '${data['startDate']}~${data['endDate']}';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['courseName'] ?? 'No Course Name',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '— ${data['instructorName'] ?? ''}',
                              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateRange,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
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
    );
  }
}
