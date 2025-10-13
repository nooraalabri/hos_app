import 'package:flutter/material.dart';
import '../theme.dart';
import '../routes.dart';
import '../widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_turned_in_outlined, size: 140, color: Color(0xFF9AAAB2)),
                const SizedBox(height: 24),
                Text('Hospital appointment', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 28),
                AppButton(text: 'login', onPressed: () => Navigator.pushNamed(context, AppRoutes.login)),
                const SizedBox(height: 16),
                AppButton(text: 'sign up', filled: false, onPressed: () => Navigator.pushNamed(context, AppRoutes.selectRole)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
