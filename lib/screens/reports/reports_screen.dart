import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(
        child: Text(
          'Reports will be displayed here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
// This screen is a placeholder for future report functionalities.