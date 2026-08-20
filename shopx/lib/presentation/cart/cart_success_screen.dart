import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shopx/application/customers/customer_notifier.dart';

// YOUR Sales Notifier
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/domain/config/company_config.dart';
import 'package:shopx/domain/reciept/receipt_data.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/infrastructure/pdf/pdf_receipt_service.dart';
import 'package:shopx/infrastructure/printer/thermal_printer_service.dart';
import 'package:shopx/presentation/dashboard/user/user_dashboard.dart';
import 'package:shopx/presentation/printpreview/reciept_preview_screen.dart';

class SuccessScreen extends HookConsumerWidget {
  final int saleId;
  const SuccessScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🔥 SUCCESS SCREEN SALE ID = $saleId");

    // ---------------------------
    // 2. Fetch sale details
    // ---------------------------
    final futureSale = useMemoized(
      () => ref.read(salesNotifierProvider.notifier).getSale(saleId),
    );

    final saleSnapshot = useFuture(futureSale);

    if (saleSnapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    print("🔥 SUCCESS SCREEN RECEIVED sale = ${saleSnapshot.data}");

    if (!saleSnapshot.hasData) {
      return const Scaffold(body: Center(child: Text("Failed to load sale")));
    }

    final Sale sale = saleSnapshot.data!;

    final futureCustomer = useMemoized(() {
      return ref
          .read(customerNotifierProvider.notifier)
          .fetchCustomerById(sale.customerId);
    });
    final customerSnapshot = useFuture(futureCustomer);

    if (customerSnapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!customerSnapshot.hasData) {
      return const Scaffold(
        body: Center(child: Text("Failed to load customer")),
      );
    }

    final customer = customerSnapshot.data!;

    // ---------------------------
    // Local email input
    // ---------------------------
    final emailController = useTextEditingController();

    //SHARE PDF
    Future<void> onSendPdfReceipt() async {
      final receiptItems = sale.items.map((item) {
        return ReceiptItem(
          nameEn: item.productName,
          nameAr: item.productNameAr,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
        );
      }).toList();

      final double subTotal = sale.subtotalAmount;
      final double vatAmount = sale.vatAmount;
      const double vatPercentage = 15.0;

      final receipt = ReceiptData(
        companyNameEn: CompanyConfig.companyNameEn,
        companyNameAr: CompanyConfig.companyNameAr,
        city: CompanyConfig.city,
        country: CompanyConfig.country,
        crNumber: CompanyConfig.crNumber,
        vatNumber: CompanyConfig.vatNumber,
        mobile: CompanyConfig.mobile,
        customerAddress: customer.address,
        customerPhone: customer.phone,
        discount: sale.discountAmount,
        invoiceNumber: sale.id.toString(),
        invoiceDate: sale.saleDate,
        customerName: sale.customerName,
        items: receiptItems,
        subTotal: subTotal,
        vatPercentage: vatPercentage,
        vatAmount: vatAmount,
        netTotal: sale.totalAmount,
        qrPayload: 'Invoice:${sale.id}',
      );

      final file = await PdfReceiptService.generateReceiptPdf(receipt);

      await Share.shareXFiles([XFile(file.path)], text: 'Invoice ${sale.id}');
    }

    // ---------------------------
    // 5. Thermal Printer ESC/POS
    // ---------------------------

    void onOpenReceiptPreview() {
      final receiptItems = sale.items.map((item) {
        return ReceiptItem(
          nameEn: item.productName,
          nameAr: item.productNameAr,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
        );
      }).toList();

      final double subTotal = sale.subtotalAmount;
      final double vatAmount = sale.vatAmount;
      const double vatPercentage = 15.0;
      final double netTotal = sale.totalAmount;

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

        items: receiptItems,
        subTotal: subTotal,
        discount: sale.discountAmount,
        vatPercentage: vatPercentage,
        vatAmount: vatAmount,
        netTotal: netTotal,

        qrPayload: 'Invoice:${sale.id}',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecieptPreviewScreen(receipt: receiptData),
        ),
      );
    }

    // ---------------------------
    // 6. Next Order
    // ---------------------------
    void handleNextOrder() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserDashboard()),
      );
    }

    // ---------------------------
    // CONSTANTS
    // ---------------------------
    const Color mainBlue = Color(0xFF1976D2);
    const Color lightBlueBg = Color(0xFFE3F2FD);

    // ------------------------------------------------------------
    //                    YOUR ORIGINAL UI BELOW
    // ------------------------------------------------------------
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E66E1), Color(0xFF1565C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // White Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSuccessIllustration(lightBlueBg, mainBlue),
                        const SizedBox(height: 24),
                        const Text(
                          "Transaction successful!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: mainBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "NOTE: Don't forget to smile at customers.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Payment Box
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: mainBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Text(
                                  "Payment method: ${sale.payments.first.method.toUpperCase()}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Text(
                                  "Currency exchange: SAR ${sale.totalAmount}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Email Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: emailController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: "Email",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SEND RECEIPT
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: onSendPdfReceipt,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE3F2FD),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "SEND RECEIPT",
                              style: TextStyle(
                                color: mainBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  kHeight40,

                  // PRINT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: onOpenReceiptPreview,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "PREVIEW RECEIPT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NEXT ORDER
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: handleNextOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "NEXT ORDER",
                        style: TextStyle(
                          color: mainBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIllustration(Color bgColor, Color iconColor) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 48,
                color: Colors.grey[300],
              ),
              Positioned(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.check_circle, size: 32, color: iconColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
