import 'package:flutter/material.dart';

Widget buildInputGroup(
  String label,
  TextEditingController controller,
  VoidCallback onChanged, {
  bool isPhone = false,
  int maxLines = 1,
  String? errorText, // ⭐ NEW
}) {
  final hasError = errorText != null;

  return Padding(
    padding: const EdgeInsets.only(bottom: 20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        // INPUT CONTAINER
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red : Colors.transparent, // ⭐ RED BORDER
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),

        // ERROR TEXT
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    ),
  );
}
