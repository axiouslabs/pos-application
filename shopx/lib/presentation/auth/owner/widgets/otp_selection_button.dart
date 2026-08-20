// --- Helper Widget for OTP Selection Buttons ---
import 'package:flutter/material.dart';

class OtpSelectionButton extends StatelessWidget {
  final String label;
  final dynamic icon; // can be IconData or Widget
  final bool isSelected;
  final VoidCallback onTap;

  const OtpSelectionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF1976D2);
    const unselectedBgColor = Color(0xFFF3F4F6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            icon is IconData
                ? Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.black87,
                    size: 20,
                  )
                : icon is Widget
                ? icon
                : const SizedBox(),

            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
