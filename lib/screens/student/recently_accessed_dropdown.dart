import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class RecentlyAccessedDropdown extends StatefulWidget {
  const RecentlyAccessedDropdown({Key? key}) : super(key: key);

  @override
  State<RecentlyAccessedDropdown> createState() => _RecentlyAccessedDropdownState();
}

class _RecentlyAccessedDropdownState extends State<RecentlyAccessedDropdown> {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _courses = [];
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _loadJoinedCourses();
  }

  Future<void> _loadJoinedCourses() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _courses = [];
        _selectedCourseId = null;
      });
      return;
    }

    final studentDoc = await _firestore.collection('students').doc(user.uid).get();
    if (!studentDoc.exists) {
      setState(() {
        _courses = [];
        _selectedCourseId = null;
      });
      return;
    }

    final data = studentDoc.data() as Map<String, dynamic>? ?? {};
    final List<dynamic> joinedCourses = data['joinedCourses'] ?? [];

    if (joinedCourses.isEmpty) {
      setState(() {
        _courses = [];
        _selectedCourseId = null;
      });
      return;
    }

    final coursesQuery = await _firestore
        .collection('courses')
        .where(FieldPath.documentId, whereIn: joinedCourses)
        .get();

    setState(() {
      _courses = coursesQuery.docs;
      if (_courses.isNotEmpty) {
        _selectedCourseId = _courses[0].id;
      }
    });
  }

  Map<String, dynamic>? _selectedCourseData;

  @override
  Widget build(BuildContext context) {
    if (_courses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          isExpanded: true,
          value: _selectedCourseId,
          items: _courses.map((course) {
            final data = course.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: course.id,
              child: Text(data['courseName'] ?? 'No Course Name'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCourseId = value;
              _selectedCourseData = _courses.firstWhere(
                (course) => course.id == value,
                orElse: () => _courses.first,
              ).data() as Map<String, dynamic>?;
            });
          },
        ),
        const SizedBox(height: 12),
        if (_selectedCourseData != null) ...[
          Text('Instructor: ${_selectedCourseData!['instructorName'] ?? 'N/A'}'),
          Text('Start Date: ${_formatDate(_selectedCourseData!['startDate'])}'),
          Text('End Date: ${_formatDate(_selectedCourseData!['endDate'])}'),
        ],
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Invalid date';
      }
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
