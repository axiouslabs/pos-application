import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/application/customers/customer_notifier.dart';
import 'package:shopx/application/salesman/salesman_notifier.dart';
import 'package:shopx/domain/customers/customer.dart';
import 'package:shopx/presentation/dashboard/admin/pages/customer/admin_customer_filter_result.dart';
import 'package:shopx/presentation/dashboard/admin/pages/customer/admin_customer_page.dart';

class AdminCustomerListPage extends HookConsumerWidget {
  const AdminCustomerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

    final searchQuery = useState('');
    final selectedArea = useState<String>("All");
    final selectedSalespersonId = useState<int?>(null);
    final selectedFilterType = useState<CustomerFilterType?>(null);

    // STATE: Track expanded row
    final expandedCustomerId = useState<int?>(null);
    final customerState = ref.watch(customerNotifierProvider);

    final customers = customerState.customers;
    final salesmanState = ref.watch(salesmanNotifierProvider);

    // 🔥 ID → NAME mapping
    final Map<int, String> salespersonMap = {
      for (final s in salesmanState.salesmen)
        if (s.id != null) s.id!: s.username,
    };
    final salespersons = salesmanState.salesmen;

    final areas = [
      "All",
      ...{
        for (var c in customers)
          if (c.area != null && c.area!.isNotEmpty) c.area!,
      },
    ].toList();

    final filteredCustomers = customers.where((customer) {
      final query = searchQuery.value.toLowerCase();

      final matchesSearch =
          customer.name.toLowerCase().contains(query) ||
          (customer.phone?.toLowerCase().contains(query) ?? false);

      bool matchesFilter = true;

      if (selectedFilterType.value == CustomerFilterType.area) {
        matchesFilter =
            selectedArea.value == "All" || customer.area == selectedArea.value;
      }

      if (selectedFilterType.value == CustomerFilterType.salesperson) {
        matchesFilter =
            selectedSalespersonId.value == null ||
            customer.salespersonId == selectedSalespersonId.value;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    useEffect(() {
      if (auth.isAuthenticated) {
        Future.microtask(() async {
          await ref.read(customerNotifierProvider.notifier).fetchAllCustomers();
          await ref
              .read(salesmanNotifierProvider.notifier)
              .fetchSalesmen(); // ✅ ADD
        });
      }
      return null;
    }, [auth.isAuthenticated]);

    // LISTENER: Handle side effects (Success/Error)
    ref.listen(customerNotifierProvider, (previous, next) {
      if (!next.isLoading && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // If delete was successful, refresh list
      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.success == true) {
        ref.read(customerNotifierProvider.notifier).fetchAllCustomers();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Customers",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),

              child: TextField(
                onChanged: (value) {
                  searchQuery.value = value;
                },
                decoration: const InputDecoration(
                  hintText: "Search for a name, contact, or email",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Icon(Icons.search, color: Colors.blue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 10,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
              final result = await showDialog<CustomerFilterResult>(
  context: context,
  builder: (_) => CustomerFilterDialog(
    areas: areas,
    salespersons: salespersons, // ✅ PASS FULL SALESMEN LIST
  ),
);

if (result == null) return;

if (result.filterType == CustomerFilterType.area) {
  selectedFilterType.value = CustomerFilterType.area;
  selectedArea.value = result.value;
  selectedSalespersonId.value = null;
} else {
  selectedFilterType.value = CustomerFilterType.salesperson;
  selectedSalespersonId.value = result.salespersonId;
  selectedArea.value = "All";
}

              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,

                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Choose a Category",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
          ),

          // List Content
          Expanded(
            child: customerState.isLoading && customerState.customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : customerState.customers.isEmpty
                ? const Center(child: Text("No customers found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];

                      final isExpanded =
                          expandedCustomerId.value == customer.id;

                      return _buildCustomerCard(
                        context,
                        ref,
                        customer,
                        isExpanded,
                        expandedCustomerId,
                        salespersonMap,
                      );
                    },
                  ),
          ),

          // Add New Customer Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.transparent,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCustomerPage(),
                    ),
                  );
                },
                child: const Text(
                  "Add a new customer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
    bool isExpanded,
    ValueNotifier<int?> expandedState,
    Map<int, String> salespersonMap, // ✅ ADD THIS
  ) {
    return GestureDetector(
      onTap: () {
        // Toggle expansion logic
        expandedState.value = (expandedState.value == customer.id)
            ? null
            : customer.id;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                if (!isExpanded)
                  const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),

            // Expanded Content
            if (isExpanded) ...[
              const SizedBox(height: 8),
              Text("Phone: ${customer.phone ?? "-"}"),
              if (customer.area != null)
                Text(
                  "Area: ${customer.area}",
                  style: const TextStyle(color: Colors.grey),
                ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  // Modify Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdminCustomerPage(customer: customer),
                          ),
                        );
                      },
                      child: const Text(
                        "Modify",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Delete Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              content: const Text(
                                "Do you want to delete?",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              actionsAlignment: MainAxisAlignment.spaceEvenly,
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    "NO",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    "YES",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (shouldDelete == true) {
                          await ref
                              .read(customerNotifierProvider.notifier)
                              .deleteCustomer(customer.id);
                        }
                      },

                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (customer.salespersonId != null)
              Text(
                "Salesperson: ${salespersonMap[customer.salespersonId!] ?? "-"}",
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
