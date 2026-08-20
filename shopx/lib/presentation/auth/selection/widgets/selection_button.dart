// Helper widget to keep code clean and reusable
import 'package:flutter/material.dart';

class SelectionButton extends StatelessWidget {
  final String title;
final dynamic icon;   // can be IconData or Image widget
  final Color color;
  final VoidCallback onTap;

  const SelectionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
                const SizedBox(width: 20), // left padding for icon

           icon is IconData
    ? Icon(icon, size: 24, color: Colors.white)
    : icon is Widget
        ? icon
        : const SizedBox(),

    const SizedBox(width: 12), // gap between icon and text
            Expanded(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
        const SizedBox(width: 36), // MATCH the left icon width + padding

          ],
        ),
      ),
    );
  }
}