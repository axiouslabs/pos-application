import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/presentation/dashboard/user/pages/transactions/transaction_detail_sheet.dart';
import 'package:shopx/widget/transaction/build_transaction_card.dart';

// Represents either a sale entry or a payment-received entry in the timeline
class _TimelineEntry {
  final DateTime date;
  final Sale sale;
  final bool isPaymentEntry; // true = payment received event
  final double? paymentAmount;
  final String? paymentMethod;

  const _TimelineEntry({
    required this.date,
    required this.sale,
    this.isPaymentEntry = false,
    this.paymentAmount,
    this.paymentMethod,
  });
}

class TransactionHistoryPage extends HookConsumerWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch Data on Init — show cached data immediately, refresh in background
    useEffect(() {
      Future.microtask(() {
        ref.read(salesNotifierProvider.notifier).fetchMySales();
      });
      return null;
    }, []);

    // 2. Watch State
    final salesState = ref.watch(salesNotifierProvider);
    final sales = salesState.sales;

    // Show spinner only on first load (no cached data yet)
    final isFirstLoad = salesState.isLoading && sales.isEmpty;

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
      final Map<String, List<_TimelineEntry>> map = {};

      // 1️⃣ FILTER BY STATUS
      final filteredSales = sales.where((sale) {
        if (selectedStatus.value == 'ALL') return true;
        return sale.paymentStatus.toUpperCase() == selectedStatus.value;
      }).toList();

      // 2️⃣ Build timeline entries:
      //    - One entry per sale (on the sale's creation date)
      //    - One entry per payment received (on the payment's date, if different from sale date)
      final List<_TimelineEntry> entries = [];

      for (final sale in filteredSales) {
        // Sale creation entry
        entries.add(_TimelineEntry(date: sale.saleDate, sale: sale));

        // Payment received entries — only add if payment date differs from sale date
        for (final payment in sale.payments) {
          final saleDay = DateFormat('yyyy-MM-dd').format(sale.saleDate);
          final payDay = DateFormat('yyyy-MM-dd').format(payment.createdAt);
          if (payDay != saleDay) {
            entries.add(_TimelineEntry(
              date: payment.createdAt,
              sale: sale,
              isPaymentEntry: true,
              paymentAmount: payment.amount,
              paymentMethod: payment.method,
            ));
          }
        }
      }

      // 3️⃣ SORT DESC
      entries.sort((a, b) => b.date.compareTo(a.date));

      // 4️⃣ GROUP BY DATE
      for (final entry in entries) {
        final dateKey = DateFormat('EEEE, MMMM d, yyyy').format(entry.date);
        map.putIfAbsent(dateKey, () => []);
        map[dateKey]!.add(entry);
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
                  // A. LOADING (only on first load — no cached data)
                  if (isFirstLoad) {
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
                  return RefreshIndicator(
                    color: primaryBlue,
                    onRefresh: () async {
                      await ref
                          .read(salesNotifierProvider.notifier)
                          .fetchMySales();
                    },
                    child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: groupedSales.keys.length,
                    itemBuilder: (context, index) {
                      final dateKey = groupedSales.keys.elementAt(index);
                      final dayEntries = groupedSales[dateKey]!;

                      // Daily total: sum sale amounts for sale entries,
                      // and payment amounts for payment entries
                      final double dayTotal = dayEntries.fold(0, (sum, entry) {
                        if (entry.isPaymentEntry) {
                          return sum + (entry.paymentAmount ?? 0);
                        }
                        return sum + entry.sale.totalAmount;
                      });

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
                                    color: Color(0xFF536471),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "SAR ${dayTotal.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // -- Entries for this date --
                          ...dayEntries.map((entry) {
                            if (entry.isPaymentEntry) {
                              // Payment received card
                              return GestureDetector(
                                onTap: () => _openTransactionDetails(
                                    context, ref, entry.sale),
                                child: _buildPaymentReceivedCard(
                                  entry,
                                  primaryBlue,
                                ),
                              );
                            }
                            return GestureDetector(
                              onTap: () => _openTransactionDetails(
                                  context, ref, entry.sale),
                              child: buildTransactionCard(
                                entry.sale,
                                primaryBlue,
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ), // ListView.builder
                  ); // RefreshIndicator
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

  // ── Payment received card (shown on the date payment was collected) ────────
  Widget _buildPaymentReceivedCard(_TimelineEntry entry, Color primaryBlue) {
    final timeStr = DateFormat('hh:mm a').format(entry.date);
    final trxId = "#TRX${entry.sale.id.toString().padLeft(10, '0')}";
    final method = (entry.paymentMethod ?? 'cash').toLowerCase();
    final methodIcon =
        method == 'card' ? Icons.credit_card : Icons.payments_outlined;
    const receivedColor = Color(0xFF16A34A); // green

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: receivedColor.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: receivedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(methodIcon, color: receivedColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Received",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: receivedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "SAR ${(entry.paymentAmount ?? 0).toStringAsFixed(2)}  •  $timeStr",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$trxId  •  ${entry.sale.customerName}",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Method badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: receivedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              method.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: receivedColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
