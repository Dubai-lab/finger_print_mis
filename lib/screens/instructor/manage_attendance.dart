import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';

class ManageAttendancePage extends StatefulWidget {
  final String courseOfferingId;

  const ManageAttendancePage({Key? key, required this.courseOfferingId}) : super(key: key);

  @override
  State<ManageAttendancePage> createState() => _ManageAttendancePageState();
}

class _ManageAttendancePageState extends State<ManageAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _editingAttendanceId;
  TimeOfDay? _editingEndTime;
  TextEditingController? _editingMarksController;

  Future<void> _startEditingAttendance(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final endTimeStr = data['attendanceEndTime'] as String? ?? '00:00';
    final parts = endTimeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    setState(() {
      _editingAttendanceId = doc.id;
      _editingEndTime = TimeOfDay(hour: hour, minute: minute);
      _editingMarksController = TextEditingController(text: data['attendanceMarks'] ?? '');
    });
  }

  Future<void> _selectEditingEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _editingEndTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _editingEndTime) {
      setState(() {
        _editingEndTime = picked;
      });
    }
  }

  Future<void> _saveEditingAttendance() async {
    if (_editingAttendanceId == null || _editingEndTime == null || _editingMarksController == null) {
      return;
    }
    if (_editingMarksController!.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter attendance marks')),
      );
      return;
    }

    try {
      await _firestore.collection('attendance').doc(_editingAttendanceId).update({
        'attendanceEndTime': '${_editingEndTime!.hour}:${_editingEndTime!.minute}',
        'attendanceMarks': _editingMarksController!.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance updated successfully')),
      );

      setState(() {
        _editingAttendanceId = null;
        _editingEndTime = null;
        _editingMarksController?.dispose();
        _editingMarksController = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update attendance: \$e')),
      );
    }
  }

  Future<void> _deleteAttendance(String docId) async {
    try {
      await _firestore.collection('attendance').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete attendance: \$e')),
      );
    }
  }

  Widget _buildAttendanceList() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    print('ManageAttendancePage: userModel = \$user');
    print('ManageAttendancePage: user id = \${user?.id}');

    if (user == null || user.id == null) {
      return const Center(child: Text('User ID not found. Cannot load attendance records.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('attendance')
          .where('courseOfferingId', isEqualTo: widget.courseOfferingId)
          //.where('instructorId', isEqualTo: user.id) // temporarily removed for debugging
          .orderBy('attendanceDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: \${snapshot.error.toString()}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        print('ManageAttendancePage: fetched attendance docs count = \${docs.length}');
        if (docs.isEmpty) {
          return const Center(child: Text('No attendance records found.'));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final attendanceDate = (data['attendanceDate'] as Timestamp).toDate();
            final endTime = data['attendanceEndTime'] ?? '';
            final marks = data['attendanceMarks'] ?? '';

            final isEditing = _editingAttendanceId == doc.id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text('Date: \${attendanceDate.toLocal().toString().split(' ')[0]}'),
                subtitle: isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('End Time: '),
                              TextButton(
                                onPressed: () => _selectEditingEndTime(context),
                                child: Text(_editingEndTime?.format(context) ?? ''),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _editingMarksController,
                            decoration: const InputDecoration(labelText: 'Attendance Marks'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      )
                    : Text('End Time: \$endTime\nMarks: \$marks'),
                trailing: isEditing
                    ? SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.save, color: Colors.green),
                              onPressed: _saveEditingAttendance,
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _editingAttendanceId = null;
                                  _editingEndTime = null;
                                  _editingMarksController?.dispose();
                                  _editingMarksController = null;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _startEditingAttendance(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text('Are you sure you want to delete this attendance record?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _deleteAttendance(doc.id);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Attendance'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildAttendanceList(),
      ),
    );
  }
}
