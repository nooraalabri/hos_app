import 'package:flutter/material.dart';

class PendingScreen extends StatelessWidget {
  final String forRole;
  const PendingScreen({super.key, required this.forRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_bottom, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Your $forRole account is under review',
                  style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('You will be notified when an admin makes a decision.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
