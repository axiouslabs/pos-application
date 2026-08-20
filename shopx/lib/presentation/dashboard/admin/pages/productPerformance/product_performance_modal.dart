import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/application/salesman/salesman_notifier.dart';
import 'package:shopx/domain/salesman/salesman.dart';

class ProductPerformanceFilterResult {
  final String startDate;
  final String endDate;
  final String? salespersonId;

  ProductPerformanceFilterResult({
    required this.startDate,

    required this.endDate,
    this.salespersonId,
  });
}

class ProductPerformanceFilterModal extends HookConsumerWidget {
  const ProductPerformanceFilterModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

      // 🔥 FORCE FETCH WHEN MODAL OPENS
    useEffect(() {
      Future.microtask(() {
        ref.read(salesmanNotifierProvider.notifier).fetchSalesmen();
      });
      return null;
    }, []);


    final primaryBlue = const Color(0xFF1D72D6);

    final salesmanState = ref.watch(salesmanNotifierProvider);
 final selectedSalespersonId = useState<int?>(null);



    final fromDate = useState<DateTime?>(null);
    final toDate = useState<DateTime?>(null);

    return Material(
  color: Colors.transparent,
  child: SingleChildScrollView(
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

        /// SALESPERSON AUTOCOMPLETE
        Autocomplete<Salesman>(
          optionsBuilder: (text) {
            if (text.text.isEmpty) return const Iterable.empty();
            return salesmanState.salesmen.where(
              (s) => s.username
                  .toLowerCase()
                  .contains(text.text.toLowerCase()),
            );
          },
          displayStringForOption: (s) => s.username,
          onSelected: (s) {
            selectedSalespersonId.value = s.id;
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
                ProductPerformanceFilterResult(
                  startDate: DateFormat("yyyy-MM-dd")
                      .format(fromDate.value!),
                  endDate:
                      DateFormat("yyyy-MM-dd")
                          .format(toDate.value!),
                  salespersonId:
                      selectedSalespersonId.value?.toString(),
                ),
              );
            },
            child: const Text("Apply Filter"),
          ),
        ),

        const SizedBox(height: 20),
      ],
    ),
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
