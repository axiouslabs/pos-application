// --- HELPER WIDGET FOR MENU ITEMS ---
import 'package:flutter/material.dart';

class DrawerMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const DrawerMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white24,
      highlightColor: Colors.transparent,
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}