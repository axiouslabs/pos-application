//What information is printed on the receipt

// lib/domain/receipt/receipt_data.dart

/// Represents a single line item on the receipt
class ReceiptItem {
  final String nameEn; // Item name in English
  final String? nameAr; // Item name in Arabic (optional)
  final double unitPrice; // Price per unit
  final int quantity; // Quantity sold

  const ReceiptItem({
    required this.nameEn,
    this.nameAr,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;
}

/// Represents all data required to print a thermal receipt
class ReceiptData {
  // --------------------
  // Company Information
  // --------------------
  final String companyNameEn;
  final String companyNameAr;
  final String city;
  final String country;
  final String crNumber;
  final String vatNumber;
  final String mobile;

  //customer Information
  
  // OPTIONAL — only needed for PDF send
  final String? customerAddress;
  final String? customerPhone;
  final String? customerVat; // ✅ ADD THIS
  final double? discount;

  // --------------------
  // Invoice Information
  // --------------------
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerName;

  // --------------------
  // Items
  // --------------------
  final List<ReceiptItem> items;

  // --------------------
  // Totals
  // --------------------
  final double subTotal;
  final double vatAmount;
  final double vatPercentage;
  final double netTotal;

  // --------------------
  // QR Code Payload (ZATCA)
  // --------------------
  final String qrPayload;

  const ReceiptData({
    required this.companyNameEn,
    required this.companyNameAr,
    required this.city,
    required this.country,
    required this.crNumber,
    required this.vatNumber,
    required this.mobile,
     this.customerAddress,
     this.customerPhone,
     this.customerVat,
    this.discount,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.items,
    required this.subTotal,
    required this.vatAmount,
    required this.vatPercentage,
    required this.netTotal,
    required this.qrPayload,
  });
}
