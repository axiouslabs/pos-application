import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionFilterResult {
  final String? salespersonName;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String status; // ALL, PAID, PENDING, VOID

  TransactionFilterResult({
    this.salespersonName,
    this.fromDate,
    this.toDate,
    required this.status,
  });
}

class TransactionFilterDialog extends StatefulWidget {
  final List<String> salespersons;
  final bool isAdmin;

  const TransactionFilterDialog({
    super.key,
    this.salespersons = const [],
    this.isAdmin = false,
  });

  @override
  State<TransactionFilterDialog> createState() =>
      _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends State<TransactionFilterDialog> {
  String? _selectedSalesperson;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _status = 'ALL';

  final List<String> _statusOptions = ['ALL', 'PAID', 'PENDING', 'CANCELLED'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 20),

           if (widget.isAdmin) ...[
  _salespersonAutocomplete(),
  const SizedBox(height: 16),
],

            _datePicker(
              label: "From Date",
              value: _fromDate,
              onTap: () => _pickDate(isFrom: true),
            ),
            const SizedBox(height: 12),

            _datePicker(
              label: "To Date",
              value: _toDate,
              onTap: () => _pickDate(isFrom: false),
            ),
            const SizedBox(height: 16),

            _statusDropdown(),
            const SizedBox(height: 24),

            _actions(context),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Filter Transactions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ================= AUTOCOMPLETE =================

  Widget _salespersonAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return widget.salespersons;
        }
        return widget.salespersons.where(
          (name) => name
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()),
        );
      },
      onSelected: (value) {
        _selectedSalesperson = value;
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: "Salesperson",
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  // ================= DATE PICKER =================

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value == null
              ? "Select date"
              : DateFormat('dd MMM yyyy').format(value),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  // ================= STATUS =================

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: const InputDecoration(
        labelText: "Payment Status",
        border: OutlineInputBorder(),
      ),
      items: _statusOptions
          .map(
            (s) => DropdownMenuItem(value: s, child: Text(s)),
          )
          .toList(),
      onChanged: (value) => setState(() => _status = value!),
    );
  }

  // ================= ACTIONS =================

  // Widget _actions(BuildContext context) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: OutlinedButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Cancel"),
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(
  //               context,
  //               TransactionFilterResult(
  //                 salespersonName: _selectedSalesperson,
  //                 fromDate: _fromDate,
  //                 toDate: _toDate,
  //                 status: _status,
  //               ),
  //             );
  //           },
  //           child: const Text("Apply Filter"),
  //         ),
  //       ),
  //     ],
  //   );
  // }

   Widget _actions(BuildContext context) {
  return Column(
    children: [

      // 🔹 Clear Filter Button
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            Navigator.pop(context, null); // return null explicitly
          },
          child: const Text(
            "Clear Filter",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),

      const SizedBox(height: 12),

      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  TransactionFilterResult(
                    salespersonName: _selectedSalesperson,
                    fromDate: _fromDate,
                    toDate: _toDate,
                    status: _status,
                  ),
                );
              },
              child: const Text("Apply Filter"),
            ),
          ),
        ],
      ),
    ],
  );
}


}
