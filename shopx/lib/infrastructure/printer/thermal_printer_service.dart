import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;

import 'package:shopx/domain/reciept/receipt_data.dart';
import 'receipt_image_builder.dart';

class ThermalPrinterService {
  static Future<void> printReceipt({
    required ReceiptData receipt,
    required BuildContext context,
  }) async {
    try {
      // 1️⃣ Build receipt IMAGE
      final ui.Image image =
          await ReceiptImageBuilder.build(receipt);

      // 2️⃣ Convert image → bytes
      final bytes = await _imageToBytes(image);

      // 3️⃣ Check connection
      if (!await PrintBluetoothThermal.connectionStatus) {
        _show(context, "Printer not connected");
        return;
      }

      // 4️⃣ Print
      await PrintBluetoothThermal.writeBytes(bytes);
      _show(context, "Printed successfully");
    } catch (e) {
      _show(context, "Print failed: $e");
    }
  }

  static Future<List<int>> _imageToBytes(ui.Image image) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    final decoded = img.decodeImage(byteData!.buffer.asUint8List())!;
    final resized = img.copyResize(decoded, width: 384);

    final bytes = <int>[];
    bytes.addAll(generator.image(resized));
    bytes.addAll(generator.cut());
    return bytes;
  }

  static void _show(BuildContext c, String m) {
    ScaffoldMessenger.of(c)
        .showSnackBar(SnackBar(content: Text(m)));
  }
}
