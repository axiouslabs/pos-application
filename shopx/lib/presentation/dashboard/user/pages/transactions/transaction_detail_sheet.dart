import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopx/application/payments/payments_notifier.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/domain/config/company_config.dart';
import 'package:shopx/domain/reciept/receipt_data.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/presentation/printpreview/reciept_preview_screen.dart';

class TransactionDetailSheet extends HookConsumerWidget {
  final Sale sale;
  final ScrollController scrollController;

  const TransactionDetailSheet({
    super.key,
    required this.sale,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch full invoice (with items) when the sheet opens
    useEffect(() {
      Future.microtask(() {
        ref.read(salesNotifierProvider.notifier).fetchSaleById(sale.id);
      });
      return null;
    }, []);

    final salesState = ref.watch(salesNotifierProvider);
    final paymentsState = ref.watch(paymentsNotifierProvider);

    // Use the freshly fetched invoice if available, else fall back to the list item
    final invoice = salesState.sale?.id == sale.id ? salesState.sale! : sale;
    final items = invoice.items;

    final status = invoice.paymentStatus.toUpperCase();
    final isPending = status == 'PENDING';
    final isPartiallyPaid = status == 'PARTIALLY_PAID';
    final showPaymentActions = isPending || isPartiallyPaid;

    // Paid / balance amounts from the payments notifier (set after partial payment)
    final paidAmount = paymentsState.summary?.paidAmount;
    final balanceAmount = paymentsState.summary?.balance;

    const primaryBlue = Color(0xFF1D72D6);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // ── Handle bar ──────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header row: title + Print Preview ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Transaction Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _openPrintPreview(context, invoice),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text("Preview"),
                style: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Info rows ────────────────────────────────────────────
          _row("Invoice ID", "#TRX${invoice.id.toString().padLeft(10, '0')}"),
          _row("Customer", invoice.customerName),
          _row(
            "Date",
            DateFormat('dd MMM yyyy, hh:mm a').format(invoice.saleDate),
          ),
          _row("Salesperson", invoice.salespersonName),

          const Divider(height: 28),

          // ── Amounts ──────────────────────────────────────────────
          _amountRow("Subtotal", invoice.subtotalAmount),
          _amountRow("Discount", invoice.discountAmount),
          _amountRow(
            "VAT (${invoice.vatPercentage.toStringAsFixed(0)}%)",
            invoice.vatAmount,
          ),

          const Divider(height: 20),
          _amountRow("Total Amount", invoice.totalAmount, isBold: true),

          if (isPartiallyPaid || paidAmount != null) ...[
            const SizedBox(height: 6),
            _amountRow(
              "Paid",
              paidAmount ?? 0,
              color: Colors.green,
            ),
            _amountRow(
              "Balance Due",
              balanceAmount ?? (invoice.totalAmount - (paidAmount ?? 0)),
              color: Colors.red,
              isBold: true,
            ),
          ],

          const SizedBox(height: 20),

          // ── Status chip ──────────────────────────────────────────
          _statusChip(status),

          const SizedBox(height: 24),

          // ── Items ────────────────────────────────────────────────
          const Text(
            "Items",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (salesState.isLoading && items.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (items.isEmpty)
            const Text(
              "No items available",
              style: TextStyle(color: Colors.grey),
            )
          else
            ...items.map((item) {
              final unitPrice =
                  item.quantity > 0 ? item.totalPrice / item.quantity : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${item.quantity} × SAR ${unitPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "SAR ${item.totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 30),

          // ── Payment action buttons (pending / partially paid only) ─
          if (showPaymentActions) ...[
            _actionButton(
              label: "Record Partial Payment",
              color: primaryBlue,
              outlined: true,
              onTap: () => _showRecordPaymentDialog(context, ref, invoice),
            ),
            const SizedBox(height: 12),
            _actionButton(
              label: "Mark as Fully Paid",
              color: Colors.green,
              onTap: () async {
                await ref
                    .read(paymentsNotifierProvider.notifier)
                    .markPaymentAsPaid(invoice.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],

          // ── Downgrade actions (paid only) ────────────────────────
          if (status == 'PAID') ...[
            _sectionLabel("Adjust Payment Status"),
            const SizedBox(height: 10),
            _actionButton(
              label: "Mark as Unpaid (Pending)",
              color: const Color(0xFFF59E0B),
              outlined: true,
              icon: Icons.undo_rounded,
              onTap: () => _confirmMarkAsPending(context, ref, invoice),
            ),
            const SizedBox(height: 10),
            _actionButton(
              label: "Mark as Partially Paid",
              color: const Color(0xFFF97316),
              outlined: true,
              icon: Icons.tune_rounded,
              onTap: () => _showMarkAsPartialDialog(context, ref, invoice),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Print preview ─────────────────────────────────────────────────────────
  void _openPrintPreview(BuildContext context, Sale s) {
    final receiptItems = s.items
        .map((item) => ReceiptItem(
              nameEn: item.productName,
              nameAr: item.productNameAr,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
            ))
        .toList();

    final receiptData = ReceiptData(
      companyNameEn: CompanyConfig.companyNameEn,
      companyNameAr: CompanyConfig.companyNameAr,
      city: CompanyConfig.city,
      country: CompanyConfig.country,
      crNumber: CompanyConfig.crNumber,
      vatNumber: CompanyConfig.vatNumber,
      mobile: CompanyConfig.mobile,
      invoiceNumber: s.id.toString(),
      invoiceDate: s.saleDate,
      customerName: s.customerName,
      customerPhone: s.customerPhone,
      items: receiptItems,
      subTotal: s.subtotalAmount,
      vatPercentage: s.vatPercentage,
      vatAmount: s.vatAmount,
      netTotal: s.totalAmount,
      discount: s.discountAmount,
      qrPayload: 'Invoice:${s.id}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecieptPreviewScreen(receipt: receiptData),
      ),
    );
  }

  // ── Status chip ───────────────────────────────────────────────────────────
  Widget _statusChip(String status) {
    Color bgColor;
    String label;

    switch (status) {
      case 'PAID':
        bgColor = const Color(0xFF1D72D6);
        label = 'PAID';
        break;
      case 'PENDING':
        bgColor = const Color(0xFFF59E0B);
        label = 'PENDING';
        break;
      case 'PARTIALLY_PAID':
        bgColor = const Color(0xFFF97316);
        label = 'PARTIAL';
        break;
      case 'VOID':
      case 'VOIDED':
        bgColor = const Color(0xFF9CA3AF);
        label = 'VOIDED';
        break;
      default:
        bgColor = const Color(0xFF1D72D6);
        label = status.replaceAll('_', ' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color ?? const Color(0xFF374151),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "SAR ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
    IconData? icon,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: outlined ? color : Colors.white),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: outlined ? color : Colors.white,
          ),
        ),
      ],
    );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: BorderSide(color: color),
            shape: shape,
          ),
          child: child,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color,
          shape: shape,
        ),
        child: child,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Record partial payment dialog ─────────────────────────────────────────
  void _showRecordPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Sale s,
  ) {
    final amountController = TextEditingController();
    String selectedMethod = "cash";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Record Payment",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Amount (SAR)",
                    hintText: "Enter payment amount",
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: InputDecoration(
                    labelText: "Payment Method",
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "cash", child: Text("Cash")),
                    DropdownMenuItem(
                        value: "card", child: Text("Card / Bank")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedMethod = val);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Enter a valid amount")),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();

                  await ref
                      .read(paymentsNotifierProvider.notifier)
                      .addPartialPayment(
                        saleId: s.id,
                        customerId: s.customerId,
                        amount: amount,
                        method: selectedMethod,
                      );

                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D72D6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Confirm: paid → pending ───────────────────────────────────────────────
  void _confirmMarkAsPending(BuildContext context, WidgetRef ref, Sale s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Mark as Unpaid?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "This will remove all recorded payments for this invoice and set its status back to Pending.\n\nAre you sure?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(paymentsNotifierProvider.notifier)
                  .markPaymentAsPending(s.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Yes, Mark Unpaid",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Dialog: paid → partially paid ────────────────────────────────────────
  void _showMarkAsPartialDialog(BuildContext context, WidgetRef ref, Sale s) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text("Set Partial Payment",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total: SAR ${s.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Amount Already Paid (SAR)",
                    hintText: "e.g. 500.00",
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The remainder will become the outstanding balance.",
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(controller.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Enter a valid paid amount")),
                    );
                    return;
                  }
                  if (amount >= s.totalAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Amount must be less than the total. Use Mark as Paid instead.")),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  await ref
                      .read(paymentsNotifierProvider.notifier)
                      .markPaymentAsPartial(
                        saleId: s.id,
                        paidAmount: amount,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Confirm",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
