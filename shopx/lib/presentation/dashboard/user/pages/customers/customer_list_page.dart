import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/application/customers/customer_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/presentation/dashboard/user/pages/customers/add_customer_page.dart';

class CustomerListPage extends HookConsumerWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
final loggedInSalespersonId = authState.user?.id;

    // 1. Fetch Customers on Load
  useEffect(() {
  Future.microtask(() {
    // 🔒 Manage Customers → ONLY my customers
    ref.read(customerNotifierProvider.notifier).fetchMyCustomers();
  });
  return null;
}, []);


    final searchQuery = useState('');


    // 2. Watch State
    final customerState = ref.watch(customerNotifierProvider);
    final customers = customerState.customers;

  final filteredCustomers = customers.where((customer) {
  final query = searchQuery.value.toLowerCase();
  return customer.name.toLowerCase().contains(query);
}).toList();






    // UI Constants
    const primaryBlue = Color(0xFF1976D2);
    const bgColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 20, color: primaryBlue),
                  ),
                  const Expanded(
                    child: Text(
                      "Customers",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // Balance back button
                ],
              ),
            ),

           // --- SEARCH BAR (Visual Only) ---
  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: TextField(
      onChanged: (value) {
        searchQuery.value = value;
      },
      decoration: const InputDecoration(
        hintText: "Search for a name",
        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: Icon(Icons.search, color: Color(0xFF1F2937)),
      ),
    ),
  ),
),



           kHeight10,

            // --- CUSTOMER LIST ---
            Expanded(
              child: Builder(
                builder: (context) {
                  if (customerState.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: primaryBlue));
                  }

                  if (customerState.error != null) {
                    return Center(child: Text("Error: ${customerState.error}"));
                  }

                  if (customers.isEmpty) {
                    return const Center(child: Text("No customers found"));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                   itemCount: filteredCustomers.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        color: Colors.white, // Background per item for clean look
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // --- ADD BUTTON ---
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Navigate to Add Page
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddCustomerPage()),
                    );
                    // Refresh list on return
                    ref.read(customerNotifierProvider.notifier).fetchMyCustomers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Add a new customer",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}