import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopx/application/payments/payments_notifier.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/widget/admintransaction/transaction_detail_dialog.dart';
import 'package:shopx/widget/admintransaction/transaction_filter_dialog.dart';

class AdminTransactionHistoryPage extends HookConsumerWidget {
  final VoidCallback? onFilterTap;

  const AdminTransactionHistoryPage({super.key, this.onFilterTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(salesNotifierProvider.notifier).fetchAdminSales();
      });
      return null;
    }, []);

    final primaryBlue = const Color(0xFF1D72D6);

    final salesState = ref.watch(salesNotifierProvider);
    final filter = useState<TransactionFilterResult?>(null);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryBlue, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Transaction History",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await showDialog<TransactionFilterResult>(
                context: context,
               builder: (_) => TransactionFilterDialog(
  salespersons: salesState.sales
      .map((e) => e.salespersonName)
      .toSet()
      .toList(),
  isAdmin: true,
),
              );

              // if (result != null) {
              //   filter.value = result;
              // }

              // filter.value = result; // allow null also

              if (result == null) {
                // Clear filter → fetch all
                await ref
                    .read(salesNotifierProvider.notifier)
                    .fetchAdminSales();
              } else {
                await ref
                    .read(salesNotifierProvider.notifier)
                    .fetchAdminSales(
                      from: result.fromDate?.toIso8601String(),
                      to: result.toDate?.toIso8601String(),
                      salesperson: result.salespersonName,
                      status: result.status == 'ALL' ? null : result.status,
                    );
              }
            },

            icon: Icon(Icons.tune, color: primaryBlue, size: 20),
            label: Text(
              "Filter",
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: salesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : salesState.error != null
          ? Center(child: Text(salesState.error!))
          // : _buildSalesList(context, ref, salesState.sales, filter.value),
          : _buildSalesList(context, ref, salesState.sales),
    );
  }

  // ================= LIST =================

  //   Widget _buildSalesList(
  //     BuildContext context,
  //     WidgetRef ref,
  //     List<Sale> sales,
  //     TransactionFilterResult? filter,
  //   ) {
  //     // var filteredSales = List<Sale>.from(sales);
  //     var filteredSales = List<Sale>.from(sales);

  // // ✅ DEFAULT: Show only today's sales if no filter applied
  // if (filter == null) {
  //   final now = DateTime.now();

  //   filteredSales = filteredSales.where((sale) {
  //     return sale.saleDate.year == now.year &&
  //            sale.saleDate.month == now.month &&
  //            sale.saleDate.day == now.day;
  //   }).toList();
  // }

  //     if (filter != null) {
  //       // Salesperson filter
  //       if (filter.salespersonName != null) {
  //         filteredSales = filteredSales
  //             .where(
  //               (s) =>
  //                   s.salespersonName.trim().toLowerCase() ==
  //                   filter.salespersonName!.trim().toLowerCase(),
  //             )
  //             .toList();
  //       }

  //       // Status filter
  //       // if (filter.status != 'ALL') {
  //       //   filteredSales = filteredSales
  //       //       .where((s) => s.paymentStatus.toUpperCase() == filter.status)
  //       //       .toList();
  //       // }
  // if (filter.status != 'ALL') {
  //   filteredSales = filteredSales.where((s) {
  //     if (filter.status == 'CANCELLED') {
  //       return s.saleStatus == 'voided';
  //     }

  //     if (filter.status == 'PAID') {
  //       return s.saleStatus != 'voided' &&
  //           s.paymentStatus.toUpperCase() == 'PAID';
  //     }

  //     if (filter.status == 'PENDING') {
  //       return s.saleStatus != 'voided' &&
  //           s.paymentStatus.toUpperCase() == 'PENDING';
  //     }

  //     return true;
  //   }).toList();
  // }

  //       // // From date
  //       // if (filter.fromDate != null) {
  //       //   filteredSales = filteredSales
  //       //       .where((s) => !s.saleDate.isBefore(filter.fromDate!))
  //       //       .toList();
  //       // }

  //       // // To date
  //       // if (filter.toDate != null) {
  //       //   filteredSales = filteredSales
  //       //       .where((s) => !s.saleDate.isAfter(filter.toDate!))
  //       //       .toList();
  //       // }

  //       // From date
  // if (filter.fromDate != null) {
  //   final startOfDay = DateTime(
  //     filter.fromDate!.year,
  //     filter.fromDate!.month,
  //     filter.fromDate!.day,
  //     0,
  //     0,
  //     0,
  //   );

  //   filteredSales = filteredSales
  //       .where((s) => !s.saleDate.isBefore(startOfDay))
  //       .toList();
  // }

  // // To date
  // if (filter.toDate != null) {
  //   final endOfDay = DateTime(
  //     filter.toDate!.year,
  //     filter.toDate!.month,
  //     filter.toDate!.day,
  //     23,
  //     59,
  //     59,
  //     999,
  //   );

  //   filteredSales = filteredSales
  //       .where((s) => !s.saleDate.isAfter(endOfDay))
  //       .toList();
  // }
  //     }

  //     if (filteredSales.isEmpty) {
  //       return const Center(child: Text("No transactions found"));
  //     }

  //     final sortedSales = [...filteredSales]
  //       ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

  //     final groupedSales = _groupByDate(sortedSales);

  //     return ListView.builder(
  //       padding: const EdgeInsets.all(20),
  //       itemCount: groupedSales.keys.length,
  //       itemBuilder: (context, index) {
  //         final dateKey = groupedSales.keys.elementAt(index);
  //         final dailySales = groupedSales[dateKey]!;

  //         final dailyTotal = dailySales
  //             .where(
  //               (s) =>
  //                   s.paymentStatus.toUpperCase() == 'PAID' &&
  //                   s.saleStatus != 'voided',
  //             )
  //             .fold<double>(0, (sum, sale) => sum + sale.totalAmount);

  //         return Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // DATE HEADER
  //             Padding(
  //               padding: const EdgeInsets.only(bottom: 16, top: 8),
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     dateKey,
  //                     style: const TextStyle(
  //                       color: Color(0xFF536471),
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   Text(
  //                     "SAR ${dailyTotal.toStringAsFixed(2)}",
  //                     style: const TextStyle(
  //                       color: Color(0xFF1F2937),
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             // TRANSACTION CARDS
  //             // ...dailySales.map(
  //             //   (sale) => _buildTransactionCard(context, sale, () async {
  //             //     await ref
  //             //         .read(salesNotifierProvider.notifier)
  //             //         .fetchAdminSales();
  //             //   }),
  //             // ),
  //             ...dailySales.map(
  //               (sale) => _buildTransactionCard(context, ref, sale, () async {
  //                 await ref
  //                     .read(salesNotifierProvider.notifier)
  //                     .fetchAdminSales();
  //               }),
  //             ),

  //             const SizedBox(height: 12),
  //           ],
  //         );
  //       },
  //     );
  //   }



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
          .where(
            (s) =>
                s.paymentStatus.toUpperCase() == 'PAID' &&
                s.saleStatus != 'voided',
          )
          .fold<double>(0, (sum, sale) => sum + sale.totalAmount);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateKey,
                  style: const TextStyle(
                    color: Color(0xFF536471),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "SAR ${dailyTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...dailySales.map(
            (sale) => _buildTransactionCard(context, ref, sale, () async {
              await ref
                  .read(salesNotifierProvider.notifier)
                  .fetchAdminSales();
            }),
          ),
          const SizedBox(height: 12),
        ],
      );
    },
  );
}

  // ================= GROUP BY DATE =================

  Map<String, List<Sale>> _groupByDate(List<Sale> sales) {
    final Map<String, List<Sale>> grouped = {};

    for (final sale in sales) {
      final key = DateFormat('EEEE, MMMM d, yyyy').format(sale.saleDate);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(sale);
    }

    return grouped;
  }

  // ================= CARD =================

  Widget _buildTransactionCard(
    BuildContext context,
    WidgetRef ref, // 👈 ADD THIS
    Sale sale,
    VoidCallback onRefresh,
  ) {
    final timeString = DateFormat('hh:mm a').format(sale.saleDate);
    final trxId = "#TRX${sale.id.toString().padLeft(10, '0')}";

    // //old
    // final statusColor = _getStatusColor(sale.paymentStatus);

    final isVoided = sale.saleStatus == 'voided';
    final statusColor = isVoided
        ? Colors.red
        : _getStatusColor(sale.paymentStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: () {
        showDialog(
          context: context,
          builder: (_) => TransactionDetailsDialog(
            sale: sale,

            // 🔒 FINAL SAFETY GUARD
            onMarkAsPaid: sale.saleStatus == 'voided'
                ? null
                : sale.paymentStatus.toUpperCase() == 'PENDING'
                ? () async {
                    await ref
                        .read(paymentsNotifierProvider.notifier)
                        .markPaymentAsPaid(sale.id);

                    Navigator.of(context).pop(); // parent closes dialog
                    await ref
                        .read(salesNotifierProvider.notifier)
                        .fetchAdminSales();
                  }
                : null,

            // onCancelSale: sale.saleStatus == 'voided'
            //     ? null
            //     : () async {
            //         await ref
            //             .read(salesNotifierProvider.notifier)
            //             .voidSale(sale.id);

            //         Navigator.of(context).pop();
            //         await ref
            //             .read(salesNotifierProvider.notifier)
            //             .fetchAdminSales();
            //       },
            onCancelSale: sale.saleStatus == 'voided'
                ? null
                : () async {
                    await ref
                        .read(salesNotifierProvider.notifier)
                        .voidSale(sale.id);

                    // ❌ NO Navigator.pop() HERE
                    // Dialog will close itself
                  },
          ),
        );
      },

      //   onTap: () {
      //     showDialog(
      //       context: context,
      //       builder: (_) => TransactionDetailsDialog(
      //         sale: sale,

      //       onMarkAsPaid:
      // sale.paymentStatus.toUpperCase() == 'PENDING' &&
      //         sale.saleStatus != 'voided'
      //     ? () async {
      //         await ref
      //             .read(paymentsNotifierProvider.notifier)
      //             .markPaymentAsPaid(sale.id);

      //         // ✅ CLOSE DIALOG FIRST
      //         Navigator.of(context).pop();

      //         // ✅ REFRESH LIST AFTER
      //         await ref
      //             .read(salesNotifierProvider.notifier)
      //             .fetchAdminSales();
      //       }
      //     : null,

      //       onCancelSale: sale.saleStatus != 'voided'
      // ? () async {
      //     await ref
      //         .read(salesNotifierProvider.notifier)
      //         .voidSale(sale.id);

      //     // ✅ CLOSE DIALOG FIRST
      //     Navigator.of(context).pop();

      //     // ✅ REFRESH LIST AFTER
      //     await ref
      //         .read(salesNotifierProvider.notifier)
      //         .fetchAdminSales();
      //   }
      // : null,

      //       ),
      //     );
      //   },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child:
                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Text(
                  //       "SAR ${sale.totalAmount.toStringAsFixed(2)}",
                  //       style: const TextStyle(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.bold,
                  //         color: Color(0xFF1F2937),
                  //       ),
                  //     ),
                  //     const SizedBox(height: 4),
                  //     Text(
                  //       "$timeString - $trxId",
                  //       style: const TextStyle(
                  //         fontSize: 12,
                  //         color: Color(0xFF536471),
                  //         fontWeight: FontWeight.w400,
                  //       ),
                  //       maxLines: 1,
                  //       overflow: TextOverflow.ellipsis,
                  //     ),
                  //   ],
                  // ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 💰 Amount
                      Text(
                        "SAR ${sale.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 👤 Customer Name (NEW)
                      Text(
                        sale.customerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // 🕒 Time + TRX
                      Text(
                        "$timeString - $trxId",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF536471),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                // sale.paymentStatus.toUpperCase(),
                sale.saleStatus == 'voided'
                    ? 'CANCELLED'
                    : sale.paymentStatus.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS COLOR =================

  // Color _getStatusColor(String status) {
  //   switch (status.toUpperCase()) {
  //     case 'PAID':
  //       return const Color(0xFF1D72D6);
  //     case 'PENDING':
  //       return const Color(0xFFF59E0B);
  //     case 'VOID':
  //       return const Color(0xFF9CA3AF);
  //     default:
  //       return const Color(0xFF1D72D6);
  //   }
  // }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF1D72D6);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF1D72D6);
    }
  }
}
