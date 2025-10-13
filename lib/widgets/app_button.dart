import 'package:flutter/material.dart';
import '../theme.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool filled;
  const AppButton({super.key, required this.text, required this.onPressed, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? AppTheme.dark : Colors.transparent,
        foregroundColor: filled ? Colors.white : AppTheme.dark,
        minimumSize: const Size(180, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.dark, width: filled ? 0 : 1.4),
        ),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
    );
  }
}
