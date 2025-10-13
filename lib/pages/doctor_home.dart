import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Doctor')),
        body: Center(child: ElevatedButton(
            onPressed: () => AuthService.logoutAndGoWelcome(context),
            child: const Text('Logout'))));
  }
}
