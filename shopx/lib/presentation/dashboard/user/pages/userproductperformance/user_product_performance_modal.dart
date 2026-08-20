import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopx/application/auth/auth_notifier.dart';

class UserProductPerformanceFilterResult {
  final String startDate;
  final String endDate;

  UserProductPerformanceFilterResult({
    required this.startDate,
    required this.endDate,
  });
}

class UserProductPerformanceModal extends HookConsumerWidget {
  const UserProductPerformanceModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryBlue = const Color(0xFF1D72D6);

    final authState = ref.watch(authNotifierProvider);
    final username = authState.user?.username ?? "Unknown";

    final fromDate = useState<DateTime?>(null);
    final toDate = useState<DateTime?>(null);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter Product Performance",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 🔒 SALESPERSON (READ-ONLY)
          TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: "Salesperson",
              border: const OutlineInputBorder(),
              hintText: username,
            ),
            controller: TextEditingController(text: username),
          ),

          const SizedBox(height: 14),

          _datePicker(
            context,
            label: "From Date",
            value: fromDate.value,
            onPick: (d) => fromDate.value = d,
          ),

          const SizedBox(height: 14),

          _datePicker(
            context,
            label: "To Date",
            value: toDate.value,
            onPick: (d) => toDate.value = d,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  UserProductPerformanceFilterResult(
                    startDate: DateFormat("yyyy-MM-dd")
                        .format(fromDate.value!),
                    endDate:
                        DateFormat("yyyy-MM-dd").format(toDate.value!),
                  ),
                );
              },
              child: const Text("Apply Filter"),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _datePicker(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required Function(DateTime) onPick,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2022),
          lastDate: DateTime.now(),
          initialDate: value ?? DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value == null
              ? "Select date"
              : DateFormat("yyyy-MM-dd").format(value),
        ),
      ),
    );
  }
}
