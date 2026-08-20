import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shopx/domain/salesman/salesman.dart';

enum CustomerFilterType { area, salesperson }

class CustomerFilterResult {
  final CustomerFilterType filterType;
  final String value; // area name OR salesperson name (for display)
  final int? salespersonId;

  CustomerFilterResult({
    required this.filterType,
    required this.value,
    this.salespersonId,
  });
}

class CustomerFilterDialog extends HookWidget {
  final List<String> areas;
  final List<Salesman> salespersons;

  const CustomerFilterDialog({
    super.key,
    required this.areas,
    required this.salespersons,
  });

  @override
  Widget build(BuildContext context) {
    final filterType = useState<CustomerFilterType>(CustomerFilterType.area);
    final searchText = useState("");

    // ✅ AREA FILTER
    final filteredAreas = areas
        .where(
          (a) =>
              a != "All" &&
              a.toLowerCase().contains(searchText.value.toLowerCase()),
        )
        .toList();

    // ✅ SALESPERSON FILTER (ID-SAFE)
    final filteredSalespersons = salespersons
        .where(
          (s) =>
              s.username.toLowerCase().contains(searchText.value.toLowerCase()),
        )
        .toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Filter Customers",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// CATEGORY
            DropdownButtonFormField<CustomerFilterType>(
              value: filterType.value,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: CustomerFilterType.area,
                  child: Text("Area"),
                ),
                DropdownMenuItem(
                  value: CustomerFilterType.salesperson,
                  child: Text("Salesperson"),
                ),
              ],
              onChanged: (v) {
                filterType.value = v!;
                searchText.value = "";
              },
            ),

            const SizedBox(height: 12),

            /// SEARCH
            TextField(
              decoration: InputDecoration(
                labelText: filterType.value == CustomerFilterType.area
                    ? "Search Area"
                    : "Search Salesperson",
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => searchText.value = v,
            ),

            const SizedBox(height: 12),

            /// LIST
            SizedBox(
              height: 220,
              child: filterType.value == CustomerFilterType.area
                  ? (filteredAreas.isEmpty
                        ? const Center(child: Text("No results"))
                        : ListView.builder(
                            itemCount: filteredAreas.length,
                            itemBuilder: (context, index) {
                              final area = filteredAreas[index];
                              return ListTile(
                                title: Text(area),
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                    CustomerFilterResult(
                                      filterType: CustomerFilterType.area,
                                      value: area,
                                    ),
                                  );
                                },
                              );
                            },
                          ))
                  : (filteredSalespersons.isEmpty
                        ? const Center(child: Text("No results"))
                        : ListView.builder(
                            itemCount: filteredSalespersons.length,
                            itemBuilder: (context, index) {
                              final s = filteredSalespersons[index];
                              return ListTile(
                                title: Text(s.username),
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                    CustomerFilterResult(
                                      filterType:
                                          CustomerFilterType.salesperson,
                                      value: s.username,
                                      salespersonId: s.id,
                                    ),
                                  );
                                },
                              );
                            },
                          )),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
