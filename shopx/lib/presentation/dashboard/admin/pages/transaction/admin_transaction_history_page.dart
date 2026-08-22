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
      backgroundColor: const Color(0xFFF8F9FA),
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
                ),
              );

              if (result != null) {
                filter.value = result;
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
      body: salesState.isLoading && salesState.sales.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : salesState.sales.isEmpty && salesState.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load transactions',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Check your connection and try again.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(salesNotifierProvider.notifier)
                        .fetchAdminSales(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildSalesList(context, ref, salesState.sales, filter.value),
    );
  }

  // ================= LIST =================

  Widget _buildSalesList(
    BuildContext context,
    WidgetRef ref,
    List<Sale> sales,
    TransactionFilterResult? filter,
  ) {
    var filteredSales = List<Sale>.from(sales);

    if (filter != null) {
      if (filter.salespersonName != null) {
        filteredSales = filteredSales
            .where(
              (s) =>
                  s.salespersonName.trim().toLowerCase() ==
                  filter.salespersonName!.trim().toLowerCase(),
            )
            .toList();
      }
      // Status filter
      if (filter.status != 'ALL') {
        if (filter.status == 'CANCELED') {
          filteredSales = filteredSales.where((s) {
            final st = s.paymentStatus.toUpperCase();
            return st == 'VOID' || st == 'VOIDED' || st == 'CANCELED';
          }).toList();
        } else {
          filteredSales = filteredSales
              .where((s) => s.paymentStatus.toUpperCase() == filter.status)
              .toList();
        }
      }

      if (filter.fromDate != null) {
        filteredSales = filteredSales
            .where((s) => !s.saleDate.isBefore(filter.fromDate!))
            .toList();
      }

      if (filter.toDate != null) {
        filteredSales = filteredSales
            .where((s) => !s.saleDate.isAfter(filter.toDate!))
            .toList();
      }
    }

    if (filteredSales.isEmpty) {
      return const Center(child: Text("No transactions found"));
    }

    final sortedSales = [...filteredSales]
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

    final groupedSales = _groupByDate(sortedSales);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedSales.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedSales.keys.elementAt(index);
        final dailySales = groupedSales[dateKey]!;

        final dailyTotal = dailySales.fold<double>(
          0,
          (sum, sale) => sum + sale.totalAmount,
        );

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
    WidgetRef ref,
    Sale sale,
    VoidCallback onRefresh,
  ) {
    final timeString = DateFormat('hh:mm a').format(sale.saleDate);
    final trxId = "#TRX${sale.id.toString().padLeft(10, '0')}";
    final statusColor = _getStatusColor(sale.paymentStatus);
    final statusText = _getStatusDisplayText(sale.paymentStatus);

    final showActions = sale.paymentStatus.toUpperCase() == 'PENDING' ||
        sale.paymentStatus.toUpperCase() == 'PARTIALLY_PAID';
    final isVoided = sale.paymentStatus.toUpperCase() == 'VOID' ||
        sale.paymentStatus.toUpperCase() == 'VOIDED' ||
        sale.paymentStatus.toUpperCase() == 'CANCELED';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => TransactionDetailsDialog(
            sale: sale,
            onMarkAsPaid: showActions
                ? () async {
                    await ref
                        .read(paymentsNotifierProvider.notifier)
                        .markPaymentAsPaid(sale.id);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    onRefresh();
                  }
                : null,
            onRecordPayment: showActions
                ? (amount, method) async {
                    await ref
                        .read(paymentsNotifierProvider.notifier)
                        .addPartialPayment(
                          saleId: sale.id,
                          customerId: sale.customerId,
                          amount: amount,
                          method: method,
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    onRefresh();
                  }
                : null,
            onMarkAsPending: sale.paymentStatus.toUpperCase() == 'PAID'
                ? () async {
                    await ref
                        .read(paymentsNotifierProvider.notifier)
                        .markPaymentAsPending(sale.id);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    onRefresh();
                  }
                : null,
            onMarkAsPartial: sale.paymentStatus.toUpperCase() == 'PAID'
                ? (paidAmt) async {
                    await ref
                        .read(paymentsNotifierProvider.notifier)
                        .markPaymentAsPartial(
                          saleId: sale.id,
                          paidAmount: paidAmt,
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    onRefresh();
                  }
                : null,
            onReversePayment:
                sale.paymentStatus.toUpperCase() == 'PARTIALLY_PAID'
                    ? () async {
                        await ref
                            .read(paymentsNotifierProvider.notifier)
                            .reversePartialPayment(sale.id);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        onRefresh();
                      }
                    : null,
            onVoid: isVoided
                ? null
                : () async {
                    await ref
                        .read(salesNotifierProvider.notifier)
                        .voidSale(sale.id);
                    // Close the details dialog on success so the
                    // list behind it reflects the updated state.
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    onRefresh();
                  },
          ),
        );
      },
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SAR ${sale.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sale.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
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
                statusText,
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

  // ================= STATUS DISPLAY =================

  String _getStatusDisplayText(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'PAID';
      case 'PENDING':
        return 'PENDING';
      case 'PARTIALLY_PAID':
        return 'PARTIAL';
      case 'VOID':
      case 'VOIDED':
      case 'CANCELED':
        return 'CANCELED';
      default:
        return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  // ================= STATUS COLOR =================

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF1D72D6);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'PARTIALLY_PAID':
        return const Color(0xFFF97316);
      case 'VOID':
      case 'VOIDED':
      case 'CANCELED':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF1D72D6);
    }
  }
}
