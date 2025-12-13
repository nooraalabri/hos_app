import 'package:flutter/material.dart';

class AppColors {
  static const dark = Color(0xFF2C4C56);
  static const mid = Color(0xFF5F7E86);
  static const light = Color(0xFFDDE6EA);
  static const white = Colors.white;
  static const primary = Color(0xFF5F7E86);
}

// --------------------------------------------------
// APP SCAFFOLD
// --------------------------------------------------

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? drawer;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.dark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      drawer: drawer,
      body: SafeArea(child: body),
    );
  }
}

// --------------------------------------------------
// PRIMARY CARD
// --------------------------------------------------

class PrimaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const PrimaryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withOpacity(0.10),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          child: child,
        ),
      ),
    );
  }
}

// --------------------------------------------------
// PRIMARY BUTTON
// --------------------------------------------------

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool filled;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? AppColors.primary : AppColors.white,
        foregroundColor: filled ? AppColors.white : AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary, width: filled ? 0 : 1.5),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: filled ? AppColors.white : AppColors.primary,
        ),
      ),
    );
  }
}

// --------------------------------------------------
// INPUT FIELD
// --------------------------------------------------

InputDecoration input(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.mid),
  filled: true,
  fillColor: AppColors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
);

// --------------------------------------------------
// CARD TILE (THE FIX YOU ASKED FOR ❤️)
// --------------------------------------------------

class CardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final IconData icon;
  final VoidCallback onAction;

  const CardTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.dark, // ← اللون واضح
            size: 42,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              "$title\n$subtitle",
              style: const TextStyle(
                color: AppColors.dark,    // ← النص واضح داخل الكارد
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 12),

          PrimaryButton(
            text: actionText,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
