import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopx/application/customers/customer_notifier.dart';
import 'package:shopx/application/payments/payments_notifier.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/application/sales/sales_state.dart';
import 'package:shopx/domain/customers/customer.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/widget/admintransaction/transaction_detail_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dedicated Riverpod provider so Bills page has its own isolated sales state
// and doesn't collide with the transaction history page.
// ─────────────────────────────────────────────────────────────────────────────
final customerBillsNotifierProvider =
    NotifierProvider<SalesNotifier, SalesState>(SalesNotifier.new);

class AdminCustomerBillsPage extends HookConsumerWidget {
  const AdminCustomerBillsPage({super.key});

  static const _primaryBlue = Color(0xFF1D72D6);
  static const _bgColor = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── State ──────────────────────────────────────────────────────────────
    final selectedCustomer = useState<Customer?>(null);
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final statusFilter = useState('ALL');
    final fromDate = useState<DateTime?>(null);
    final toDate = useState<DateTime?>(null);
    final isFilterVisible = useState(false);

    // ── Load all customers once ────────────────────────────────────────────
    useEffect(() {
      Future.microtask(() =>
          ref.read(customerNotifierProvider.notifier).fetchAllCustomers());
      return null;
    }, []);

    final customerState = ref.watch(customerNotifierProvider);
    final allCustomers = customerState.customers;

    // ── Sales for selected customer ────────────────────────────────────────
    final billsState = ref.watch(customerBillsNotifierProvider);

    // ── Filtered customer suggestions ─────────────────────────────────────
    final filteredCustomers = useMemoized(() {
      final q = searchQuery.value.trim().toLowerCase();
      if (q.isEmpty) return allCustomers;
      return allCustomers
          .where((c) => c.name.toLowerCase().contains(q))
          .toList();
    }, [allCustomers, searchQuery.value]);

    // ── Filtered bills ─────────────────────────────────────────────────────
    final filteredBills = useMemoized(() {
      var list = List<Sale>.from(billsState.sales);

      // status
      if (statusFilter.value != 'ALL') {
        list = list
            .where((s) =>
                s.paymentStatus.toUpperCase() == statusFilter.value)
            .toList();
      }
      // from date
      if (fromDate.value != null) {
        list = list
            .where((s) => !s.saleDate
                .isBefore(DateTime(fromDate.value!.year,
                    fromDate.value!.month, fromDate.value!.day)))
            .toList();
      }
      // to date
      if (toDate.value != null) {
        final end = DateTime(
            toDate.value!.year, toDate.value!.month, toDate.value!.day, 23, 59, 59);
        list = list.where((s) => !s.saleDate.isAfter(end)).toList();
      }

      list.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      return list;
    }, [
      billsState.sales,
      statusFilter.value,
      fromDate.value,
      toDate.value,
    ]);

    // ── Totals ─────────────────────────────────────────────────────────────
    final totalAmount = filteredBills.fold<double>(
        0, (sum, s) => sum + s.totalAmount);
    final paidCount = filteredBills
        .where((s) => s.paymentStatus.toUpperCase() == 'PAID')
        .length;
    final pendingCount = filteredBills
        .where((s) => s.paymentStatus.toUpperCase() == 'PENDING')
        .length;

    // ── Helpers ────────────────────────────────────────────────────────────
    void loadBills(Customer c) {
      selectedCustomer.value = c;
      searchController.text = c.name;
      searchQuery.value = '';
      ref
          .read(customerBillsNotifierProvider.notifier)
          .fetchSalesByCustomer(c.id);
    }

    void clearCustomer() {
      selectedCustomer.value = null;
      searchController.clear();
      searchQuery.value = '';
      statusFilter.value = 'ALL';
      fromDate.value = null;
      toDate.value = null;
    }

