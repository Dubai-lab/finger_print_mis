import 'package:flutter/material.dart';

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Instructor Dashboard',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
