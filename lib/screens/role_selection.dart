import 'package:flutter/material.dart';
import '../routes.dart';
import '../widgets/app_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_turned_in_outlined, size: 120, color: Color(0xFF9AAAB2)),
              const SizedBox(height: 16),
              AppButton(text: 'Hospital', onPressed: () => Navigator.pushNamed(context, AppRoutes.regHospital)),
              const SizedBox(height: 12),
              AppButton(text: 'Doctor', onPressed: () => Navigator.pushNamed(context, AppRoutes.regDoctor)),
              const SizedBox(height: 12),
              AppButton(text: 'patient', onPressed: () => Navigator.pushNamed(context, AppRoutes.regPatient)),
            ],
          ),
        ),
      ),
    );
  }
}
