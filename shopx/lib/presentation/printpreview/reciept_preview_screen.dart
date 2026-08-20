import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shopx/domain/reciept/receipt_data.dart';
import 'package:shopx/domain/utils/zatca_qr.dart';
import 'package:shopx/infrastructure/printer/receipt_image_builder.dart';
import 'package:shopx/infrastructure/printer/thermal_printer_service.dart'; // Ensure path matches your project structure

class RecieptPreviewScreen extends HookConsumerWidget {
  final GlobalKey repaintKey = GlobalKey();
  final ReceiptData receipt;

  RecieptPreviewScreen({super.key, required this.receipt});

  String formatInvoiceDate(DateTime date) {
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrData = ZatcaQr.generate(
      sellerName: receipt.companyNameEn,
      vatNumber: receipt.vatNumber,
      invoiceDate: receipt.invoiceDate,
      totalWithVat: receipt.netTotal,
      vatAmount: receipt.vatAmount,
    );

    final isPrinting = useState(false);

    // Standard thermal paper width (approx 384px for 58mm/80mm)
    const double receiptWidth = 384;
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Stack(
          children: [
            // Background overlay
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.05)),
            ),

            // Centered receipt preview card
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 15),
                  ],
                ),
                child: Column(
                  children: [
                    // 🔝 TOP BAR WITH CLOSE BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(
                                context,
                              ); // 👈 back to success screen
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // RECEIPT CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: RepaintBoundary(
                            key: repaintKey,
                            child: Container(
                              color: Colors.white,
                              width: receiptWidth, // 384
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeader(receipt),
                                  _buildCustomerInfo(receipt),
                                  _buildItemsTable(receipt),
                                  _buildTotals(receipt),
                                  _buildFooter(qrData),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 🔽 ACTION BUTTONS
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _shareReceipt(context),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text("Share"),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isPrinting.value
                                  ? null
                                  : () async {
                                      isPrinting.value = true;

                                      await _printReceipt(context);

                                      // Re-enable after 15 seconds
                                      Future.delayed(
                                        const Duration(seconds: 15),
                                        () {
                                          isPrinting.value = false;
                                        },
                                      );
                                    },
                              icon: const Icon(Icons.print_outlined),
                              label: Text(
                                isPrinting.value ? "Printing..." : "Print",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade400,
                                disabledForegroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      final boundary =
          repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Receipt');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Share failed')));
    }
  }

  Future<void> _printReceipt(BuildContext context) async {
    await ThermalPrinterService.printReceipt(
      receipt: receipt,
      context: context,
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader(ReceiptData r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
      child: Column(
        children: [
          const Text(
            "SAQAF NAQAL TRADING Est.",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const Text(
            "مؤسسة سقاف النقل التجارية",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          const Text(
            "MAKKAH-KSA",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            "CR: ${r.crNumber}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Mobile : 0571830599",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            "VAT : ${r.vatNumber}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- CUSTOMER & INVOICE INFO ---
  Widget _buildCustomerInfo(ReceiptData r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          _bilingualRow("Customer", ": ${r.customerName}", "اسم العميل"),

if (r.customerVat != null && r.customerVat!.isNotEmpty)
  _bilingualRow(
    "Customer VAT",
    ": ${r.customerVat}",
    "الرقم الضريبي للعميل",
  ),


          // _bilingualRow("InvoiceDate", ": ${r.invoiceDate}", "تاريخ الفاتورة"),
          _bilingualRow(
            "InvoiceDate",
            ": ${formatInvoiceDate(r.invoiceDate)}",
            "تاريخ الفاتورة",
          ),

          _bilingualRow("InvoiceNo", ": ${r.invoiceNumber}", "رقم الفاتورة"),
          const SizedBox(height: 10),
          const Divider(thickness: 1.5, color: Colors.black),
        ],
      ),
    );
  }

  // --- ITEMS TABLE ---
  Widget _buildItemsTable(ReceiptData r) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              SizedBox(
                width: 25,
                child: Text(
                  "SI",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  "Item",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  "Price",
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 45,
                child: Text(
                  "Qty",
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  "Total",
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const Divider(thickness: 1.5, color: Colors.black),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: r.items.length,
          itemBuilder: (context, index) {
            final item = r.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 25,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nameEn,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.nameAr ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      item.unitPrice.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 45,
                    child: Text(
                      "${item.quantity}",
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      item.total.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(thickness: 1.5, color: Colors.black),
      ],
    );
  }

  // --- TOTALS AREA ---
  Widget _buildTotals(ReceiptData r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          // Subtotal row with Quantity in middle
          Row(
            children: [
              const Text(
                "Sub Total",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              const Text(
                "المجموع الفرعي",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(width: 40),
              Text(
                r.items
                    .fold<int>(0, (sum, item) => sum + item.quantity)
                    .toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(width: 40),
              Text(
                r.subTotal.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black54),
          _summaryRow("Vat", "ضريبة", r.vatAmount.toStringAsFixed(2)),
          _summaryRow("Charges", "رسوم أخرى", "0.00"),
          _summaryRow(
            "Discount",
            "خصم",
            (r.discount ?? 0.0).toStringAsFixed(2),
          ),

          const Divider(thickness: 1.5, color: Colors.black),
          _summaryRow(
            "Net Total",
            "الإجمالي الصافي",
            r.netTotal.toStringAsFixed(2),
            isBold: true,
          ),
          const Divider(thickness: 1.5, color: Colors.black),
        ],
      ),
    );
  }

  // --- FOOTER ---
  Widget _buildFooter(String qrData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Simulated QR Code
          QrImageView(data: qrData, size: 120, backgroundColor: Colors.white),

          const SizedBox(height: 15),
          const Text(
            "Thank You | شكرا لكم",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 40), // Bottom padding for paper feel
        ],
      ),
    );
  }

  // --- HELPER UI WIDGETS ---
  Widget _bilingualRow(String leftEn, String value, String rightAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  height: 1.2,
                ),
                children: [
                  TextSpan(
                    text: leftEn,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: "   $value",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Text(
            rightAr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String labelEn,
    String labelAr,
    String value, {
    bool isBold = false,
  }) {
    final style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: isBold ? 17 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(labelEn, style: style),
          const Spacer(),
          Text(labelAr, style: style),
          const SizedBox(width: 60),
          Text(value, style: style),
        ],
      ),
    );
  }
}
