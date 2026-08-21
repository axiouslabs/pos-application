import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopx/domain/config/company_config.dart';
import 'package:shopx/domain/reciept/receipt_data.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/presentation/printpreview/reciept_preview_screen.dart';

class TransactionDetailsDialog extends StatefulWidget {
  final Sale sale;

  final VoidCallback? onMarkAsPaid;
  final void Function(double amount, String method)? onRecordPayment;

  final VoidCallback? onMarkAsPending;
  final void Function(double paidAmount)? onMarkAsPartial;

  final VoidCallback? onReversePayment;

  final Future<void> Function()? onVoid;

  final double? paidAmount;
  final double? balanceAmount;

  const TransactionDetailsDialog({
    super.key,
    required this.sale,
    this.onMarkAsPaid,
    this.onRecordPayment,
    this.onMarkAsPending,
    this.onMarkAsPartial,
    this.onReversePayment,
    this.onVoid,
    this.paidAmount,
    this.balanceAmount,
  });

  @override
  State<TransactionDetailsDialog> createState() =>
      _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState extends State<TransactionDetailsDialog> {
  String? _localStatusOverride;
  bool _isVoiding = false;

  String get _status {
    if (_localStatusOverride != null) {
      return _localStatusOverride!.toUpperCase();
    }
    return widget.sale.paymentStatus.toUpperCase();
  }

  bool get _isPaid => _status == 'PAID';
  bool get _isPending => _status == 'PENDING';
  bool get _isPartiallyPaid => _status == 'PARTIALLY_PAID';
  bool get _isVoided =>
      _status == 'VOID' ||
      _status == 'VOIDED' ||
      _status == 'CANCELED';

  bool get _showUpgradeActions => _isPending || _isPartiallyPaid;
  bool get _showDowngradeActions => _isPaid;

  void _openPrintPreview(BuildContext context) {
    final receiptData = ReceiptData(
      companyNameEn: CompanyConfig.companyNameEn,
      companyNameAr: CompanyConfig.companyNameAr,
      city: CompanyConfig.city,
      country: CompanyConfig.country,
      crNumber: CompanyConfig.crNumber,
      vatNumber: CompanyConfig.vatNumber,
      mobile: CompanyConfig.mobile,
      invoiceNumber: widget.sale.id.toString(),
      invoiceDate: widget.sale.saleDate,
      customerName: widget.sale.customerName,
      customerPhone: widget.sale.customerPhone,
      items: widget.sale.items
          .map((i) => ReceiptItem(
                nameEn: i.productName,
                nameAr: i.productNameAr,
                unitPrice: i.unitPrice,
                quantity: i.quantity,
              ))
          .toList(),
      subTotal: widget.sale.subtotalAmount,
      vatPercentage: widget.sale.vatPercentage,
      vatAmount: widget.sale.vatAmount,
      netTotal: widget.sale.totalAmount,
      discount: widget.sale.discountAmount,
      qrPayload: 'Invoice:${widget.sale.id}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecieptPreviewScreen(receipt: receiptData),
      ),
    );
  }

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
            if (_isVoided) _readOnlyBanner(),
            _infoRow("Customer", widget.sale.customerName),
            _infoRow("Phone", widget.sale.customerPhone),
            _infoRow("Salesperson", widget.sale.salespersonName),
            _infoRow(
              "Date",
              DateFormat('dd MMM yyyy, hh:mm a').format(widget.sale.saleDate),
            ),

            const Divider(height: 32),

            _amountRow("Subtotal", widget.sale.subtotalAmount),
            _amountRow("Discount", widget.sale.discountAmount),
            _amountRow(
              "VAT (${widget.sale.vatPercentage.toStringAsFixed(0)}%)",
              widget.sale.vatAmount,
            ),

            const Divider(height: 24),

            _amountRow("Total Amount", widget.sale.totalAmount, isBold: true),

            if (_isPartiallyPaid || widget.paidAmount != null) ...[
              const SizedBox(height: 8),
              _amountRow("Paid", widget.paidAmount ?? 0, color: Colors.green),
              _amountRow(
                "Balance Due",
                widget.balanceAmount ??
                    (widget.sale.totalAmount - (widget.paidAmount ?? 0)),
                color: Colors.red,
                isBold: true,
              ),
            ],

            const SizedBox(height: 20),

