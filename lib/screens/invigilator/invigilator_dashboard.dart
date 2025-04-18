import 'package:flutter/material.dart';

class InvigilatorDashboard extends StatelessWidget {
  const InvigilatorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invigilator Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Invigilator Dashboard',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
