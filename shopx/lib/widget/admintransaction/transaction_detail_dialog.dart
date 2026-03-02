import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shopx/application/settings/settings_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/domain/reciept/reciept_from_sale.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/infrastructure/pdf/pdf_receipt_service.dart';
import 'package:shopx/presentation/cart/cart_screen.dart';
import 'package:shopx/presentation/printpreview/reciept_preview_screen.dart';

class TransactionDetailsDialog extends HookConsumerWidget {
  final Sale sale;
  // final VoidCallback? onMarkAsPaid;
  // final VoidCallback? onCancelSale;
  final Future<void> Function()? onMarkAsPaid;
  final Future<void> Function()? onCancelSale;

  const TransactionDetailsDialog({
    super.key,
    required this.sale,
    this.onMarkAsPaid,
    this.onCancelSale, // 👈 ADD
  });

  // bool get _isPending => sale.paymentStatus.toUpperCase() == 'PENDING';

  bool get _isPending =>
      sale.paymentStatus.toUpperCase() == 'PENDING' &&
      sale.saleStatus != 'voided';

  bool get _isVoided => sale.saleStatus == 'voided';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
//     final settingsState = ref.watch(settingsNotifierProvider);
// final companySettings = settingsState.settings!;


  // 🔒 DEFENSIVE LOAD: ensure settings exist when dialog opens
  useEffect(() {
    Future.microtask(() {
      ref.read(settingsNotifierProvider.notifier).loadOnce();
    });
    return null;
  }, []);

final settingsState = ref.watch(settingsNotifierProvider);

if (settingsState.isLoading || settingsState.settings == null) {
  return const Dialog(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

final companySettings = settingsState.settings!;


    final isSubmitting = useState(false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          SingleChildScrollView(
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

                const SizedBox(height: 20),

                // ================= ITEMS =================
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
                    final unitPrice = item.totalPrice / item.quantity;

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
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                "SAR ${item.totalPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
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

                // ================= PREVIEW RECEIPT =================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text("Preview Receipt"),
                    onPressed: () {
                      final receipt = receiptFromSale(sale,companySettings);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecieptPreviewScreen(receipt: receipt),
                        ),
                      );
                    },
                  ),
                ),






                //new code 

                kHeight12,

// ================= SEND RECEIPT =================
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.send),
    label: const Text("Send Receipt"),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      backgroundColor: const Color(0xFFE3F2FD),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    onPressed: () async {
      // 🔒 SAFETY: don’t allow for voided sales
      if (_isVoided) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot send receipt for cancelled sale."),
          ),
        );
        return;
      }

      // ✅ Build receipt from THIS sale
      final receipt = receiptFromSale(sale, companySettings);

      // ✅ Generate PDF
      final file = await PdfReceiptService.generateReceiptPdf(
        receipt: receipt,
        settings: companySettings,
      );

      // ✅ Share (WhatsApp / Gmail / etc.)
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice ${sale.id}',
      );
    },
  ),
),


kHeight16,

// ================= EDIT SALE =================
if (!_isVoided)
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        "Edit Sale",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      onPressed: () {
        Navigator.of(context).pop(); // close dialog

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CartScreen(saleToEdit: sale),
          ),
        );
      },
    ),
  ),

kHeight16,

if (!_isVoided && _isPending)
  _markAsPaidButton(context, isSubmitting),

kHeight20,

if (!_isVoided && onCancelSale != null)
  _cancelSaleButton(context, isSubmitting),

                // kHeight16,

                // // if (_isPending) _markAsPaidButton(context),
                // if (!_isVoided && _isPending)
                //   _markAsPaidButton(context, isSubmitting),
                  

                // kHeight20,

                // if (!_isVoided && onCancelSale != null)
                //   _cancelSaleButton(context, isSubmitting),

                if (_isVoided)
                  const Text(
                    "This sale has been cancelled.",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (isSubmitting.value)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // ================= HEADER =================

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Transaction Details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ================= INFO ROW =================

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ================= AMOUNT ROW =================

  Widget _amountRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          ),
          Text(
            "SAR ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATUS CHIP =================

  // Widget _statusChip() {
  //   final status = sale.paymentStatus.toUpperCase();

  //   Color bgColor;
  //   switch (status) {
  //     case 'PAID':
  //       bgColor = const Color(0xFF1D72D6);
  //       break;
  //     case 'PENDING':
  //       bgColor = const Color(0xFFF59E0B);
  //       break;
  //     case 'VOID':
  //       bgColor = const Color(0xFF9CA3AF);
  //       break;
  //     default:
  //       bgColor = const Color(0xFF1D72D6);
  //   }

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: bgColor,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Text(
  //       status,
  //       style: const TextStyle(
  //         color: Colors.white,
  //         fontSize: 12,
  //         fontWeight: FontWeight.bold,
  //         letterSpacing: 0.5,
  //       ),
  //     ),
  //   );
  // }

  Widget _statusChip() {
    final bool isVoided = sale.saleStatus == 'voided';

    final String label = isVoided
        ? 'CANCELLED'
        : sale.paymentStatus.toUpperCase();

    final Color bgColor = isVoided
        ? Colors.red
        : sale.paymentStatus.toUpperCase() == 'PAID'
        ? const Color(0xFF1D72D6)
        : const Color(0xFFF59E0B);

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

  // ================= MARK AS PAID =================

  Widget _markAsPaidButton(
    BuildContext context,
    ValueNotifier<bool> isSubmitting,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // onPressed: isSubmitting.value || onMarkAsPaid == null
        //     ? null
        //     : () async {
        //         isSubmitting.value = true;
        //         await onMarkAsPaid!();
        //       },
        onPressed: isSubmitting.value || onMarkAsPaid == null
            ? null
            : () async {
                try {
                  isSubmitting.value = true;
                  await onMarkAsPaid!();
                  Navigator.of(context).pop();
                } finally {
                  isSubmitting.value = false;
                }
              },

        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF1D72D6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSubmitting.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Mark as Paid",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _cancelSaleButton(
    BuildContext context,
    ValueNotifier<bool> isSubmitting,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // onPressed: isSubmitting.value || onCancelSale == null
        //     ? null
        //     : () async {
        //         isSubmitting.value = true;
        //         await onCancelSale!();
        //       },
        onPressed: isSubmitting.value || onCancelSale == null
            ? null
            : () async {
                try {
                  isSubmitting.value = true;
                  await onCancelSale!();
                  Navigator.of(context).pop(); // ✅ CORRECT OWNER
                } finally {
                  isSubmitting.value = false;
                }
              },

        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSubmitting.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Cancel Sale",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
