import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopx/domain/config/company_config.dart';
import 'package:shopx/domain/reciept/receipt_data.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/presentation/printpreview/reciept_preview_screen.dart';

class TransactionDetailsDialog extends StatelessWidget {
  final Sale sale;

  // upgrade actions (pending / partial → paid)
  final VoidCallback? onMarkAsPaid;
  final void Function(double amount, String method)? onRecordPayment;

  // downgrade actions (paid → pending / partial)  ← NEW
  final VoidCallback? onMarkAsPending;
  final void Function(double paidAmount)? onMarkAsPartial;

  // admin-only cancel
  final VoidCallback? onVoid;

  final double? paidAmount;
  final double? balanceAmount;

  const TransactionDetailsDialog({
    super.key,
    required this.sale,
    this.onMarkAsPaid,
    this.onRecordPayment,
    this.onMarkAsPending,
    this.onMarkAsPartial,
    this.onVoid,
    this.paidAmount,
    this.balanceAmount,
  });

  // ── Status helpers ────────────────────────────────────────────────────────
  String get _status => sale.paymentStatus.toUpperCase();
  bool get _isPaid => _status == 'PAID';
  bool get _isPending => _status == 'PENDING';
  bool get _isPartiallyPaid => _status == 'PARTIALLY_PAID';
  bool get _isVoided => _status == 'VOID' || _status == 'VOIDED';

  // show upgrade buttons for unpaid statuses
  bool get _showUpgradeActions => _isPending || _isPartiallyPaid;
  // show downgrade buttons only when fully paid
  bool get _showDowngradeActions => _isPaid;

