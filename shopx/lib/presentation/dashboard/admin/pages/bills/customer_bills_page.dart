import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/application/payments/payments_notifier.dart';
import 'package:shopx/domain/customers/customer.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/widget/admintransaction/transaction_detail_dialog.dart';

class CustomerBillsPage extends HookConsumerWidget {
  final Customer customer;

  const CustomerBillsPage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // ✅ ONLY FETCH CUSTOMER DATA
    useEffect(() {
      Future.microtask(() {
        ref.read(salesNotifierProvider.notifier)
            .fetchAdminSales(customerId: customer.id);
      });
      return null;
    }, []);

    final salesState = ref.watch(salesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Bills - ${customer.name}"),
      ),
      body: salesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : salesState.error != null
              ? Center(child: Text(salesState.error!))
              : _buildSalesList(context, ref, salesState.sales),
    );
  }

  // ================= LIST =================

  Widget _buildSalesList(
    BuildContext context,
    WidgetRef ref,
    List<Sale> sales,
  ) {
    if (sales.isEmpty) {
      return const Center(child: Text("No transactions found"));
    }

    final sortedSales = [...sales]
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

    final groupedSales = _groupByDate(sortedSales);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedSales.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedSales.keys.elementAt(index);
        final dailySales = groupedSales[dateKey]!;

        final dailyTotal = dailySales
            .where((s) =>
                s.paymentStatus.toUpperCase() == 'PAID' &&
                s.saleStatus != 'voided')
            .fold<double>(0, (sum, sale) => sum + sale.totalAmount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateKey),
                  Text("SAR ${dailyTotal.toStringAsFixed(2)}"),
                ],
              ),
            ),
            ...dailySales.map(
              (sale) => _buildTransactionCard(context, ref, sale),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Map<String, List<Sale>> _groupByDate(List<Sale> sales) {
    final Map<String, List<Sale>> grouped = {};

    for (final sale in sales) {
      final key = DateFormat('EEEE, MMMM d, yyyy').format(sale.saleDate);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(sale);
    }

    return grouped;
  }

  Widget _buildTransactionCard(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
  ) {
    final timeString = DateFormat('hh:mm a').format(sale.saleDate);
    final trxId = "#TRX${sale.id.toString().padLeft(10, '0')}";
    final isVoided = sale.saleStatus == 'voided';

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => TransactionDetailsDialog(
            sale: sale,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SAR ${sale.totalAmount.toStringAsFixed(2)}"),
                  const SizedBox(height: 4),
                  Text(sale.customerName),
                  const SizedBox(height: 4),
                  Text("$timeString - $trxId"),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isVoided ? Colors.red : Colors.blue,
              child: Text(
                isVoided
                    ? 'CANCELLED'
                    : sale.paymentStatus.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}