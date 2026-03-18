import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/customers/customer_notifier.dart';
import 'package:shopx/domain/customers/customer.dart';
import 'customer_bills_page.dart';

class AdminCustomerBillsSelectorPage extends ConsumerStatefulWidget {
  const AdminCustomerBillsSelectorPage({super.key});

  @override
  ConsumerState<AdminCustomerBillsSelectorPage> createState() =>
      _AdminCustomerBillsSelectorPageState();
}

class _AdminCustomerBillsSelectorPageState
    extends ConsumerState<AdminCustomerBillsSelectorPage> {

  Customer? selectedCustomer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customerNotifierProvider.notifier).fetchAllCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {

    final state = ref.watch(customerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Customer"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Autocomplete<Customer>(

              optionsBuilder: (textEditingValue) {

                if (textEditingValue.text == "") {
                  return state.customers;
                }

                return state.customers.where((customer) =>
                    customer.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
              },

              displayStringForOption: (Customer option) => option.name,

              onSelected: (Customer customer) {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerBillsPage(customer: customer),
                  ),
                );
              },

              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {

                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: "Customer",
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}