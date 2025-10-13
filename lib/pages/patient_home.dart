import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient')),
      body: Center(
        child: ElevatedButton(
            onPressed: () => AuthService.logoutAndGoWelcome(context),
            child: const Text('Logout')),
      ),
    );
  }
}
