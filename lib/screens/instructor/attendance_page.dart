import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';

class AttendancePage extends StatefulWidget {
  final String courseOfferingId;

  const AttendancePage({Key? key, required this.courseOfferingId}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime? _attendanceStartDate;
  DateTime? _attendanceEndDate;
  TimeOfDay? _attendanceEndTime;
  final TextEditingController _marksController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For editing attendance
  String? _editingAttendanceId;
  TimeOfDay? _editingEndTime;
  TextEditingController? _editingMarksController;

  Future<void> _selectAttendanceStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _attendanceStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _attendanceStartDate) {
      setState(() {
        _attendanceStartDate = picked;
        if (_attendanceEndDate != null && _attendanceEndDate!.isBefore(picked)) {
          _attendanceEndDate = null;
        }
      });
    }
  }

  Future<void> _selectAttendanceEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _attendanceEndDate ?? (_attendanceStartDate ?? DateTime.now()),
      firstDate: _attendanceStartDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _attendanceEndDate) {
      setState(() {
        _attendanceEndDate = picked;
      });
    }
  }

  Future<void> _selectAttendanceEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _attendanceEndTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _attendanceEndTime) {
      setState(() {
        _attendanceEndTime = picked;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_attendanceStartDate == null || _attendanceEndDate == null || _attendanceEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date, end date, and end time')),
      );
      return;
    }
    if (_attendanceEndDate!.isBefore(_attendanceStartDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }
    if (_marksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter attendance marks')),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;

      DateTime currentDate = _attendanceStartDate!;
      while (!currentDate.isAfter(_attendanceEndDate!)) {
        await _firestore.collection('attendance').add({
          'courseOfferingId': widget.courseOfferingId,
          'instructorId': user?.id,
          'attendanceDate': Timestamp.fromDate(currentDate),
          'attendanceEndTime': '${_attendanceEndTime!.hour}:${_attendanceEndTime!.minute}',
          'attendanceMarks': _marksController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        currentDate = currentDate.add(const Duration(days: 1));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance created successfully for selected date range')),
      );

      setState(() {
        _attendanceStartDate = null;
        _attendanceEndDate = null;
        _attendanceEndTime = null;
        _marksController.clear();
      });

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create attendance: \$e')),
      );
    }
  }

  Future<bool> createAttendanceIfNotExists(DateTime startDate, DateTime endDate, TimeOfDay endTime, String marks) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;
      if (user == null) return false;

      // Check if attendance exists for the course offering in the date range
      final querySnapshot = await _firestore
          .collection('attendance')
          .where('courseOfferingId', isEqualTo: widget.courseOfferingId)
          .where('attendanceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('attendanceDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Attendance already exists
        return true;
      }

      // Create attendance records
      DateTime currentDate = startDate;
      while (!currentDate.isAfter(endDate)) {
        await _firestore.collection('attendance').add({
          'courseOfferingId': widget.courseOfferingId,
          'instructorId': user.id,
          'attendanceDate': Timestamp.fromDate(currentDate),
          'attendanceEndTime': '${endTime.hour}:${endTime.minute}',
          'attendanceMarks': marks,
          'createdAt': FieldValue.serverTimestamp(),
        });
        currentDate = currentDate.add(const Duration(days: 1));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

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

  @override
  void dispose() {
    _marksController.dispose();
    _editingMarksController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Attendance'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: Text(_attendanceStartDate == null
                    ? 'Select Attendance Start Date'
                    : 'Start Date: ${_attendanceStartDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectAttendanceStartDate(context),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_attendanceEndDate == null
                    ? 'Select Attendance End Date'
                    : 'End Date: ${_attendanceEndDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectAttendanceEndDate(context),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_attendanceEndTime == null
                    ? 'Select Attendance End Time'
                    : 'End Time: ${_attendanceEndTime!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectAttendanceEndTime(context),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _marksController,
                decoration: const InputDecoration(
                  labelText: 'Attendance Marks',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitAttendance,
                child: const Text('Create Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
