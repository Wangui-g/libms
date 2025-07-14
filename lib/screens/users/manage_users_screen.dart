import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: const Center(
        child: Text(
          'User management functionality will be added here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
// This screen is a placeholder for future user management functionalities.