    Future<void> pickDate({required bool isFrom}) async {
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: DateTime.now(),
      );
      if (picked != null) {
        if (isFrom) {
          fromDate.value = picked;
        } else {
          toDate.value = picked;
        }
      }
    }

    // ── UI ─────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: _primaryBlue, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Customer Bills",
          style: TextStyle(
            color: _primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (selectedCustomer.value != null)
            IconButton(
              tooltip: "Filter",
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.tune, color: _primaryBlue),
                  if (statusFilter.value != 'ALL' ||
                      fromDate.value != null ||
                      toDate.value != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () =>
                  isFilterVisible.value = !isFilterVisible.value,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────
          _SearchSection(
            controller: searchController,
            selectedCustomer: selectedCustomer.value,
            filteredCustomers: filteredCustomers,
            onQueryChanged: (q) => searchQuery.value = q,
            onCustomerSelected: loadBills,
            onClear: clearCustomer,
            isLoading: customerState.isLoading,
          ),

          // ── Filter panel ──────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _FilterPanel(
              statusFilter: statusFilter.value,
              fromDate: fromDate.value,
              toDate: toDate.value,
              onStatusChanged: (v) => statusFilter.value = v,
              onPickFrom: () => pickDate(isFrom: true),
              onPickTo: () => pickDate(isFrom: false),
              onClearFilters: () {
                statusFilter.value = 'ALL';
                fromDate.value = null;
                toDate.value = null;
              },
            ),
            crossFadeState: isFilterVisible.value
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          // ── Content area ──────────────────────────────────────────
          Expanded(
            child: selectedCustomer.value == null
                ? _EmptyPrompt(
                    customers: allCustomers,
                    onSelect: loadBills,
                  )
                : billsState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: _primaryBlue))
                    : billsState.error != null
                        ? Center(
                            child: Text(
                              "Error: ${billsState.error}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : filteredBills.isEmpty
                            ? const Center(
                                child: Text(
                                  "No bills found",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              )
                            : _BillsList(
                                customer: selectedCustomer.value!,
                                bills: filteredBills,
                                totalAmount: totalAmount,
                                paidCount: paidCount,
                                pendingCount: pendingCount,
                                onRefresh: () => ref
                                    .read(customerBillsNotifierProvider
                                        .notifier)
                                    .fetchSalesByCustomer(
                                        selectedCustomer.value!.id),
                              ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search section
// ─────────────────────────────────────────────────────────────────────────────
class _SearchSection extends StatelessWidget {
  final TextEditingController controller;
  final Customer? selectedCustomer;
  final List<Customer> filteredCustomers;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Customer> onCustomerSelected;
  final VoidCallback onClear;
  final bool isLoading;

  const _SearchSection({
    required this.controller,
    required this.selectedCustomer,
    required this.filteredCustomers,
    required this.onQueryChanged,
    required this.onCustomerSelected,
    required this.onClear,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: "Search customers by name…",
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF1D72D6)),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onClear,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          // Suggestions list (shown only when typing and no customer selected)
          if (selectedCustomer == null &&
              controller.text.isNotEmpty &&
              filteredCustomers.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filteredCustomers.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (context, i) {
                  final c = filteredCustomers[i];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        c.name.isNotEmpty
                            ? c.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF1D72D6),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: c.phone != null
                        ? Text(c.phone!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey))
                        : null,
                    onTap: () => onCustomerSelected(c),
                  );
                },
              ),
            ),
          ],

          // Selected customer badge
          if (selectedCustomer != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Color(0xFF1D72D6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCustomer!.name,
                      style: const TextStyle(
                        color: Color(0xFF1D72D6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (selectedCustomer!.phone != null)
                    Text(
                      selectedCustomer!.phone!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter panel
// ─────────────────────────────────────────────────────────────────────────────
class _FilterPanel extends StatelessWidget {
  final String statusFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClearFilters;

  const _FilterPanel({
    required this.statusFilter,
    required this.fromDate,
    required this.toDate,
    required this.onStatusChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearFilters,
  });

  static const _statuses = [
    ('ALL', 'All'),
    ('PAID', 'Paid'),
    ('PENDING', 'Pending'),
    ('PARTIALLY_PAID', 'Partial'),
    ('VOIDED', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final hasFilter =
        statusFilter != 'ALL' || fromDate != null || toDate != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Status chips
          const Text(
            "STATUS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _statuses.map((pair) {
              final (value, label) = pair;
              final selected = statusFilter == value;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => onStatusChanged(value),
                selectedColor: const Color(0xFF1D72D6),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                backgroundColor: const Color(0xFFF3F4F6),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Date row
          const Text(
            "DATE RANGE",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateChip(
                  label: fromDate == null
                      ? "From date"
                      : fmt.format(fromDate!),
                  isSet: fromDate != null,
                  onTap: onPickFrom,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateChip(
                  label: toDate == null
                      ? "To date"
                      : fmt.format(toDate!),
                  isSet: toDate != null,
                  onTap: onPickTo,
                ),
              ),
            ],
          ),

          if (hasFilter) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onClearFilters,
              child: const Text(
                "Clear all filters",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSet;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.isSet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSet
              ? const Color(0xFFE3F2FD)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: isSet
              ? Border.all(color: const Color(0xFF1D72D6), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: isSet
                  ? const Color(0xFF1D72D6)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSet
                      ? const Color(0xFF1D72D6)
                      : const Color(0xFF9CA3AF),
                  fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state prompt — shown before any customer is selected
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyPrompt extends StatelessWidget {
  final List<Customer> customers;
  final ValueChanged<Customer> onSelect;

  const _EmptyPrompt({required this.customers, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return customers.isEmpty
        ? const Center(
            child: Text(
              "No customers found",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          )
        : Column(
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.search, size: 56, color: Color(0xFFB0BEC5)),
              const SizedBox(height: 12),
              const Text(
                "Search for a customer above",
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              const Text(
                "Their bills and payment status\nwill appear here.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
              const SizedBox(height: 28),
              // Quick-select first few customers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: customers
                      .take(8)
                      .map((c) => ActionChip(
                            avatar: CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFFE3F2FD),
                              child: Text(
                                c.name.isNotEmpty
                                    ? c.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1D72D6),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            label: Text(c.name,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () => onSelect(c),
                          ))
                      .toList(),
                ),
              ),
            ],
          );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bills list with summary header
// ─────────────────────────────────────────────────────────────────────────────
class _BillsList extends HookConsumerWidget {
  final Customer customer;
  final List<Sale> bills;
  final double totalAmount;
  final int paidCount;
  final int pendingCount;
  final VoidCallback onRefresh;

  const _BillsList({
    required this.customer,
    required this.bills,
    required this.totalAmount,
    required this.paidCount,
    required this.pendingCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary card ────────────────────────────────────────
          _SummaryCard(
            total: totalAmount,
            billCount: bills.length,
            paidCount: paidCount,
            pendingCount: pendingCount,
          ),
          const SizedBox(height: 16),

          // ── Bills ───────────────────────────────────────────────
          ...bills.map((sale) => _BillCard(
                sale: sale,
                onTap: () => _openDetails(context, ref, sale),
              )),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, WidgetRef ref, Sale sale) {
    final status = sale.paymentStatus.toUpperCase();
    final showUpgrade =
        status == 'PENDING' || status == 'PARTIALLY_PAID';
    final showDowngrade = status == 'PAID';
    final isVoided = status == 'VOID' || status == 'VOIDED';

    showDialog(
      context: context,
      builder: (dialogContext) => TransactionDetailsDialog(
        sale: sale,
        // upgrade actions
        onMarkAsPaid: showUpgrade
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
        onRecordPayment: showUpgrade
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
        // downgrade actions
        onMarkAsPending: showDowngrade
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
        onMarkAsPartial: showDowngrade
            ? (paidAmt) async {
                await ref
                    .read(paymentsNotifierProvider.notifier)
                    .markPaymentAsPartial(
                        saleId: sale.id, paidAmount: paidAmt);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                onRefresh();
              }
            : null,
        // cancel
        onVoid: isVoided
            ? null
            : () async {
                await ref
                    .read(salesNotifierProvider.notifier)
                    .voidSale(sale.id);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                onRefresh();
              },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double total;
  final int billCount;
  final int paidCount;
  final int pendingCount;

  const _SummaryCard({
    required this.total,
    required this.billCount,
    required this.paidCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D72D6), Color(0xFF1557B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Billed",
            style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            "SAR ${total.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statPill("$billCount Bills", Colors.white24),
              const SizedBox(width: 8),
              _statPill("$paidCount Paid",
                  Colors.green.withValues(alpha: 0.35)),
              const SizedBox(width: 8),
              _statPill("$pendingCount Pending",
                  Colors.orange.withValues(alpha: 0.35)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual bill card
// ─────────────────────────────────────────────────────────────────────────────
class _BillCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;

  const _BillCard({required this.sale, required this.onTap});

  static Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF1D72D6);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'PARTIALLY_PAID':
        return const Color(0xFFF97316);
      case 'VOID':
      case 'VOIDED':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  static String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'PAID':
        return 'PAID';
      case 'PENDING':
        return 'PENDING';
      case 'PARTIALLY_PAID':
        return 'PARTIAL';
      case 'VOID':
      case 'VOIDED':
        return 'CANCELLED';
      default:
        return s.toUpperCase().replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a').format(sale.saleDate);
    final date = DateFormat('dd MMM yyyy').format(sale.saleDate);
    final trxId = "#TRX${sale.id.toString().padLeft(10, '0')}";
    final color = _statusColor(sale.paymentStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left colour bar
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            // Info
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
                    "$date · $time",
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trxId,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusLabel(sale.paymentStatus),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
