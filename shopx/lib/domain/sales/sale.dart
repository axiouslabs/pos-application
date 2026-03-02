


import 'sale_item.dart';
import 'payment.dart';

class Sale {
  final int id;
  final int customerId;
  final String salespersonName;
  
  final String customerName;


  // final String customerPhone;
  // final String? customerTin;  // ✅ ADD
   
   final String? customerPhone;
final String? customerTin;
  

  final List<SaleItem> items;
  final List<Payment> payments;

  
  // 🔹 NEW FIELDS (REQUIRED)
  final double subtotalAmount;
  final double discountAmount;
  final double vatAmount;
  final double vatPercentage;

  final double totalAmount;
  final String paymentStatus;
  final DateTime saleDate;

  final String saleStatus; // <-- NEW


  Sale({
    required this.id,
    required this.customerId,
    required this.salespersonName,
    required this.customerName,
    // required this.customerPhone,
    // this.customerTin,

    this.customerPhone,
this.customerTin,
    required this.items,
    required this.payments,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.vatAmount,
    required this.vatPercentage,

    required this.totalAmount,
    required this.paymentStatus,
    required this.saleDate,

     required this.saleStatus, // <-- ADD
  });


  factory Sale.fromJson(Map<String, dynamic> json) {
  final saleData = json["sale"] ?? json;

  return Sale(
    id: saleData["id"] ?? 0,
    customerId: saleData["customer_id"] ?? 0,

    salespersonName: saleData["salesperson_name"] ?? "",
    customerName: saleData["customer_name"] ?? "",
    // customerPhone: saleData["customer_phone"] ?? "",
    // customerTin: saleData["customer_tin"],  // ✅ ADD

    customerPhone: saleData["customer_phone"],
customerTin: saleData["customer_tin"],

    items: (json["items"] as List?)?.map((i) => SaleItem.fromJson(i)).toList() ?? [],
    payments: (json["payments"] as List?)?.map((p) => Payment.fromJson(p)).toList() ?? [],

      // 🔹 MAP BACKEND FIELDS CORRECTLY
      subtotalAmount:
          double.tryParse(saleData["subtotal_amount"].toString()) ?? 0,

      discountAmount:
          double.tryParse(saleData["discount_amount"].toString()) ?? 0,

      vatAmount:
          double.tryParse(saleData["vat_amount"].toString()) ?? 0,

      vatPercentage:
          double.tryParse(saleData["vat_percentage"].toString()) ?? 15,

    totalAmount: double.tryParse(saleData["total_amount"].toString()) ?? 0,
    paymentStatus: saleData["payment_status"] ?? "paid",
    saleDate: DateTime.tryParse(saleData["sale_date"]) ?? DateTime.now(),
saleStatus: (saleData["sale_status"] ?? "completed").toLowerCase(),
  );
}

}