            const Text(
              "Items",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (widget.sale.items.isEmpty)
              const Text(
                "No items available",
                style: TextStyle(color: Colors.grey),
              )
            else
              ...widget.sale.items.map((item) {
                final unitPrice = item.quantity > 0
                    ? item.totalPrice / item.quantity
                    : 0.0;
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

            if (_showUpgradeActions && !_isVoided) ...[
              if (widget.onRecordPayment != null)
                _outlinedBtn(
                  context: context,
                  label: "Record Partial Payment",
                  color: const Color(0xFF1D72D6),
                  onTap: () => _showRecordPaymentDialog(context),
                ),
              if (widget.onRecordPayment != null) const SizedBox(height: 12),
              if (_isPartiallyPaid && widget.onReversePayment != null) ...[
                _outlinedBtn(
                  context: context,
                  label: "Reverse Payment",
                  color: Colors.red,
                  icon: Icons.undo_rounded,
                  onTap: () => _confirmReversePayment(context),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.onMarkAsPaid != null)
                _filledBtn(
                  label: "Mark as Fully Paid",
                  color: Colors.green,
                  onTap: widget.onMarkAsPaid!,
                ),
              const SizedBox(height: 12),
            ],

            if (_showDowngradeActions && !_isVoided) ...[
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

            if (!_isVoided && widget.onVoid != null) ...[
              if (_isVoiding)
                _voidingProgressBtn(context)
              else
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

  Widget _readOnlyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Row(
        children: const [
          Icon(Icons.lock_outline, size: 18, color: Color(0xFF6B7280)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "This transaction has been canceled and is now read-only.",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      case 'CANCELED':
        bgColor = const Color(0xFF9CA3AF);
        displayText = 'CANCELED';
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

  Widget _outlinedBtn({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    IconData? icon,
  }) {
    final isDisabled = onTap == null;
    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: BorderSide(color: isDisabled ? Colors.grey : color),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: isDisabled ? Colors.grey : color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDisabled ? Colors.grey : color),
              ),
            ],
          ),
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

  Widget _voidingProgressBtn(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(color: Colors.red.shade200),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Canceling Bill...",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400),
            ),
          ],
        ),
      ),
    );
  }

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
              widget.onMarkAsPending?.call();
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
                  "Total: SAR ${widget.sale.totalAmount.toStringAsFixed(2)}",
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
                  if (amount >= widget.sale.totalAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Amount must be less than the total. Use Mark as Paid instead.")),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  widget.onMarkAsPartial?.call(amount);
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
              "You are about to void Invoice #${widget.sale.id.toString().padLeft(10, '0')}.",
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (widget.onVoid != null) {
                // ⚡ OPTIMISTIC UPDATE — apply UI change immediately so user
                // sees CANCELED + read-only state right away, even if the
                // backend call takes a long time (stock reversal can be slow).
                setState(() {
                  _localStatusOverride = 'voided';
                  _isVoiding = true;
                });
                try {
                  await widget.onVoid!();
                  if (mounted) {
                    setState(() {
                      _isVoiding = false;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    // Roll back optimistic state on failure
                    setState(() {
                      _localStatusOverride = null;
                      _isVoiding = false;
                    });
                    final msg = e is Exception
                        ? e.toString().replaceFirst('Exception: ', '')
                        : e.toString();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to cancel bill: $msg"),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              }
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

  void _showRecordPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    String selectedMethod = "cash";

    final alreadyPaid = widget.paidAmount ?? 0.0;
    final remaining = widget.balanceAmount ??
        (widget.sale.totalAmount - alreadyPaid);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text("Record Payment",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _summaryLine("Total Amount",
                          "SAR ${widget.sale.totalAmount.toStringAsFixed(2)}",
                          bold: true),
                      const SizedBox(height: 4),
                      _summaryLine("Already Paid",
                          "SAR ${alreadyPaid.toStringAsFixed(2)}",
                          color: Colors.green),
                      const Divider(height: 12),
                      _summaryLine("Remaining Balance",
                          "SAR ${remaining.toStringAsFixed(2)}",
                          color: Colors.red, bold: true),
                    ],
                  ),
                ),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Payment Amount (SAR)",
                    hintText: "Max: ${remaining.toStringAsFixed(2)}",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: InputDecoration(
                    labelText: "Payment Method",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
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
                      const SnackBar(content: Text("Enter a valid amount")),
                    );
                    return;
                  }
                  if (amount > remaining + 0.001) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "Amount exceeds remaining balance of SAR ${remaining.toStringAsFixed(2)}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  widget.onRecordPayment?.call(amount, selectedMethod);
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

  Widget _summaryLine(String label, String value,
      {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13,
              color: color ?? const Color(0xFF374151),
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            )),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              color: color ?? const Color(0xFF374151),
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            )),
      ],
    );
  }

  void _confirmReversePayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.undo_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text("Reverse Payment?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          "This will remove all recorded partial payments for this invoice.\n\n"
          "The paid amount will be reset to SAR 0.00 and the status will return to PENDING.",
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
              widget.onReversePayment?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Yes, Reverse",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