  // ── Print preview ─────────────────────────────────────────────────────────
  void _openPrintPreview(BuildContext context) {
    final receiptData = ReceiptData(
      companyNameEn: CompanyConfig.companyNameEn,
      companyNameAr: CompanyConfig.companyNameAr,
      city: CompanyConfig.city,
      country: CompanyConfig.country,
      crNumber: CompanyConfig.crNumber,
      vatNumber: CompanyConfig.vatNumber,
      mobile: CompanyConfig.mobile,
      invoiceNumber: sale.id.toString(),
      invoiceDate: sale.saleDate,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      items: sale.items
          .map((i) => ReceiptItem(
                nameEn: i.productName,
                nameAr: i.productNameAr,
                unitPrice: i.unitPrice,
                quantity: i.quantity,
              ))
          .toList(),
      subTotal: sale.subtotalAmount,
      vatPercentage: sale.vatPercentage,
      vatAmount: sale.vatAmount,
      netTotal: sale.totalAmount,
      discount: sale.discountAmount,
      qrPayload: 'Invoice:${sale.id}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecieptPreviewScreen(receipt: receiptData),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 20),

            _infoRow("Customer", sale.customerName),
            _infoRow("Phone", sale.customerPhone),
            _infoRow("Salesperson", sale.salespersonName),
            _infoRow(
              "Date",
              DateFormat('dd MMM yyyy, hh:mm a').format(sale.saleDate),
            ),

            const Divider(height: 32),

            _amountRow("Subtotal", sale.subtotalAmount),
            _amountRow("Discount", sale.discountAmount),
            _amountRow(
              "VAT (${sale.vatPercentage.toStringAsFixed(0)}%)",
              sale.vatAmount,
            ),

            const Divider(height: 24),

            _amountRow("Total Amount", sale.totalAmount, isBold: true),

            if (_isPartiallyPaid || paidAmount != null) ...[
              const SizedBox(height: 8),
              _amountRow("Paid", paidAmount ?? 0, color: Colors.green),
              _amountRow(
                "Balance Due",
                balanceAmount ?? (sale.totalAmount - (paidAmount ?? 0)),
                color: Colors.red,
                isBold: true,
              ),
            ],

            const SizedBox(height: 20),

            // ── Items ──────────────────────────────────────────────
            const Text(
              "Items",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (sale.items.isEmpty)
              const Text(
                "No items available",
                style: TextStyle(color: Colors.grey),
              )
            else
              ...sale.items.map((item) {
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
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                          Text(
                            "SAR ${item.totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            _statusChip(),

            const SizedBox(height: 24),

            // ── UPGRADE: pending / partial → paid ──────────────────
            if (_showUpgradeActions) ...[
              if (onRecordPayment != null)
                _outlinedBtn(
                  context: context,
                  label: "Record Partial Payment",
                  color: const Color(0xFF1D72D6),
                  onTap: () => _showRecordPaymentDialog(context),
                ),
              if (onRecordPayment != null && onMarkAsPaid != null)
                const SizedBox(height: 12),
              if (onMarkAsPaid != null)
                _filledBtn(
                  label: "Mark as Fully Paid",
                  color: Colors.green,
                  onTap: onMarkAsPaid!,
                ),
              const SizedBox(height: 12),
            ],

            // ── DOWNGRADE: paid → pending / partial ─────────────────
            if (_showDowngradeActions) ...[
              _sectionLabel("Adjust Payment Status"),
              const SizedBox(height: 10),
              _outlinedBtn(
                context: context,
                label: "Mark as Unpaid (Pending)",
                color: const Color(0xFFF59E0B),
                icon: Icons.undo_rounded,
                onTap: () => _confirmMarkAsPending(context),
              ),
              const SizedBox(height: 10),
              _outlinedBtn(
                context: context,
                label: "Mark as Partially Paid",
                color: const Color(0xFFF97316),
                icon: Icons.tune_rounded,
                onTap: () => _showMarkAsPartialDialog(context),
              ),
              const SizedBox(height: 12),
            ],

            // ── Cancel Bill (admin, any non-voided status) ──────────
            if (!_isVoided && onVoid != null) ...[
              _outlinedBtn(
                context: context,
                label: "Cancel Bill",
                color: Colors.red,
                icon: Icons.cancel_outlined,
                onTap: () => _showCancelConfirmation(context),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Transaction Details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => _openPrintPreview(context),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text("Preview"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1D72D6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  // ── Info row ──────────────────────────────────────────────────────────────
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Amount row ────────────────────────────────────────────────────────────
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

  // ── Status chip ───────────────────────────────────────────────────────────
  Widget _statusChip() {
    Color bgColor;
    String displayText;

    switch (_status) {
      case 'PAID':
        bgColor = const Color(0xFF1D72D6);
        displayText = 'PAID';
        break;
      case 'PENDING':
        bgColor = const Color(0xFFF59E0B);
        displayText = 'PENDING';
        break;
      case 'PARTIALLY_PAID':
        bgColor = const Color(0xFFF97316);
        displayText = 'PARTIAL';
        break;
      case 'VOID':
      case 'VOIDED':
        bgColor = const Color(0xFF9CA3AF);
        displayText = 'VOIDED';
        break;
      default:
        bgColor = const Color(0xFF1D72D6);
        displayText = _status.replaceAll('_', ' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
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

  // ── Reusable button builders ──────────────────────────────────────────────
  Widget _outlinedBtn({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(color: color),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filledBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  // ── Confirm: paid → pending ───────────────────────────────────────────────
  void _confirmMarkAsPending(BuildContext context) {
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
            onPressed: () {
              Navigator.of(ctx).pop();
              onMarkAsPending?.call();
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
  void _showMarkAsPartialDialog(BuildContext context) {
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
                  "Total: SAR ${sale.totalAmount.toStringAsFixed(2)}",
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
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount =
                      double.tryParse(controller.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Enter a valid paid amount")),
                    );
                    return;
                  }
                  if (amount >= sale.totalAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Amount must be less than the total. Use Mark as Paid instead.")),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  onMarkAsPartial?.call(amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Confirm",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Cancel bill confirmation ───────────────────────────────────────────────
  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text("Cancel Bill?",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You are about to void Invoice #${sale.id.toString().padLeft(10, '0')}.",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                "⚠️  This action cannot be undone. The bill will be marked as VOIDED and all payment records will be preserved for audit.",
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Keep Bill"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onVoid?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Yes, Cancel Bill",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Record Payment dialog (upgrade: pending/partial → paid) ───────────────
  void _showRecordPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    String selectedMethod = "cash";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text("Record Payment",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (balanceAmount != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      "Balance due: SAR ${balanceAmount!.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
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
                  initialValue: selectedMethod,
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
                onPressed: () {
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
                  onRecordPayment?.call(amount, selectedMethod);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D72D6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Submit",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
