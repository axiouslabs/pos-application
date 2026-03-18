import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/domain/customers/customer.dart';
import 'package:shopx/presentation/dashboard/admin/pages/transaction/admin_transaction_history_page.dart';

class CustomerBillsPage extends HookConsumerWidget {

  final Customer customer;

  const CustomerBillsPage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    Future.microtask(() {
      ref.read(salesNotifierProvider.notifier)
          .fetchAdminSales(customerId: customer.id);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Bills - ${customer.name}"),
      ),

      body: const AdminTransactionHistoryPage(),
    );
  }
}