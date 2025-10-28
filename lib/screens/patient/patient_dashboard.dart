import 'package:flutter/material.dart';
import 'patient_home_screen.dart';

/// PatientDashboard now simply redirects to PatientHomeScreen
/// Each screen (Home, Appointments, Records, Profile) now has its own
/// drawer and bottom navigation bar for better navigation control
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redirect to home screen on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
      );
    });

    // Show loading while redirecting
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

