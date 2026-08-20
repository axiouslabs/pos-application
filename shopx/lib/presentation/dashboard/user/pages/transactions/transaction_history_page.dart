import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/presentation/dashboard/user/pages/transactions/transaction_detail_sheet.dart';
import 'package:shopx/widget/transaction/build_transaction_card.dart';

class TransactionHistoryPage extends HookConsumerWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch Data on Init
    useEffect(() {
      Future.microtask(() {
        ref.read(salesNotifierProvider.notifier).fetchMySales();
      });
      return null;
    }, []);

    // 2. Watch State
    final salesState = ref.watch(salesNotifierProvider);
    final sales = salesState.sales;

    // // 3. Data Processing: Group by Date & Calculate Daily Totals
    // // We use useMemoized to avoid recalculating on every rebuild unless sales change
    // final groupedSales = useMemoized(() {
    //   final Map<String, List<Sale>> map = {};

    //   // Sort desc (newest first)
    //   final sortedSales = [...sales]
    //     ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

    //   for (var sale in sortedSales) {
    //     final dateKey = DateFormat('EEEE, MMMM d, yyyy').format(sale.saleDate);
    //     if (!map.containsKey(dateKey)) {
    //       map[dateKey] = [];
    //     }
    //     map[dateKey]!.add(sale);
    //   }
    //   return map;
    // }, [sales]);

     // ✅ 3️⃣ DECLARE selectedStatus HERE (THIS WAS MISSING)
  final selectedStatus = useState<String>('ALL');

    final groupedSales = useMemoized(() {
      final Map<String, List<Sale>> map = {};

      // 1️⃣ FILTER BY STATUS
      final filteredSales = sales.where((sale) {
        if (selectedStatus.value == 'ALL') return true;
        return sale.paymentStatus.toUpperCase() == selectedStatus.value;
      }).toList();

      // 2️⃣ SORT DESC
      filteredSales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

      // 3️⃣ GROUP BY DATE
      for (var sale in filteredSales) {
        final dateKey = DateFormat('EEEE, MMMM d, yyyy').format(sale.saleDate);
        map.putIfAbsent(dateKey, () => []);
        map[dateKey]!.add(sale);
      }

      return map;
    }, [sales, selectedStatus.value]);

    // Constants
    const primaryBlue = Color(0xFF1976D2);
    const bgColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: primaryBlue,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Transaction History",
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

            // ================= FILTER BAR (UI ONLY) =================
            // Container(
            //   margin: const EdgeInsets.only(bottom: 8),
            //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            //   decoration: const BoxDecoration(
            //     color: Colors.white,
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black12,
            //         blurRadius: 4,
            //         offset: Offset(0, 2),
            //       ),
            //     ],
            //   ),
            //   child: const Row(
            //     children: [
            //       Icon(Icons.tune, color: Color(0xFF2C3E50), size: 20),
            //       SizedBox(width: 12),
            //       Expanded(
            //         child: Text(
            //           "Date and time of the filter",
            //           style: TextStyle(
            //             color: Color(0xFF2C3E50),
            //             fontSize: 14,
            //             fontWeight: FontWeight.w500,
            //           ),
            //         ),
            //       ),
            //       Icon(Icons.keyboard_arrow_right, color: Color(0xFF2C3E50)),
            //     ],
            //   ),
            // ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Color(0xFF2C3E50),
                    size: 20,
                  ),
                  const SizedBox(width: 12),

                  // STATUS DROPDOWN
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus.value,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All')),
                          DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                          DropdownMenuItem(
                            value: 'PENDING',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'PARTIALLY_PAID',
                            child: Text('Partial'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            selectedStatus.value = value;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= CONTENT =================
            Expanded(
              child: Builder(
                builder: (context) {
                  // A. LOADING
                  if (salesState.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    );
                  }

                  // B. ERROR
                  if (salesState.error != null) {
                    return Center(
                      child: Text(
                        "Error: ${salesState.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  // C. EMPTY
                  if (groupedSales.isEmpty) {
                    return const Center(
                      child: Text(
                        "No transactions found",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  // D. LIST OF TRANSACTIONS
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: groupedSales.keys.length,
                    itemBuilder: (context, index) {
                      final dateKey = groupedSales.keys.elementAt(index);
                      final daySales = groupedSales[dateKey]!;

                      // Calculate Total for this day
                      final double dayTotal = daySales.fold(
                        0,
                        (sum, item) => sum + item.totalAmount,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -- Date Header --
                          Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateKey,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF536471), // Dark Grey
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "SAR ${dayTotal.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(
                                      0xFF1F2937,
                                    ), // Darker Black/Blue
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // -- Transactions for this date --
                          ...daySales
                              .map(
                                (sale) => GestureDetector(
                                  onTap: () {
                                    _openTransactionDetails(context, ref, sale);
                                  },
                                  child: buildTransactionCard(
                                    sale,
                                    primaryBlue,
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTransactionDetails(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return TransactionDetailSheet(
              sale: sale,
              scrollController: scrollController,
            );
          },
        );
      },
    );

    // ✅ REFRESH AFTER MODAL CLOSES
    ref.read(salesNotifierProvider.notifier).fetchMySales();
  }
}
