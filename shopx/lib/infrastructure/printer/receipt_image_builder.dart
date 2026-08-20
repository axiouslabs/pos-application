import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shopx/domain/reciept/receipt_data.dart';

class ReceiptImageBuilder {
  static Future<ui.Image> build(ReceiptData r) async {
    const double width = 384; // 58mm printer width
    const double height = 1200;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );

    double y = 10;

    // Helper to draw text
    void drawText(String text, double fontSize,
        {TextAlign align = TextAlign.left}) {
      final pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: fontSize,
          textDirection: TextDirection.rtl,
          textAlign: align,
        ),
      )..addText(text);

      final p = pb.build();
      p.layout(const ui.ParagraphConstraints(width: width));
      canvas.drawParagraph(p, Offset(0, y));
      y += p.height + 6;
    }

    // ---------------- HEADER ----------------
    drawText(r.companyNameAr, 18, align: TextAlign.center);
    drawText(r.companyNameEn, 14, align: TextAlign.center);

    drawText("VAT: ${r.vatNumber}", 12, align: TextAlign.center);
    drawText("CR: ${r.crNumber}", 12, align: TextAlign.center);

    y += 10;
    drawText("فاتورة ضريبية | Tax Invoice", 14,
        align: TextAlign.center);

    y += 10;

    // ---------------- CUSTOMER ----------------
   drawText("العميل: ${r.customerName}", 12);

if (r.customerPhone != null && r.customerPhone!.isNotEmpty) {
  drawText("الهاتف: ${r.customerPhone}", 12);
}

if (r.customerVat != null && r.customerVat!.isNotEmpty) {
  drawText("الرقم الضريبي: ${r.customerVat}", 12);
}

drawText("رقم الفاتورة: ${r.invoiceNumber}", 12);
drawText("التاريخ: ${r.invoiceDate}", 12);

    y += 10;

    // ---------------- ITEMS ----------------
    drawText("الصنف | Item        الكمية | Qty    الإجمالي | Total",
        11);

    for (final item in r.items) {
      drawText(
        "${item.nameAr} / ${item.nameEn}   ${item.quantity}   ${item.total.toStringAsFixed(2)}",
        11,
      );
    }

    y += 10;

    // ---------------- TOTALS ----------------
    drawText("المجموع: ${r.subTotal}", 12);
    drawText("الضريبة ${r.vatPercentage}%: ${r.vatAmount}", 12);
    drawText("الإجمالي: ${r.netTotal}", 14);

    y += 20;
    drawText("شكراً لتعاملكم معنا", 14, align: TextAlign.center);

    final picture = recorder.endRecording();
    return picture.toImage(width.toInt(), height.toInt());
  }
}
