import 'dart:convert';

class ZatcaQr {
  static String generate({
    required String sellerName,
    required String vatNumber,
    required DateTime invoiceDate,
    required double totalWithVat,
    required double vatAmount,
  }) {
    List<int> bytes = [];

    void addTLV(int tag, String value) {
      final valueBytes = value.codeUnits;
      bytes.add(tag);
      bytes.add(valueBytes.length);
      bytes.addAll(valueBytes);
    }

    addTLV(1, sellerName);
    addTLV(2, vatNumber);
    addTLV(3, invoiceDate.toIso8601String());
    addTLV(4, totalWithVat.toStringAsFixed(2));
    addTLV(5, vatAmount.toStringAsFixed(2));

    return base64Encode(bytes);
  }
}
