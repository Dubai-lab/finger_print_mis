import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCourseOfferingsPage extends StatefulWidget {
  const ManageCourseOfferingsPage({Key? key}) : super(key: key);

  @override
  _ManageCourseOfferingsPageState createState() => _ManageCourseOfferingsPageState();
}

class _ManageCourseOfferingsPageState extends State<ManageCourseOfferingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Course Offerings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('course_offerings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No course offerings found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'No Name';
              final noteId = data['noteId'] ?? 'No Note ID';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: FutureBuilder(
                  future: Future.wait([
                    _firestore.collection('instructors').doc(data['instructorId']).get(),
                    _firestore.collection('departments').doc(data['departmentId']).get(),
                    _firestore.collection('department_course').doc(data['courseId']).get(),
                  ]),
                  builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Loading...'),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return ListTile(
                        title: Text(name),
                        subtitle: const Text('Error loading related data'),
                      );
                    }
                    final instructorDoc = snapshot.data![0];
                    final departmentDoc = snapshot.data![1];
                    final courseDoc = snapshot.data![2];
                    final instructorData = instructorDoc.data() as Map<String, dynamic>? ?? {};
                    final departmentData = departmentDoc.data() as Map<String, dynamic>? ?? {};
                    final courseData = courseDoc.data() as Map<String, dynamic>? ?? {};
                    final instructorName = '${instructorData['firstName'] ?? ''} ${instructorData['middleName'] ?? ''} ${instructorData['lastName'] ?? ''}'.trim();
                    final departmentName = departmentData['name'] ?? 'N/A';
                    final courseName = courseData['name'] ?? 'N/A';
                      String startDateStr = '';
                      String endDateStr = '';
                      if (data['startDate'] != null) {
                        final startDate = (data['startDate'] as Timestamp).toDate();
                        startDateStr = '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
                      }
                      if (data['endDate'] != null) {
                        final endDate = (data['endDate'] as Timestamp).toDate();
                        endDateStr = '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
                      }
                      return ListTile(
                        title: Text(courseName),
                        subtitle: Text('Instructor: $instructorName\nStart Date: $startDateStr, End Date: $endDateStr'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final TextEditingController nameController = TextEditingController(text: name);
                                    final TextEditingController noteIdController = TextEditingController(text: noteId);
                                    final _formKey = GlobalKey<FormState>();
                                    return AlertDialog(
                                      title: const Text('Edit Course Offering'),
                                      content: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextFormField(
                                              controller: nameController,
                                              decoration: const InputDecoration(labelText: 'Name'),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter a name';
                                                }
                                                return null;
                                              },
                                            ),
                                            TextFormField(
                                              controller: noteIdController,
                                              decoration: const InputDecoration(labelText: 'Note ID'),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter a note ID';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            if (_formKey.currentState?.validate() ?? false) {
                                              await _firestore.collection('course_offerings').doc(doc.id).update({
                                                'name': nameController.text.trim(),
                                                'noteId': noteIdController.text.trim(),
                                              });
                                              Navigator.of(context).pop();
                                            }
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text('Are you sure you want to delete this course offering?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _firestore.collection('course_offerings').doc(doc.id).delete();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () async {
                                try {
                                  // Get course offering data
                                  final courseOfferingDoc = await _firestore.collection('course_offerings').doc(doc.id).get();
                                  final courseOfferingData = courseOfferingDoc.data();
                                  if (courseOfferingData == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Course offering data not found')),
                                    );
                                    return;
                                  }
                                  // Prepare data for 'courses' collection
                                  final instructorDoc = await _firestore.collection('instructors').doc(courseOfferingData['instructorId']).get();
                                  final instructorData = instructorDoc.data() as Map<String, dynamic>? ?? {};
                                  final instructorName = '${instructorData['firstName'] ?? ''} ${instructorData['middleName'] ?? ''} ${instructorData['lastName'] ?? ''}'.trim();
                                  final departmentDoc = await _firestore.collection('departments').doc(courseOfferingData['departmentId']).get();
                                  final departmentData = departmentDoc.data() as Map<String, dynamic>? ?? {};
                                  final departmentName = departmentData['name'] ?? 'N/A';
                                  final courseDoc = await _firestore.collection('department_course').doc(courseOfferingData['courseId']).get();
                                  final courseData = courseDoc.data() as Map<String, dynamic>? ?? {};
                                  final courseName = courseData['name'] ?? 'N/A';

                                  final courseDataToPost = {
                                    'courseName': courseName,
                                    'instructorId': courseOfferingData['instructorId'],
                                    'instructorName': instructorName,
                                    'departmentId': courseOfferingData['departmentId'],
                                    'department': departmentName,
                                    'posted': true,
                                    'startDate': courseOfferingData['startDate'],
                                    'endDate': courseOfferingData['endDate'],
                                    'createdAt': courseOfferingData['createdAt'],
                                  };

                                  // Add or update course in 'courses' collection with courseId as doc id
                                  await _firestore.collection('courses').doc(courseOfferingData['courseId']).set(courseDataToPost);

                                  // Update posted field in course_offerings
                                  await _firestore.collection('course_offerings').doc(doc.id).update({
                                    'posted': true,
                                    'pendingStudents': {}, // Initialize empty map for pending students
                                  });

                                  // Fetch all students to add them to pendingStudents with current timestamp
                                  final studentsSnapshot = await _firestore.collection('students').get();
                                  Map<String, dynamic> pendingStudentsMap = {};
                                  final now = DateTime.now().toUtc();
                                  for (var studentDoc in studentsSnapshot.docs) {
                                    pendingStudentsMap[studentDoc.id] = now;
                                  }
                                  // Update course_offerings with pendingStudents map
                                  await _firestore.collection('course_offerings').doc(doc.id).update({
                                    'pendingStudents': pendingStudentsMap,
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Course offering posted to students')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to post course offering: $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
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
