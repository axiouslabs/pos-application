


import 'sale_item.dart';
import 'payment.dart';

class Sale {
  final int id;
  final int customerId;
  final String salespersonName;
  final String customerName;
  final String customerPhone;

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

  Sale({
    required this.id,
    required this.customerId,
    required this.salespersonName,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.payments,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.vatAmount,
    required this.vatPercentage,

    required this.totalAmount,
    required this.paymentStatus,
    required this.saleDate,
  });

  // factory Sale.fromJson(Map<String, dynamic> json) {
  //   print("🔥 PARSING Sale.fromJson...");

  //   final saleData = json["sale"];

  //   return Sale(
  //     id: saleData["id"],
  //     customerId: saleData["customer_id"],
  //     salespersonName: saleData["salesperson_name"] ?? "",
  //     customerName: saleData["customer_name"] ?? "",
  //     customerPhone: saleData["customer_phone"] ?? "",

  //     items: (json["items"] as List)
  //         .map((i) => SaleItem.fromJson(i))
  //         .toList(),

  //     payments: (json["payments"] as List)
  //         .map((p) => Payment.fromJson(p))
  //         .toList(),

  //     totalAmount: double.parse(saleData["total_amount"].toString()),
  //     paymentStatus: saleData["payment_status"],
  //     saleDate: DateTime.parse(saleData["sale_date"]),
  //   );
  // }

  factory Sale.fromJson(Map<String, dynamic> json) {
    // Single-sale endpoint wraps data in {"sale": {...}, "items": [...], "payments": [...]}
    // List endpoints return flat objects directly
    final bool isWrapped = json.containsKey("sale") && json["sale"] is Map;
    final saleData = isWrapped
        ? json["sale"] as Map<String, dynamic>
        : json;

    return Sale(
      id: saleData["id"] ?? 0,
      customerId: saleData["customer_id"] ?? 0,
      salespersonName: saleData["salesperson_name"]?.toString() ?? "",
      customerName: saleData["customer_name"]?.toString() ?? "",
      customerPhone: saleData["customer_phone"]?.toString() ?? "",

      // items / payments only present on single-sale endpoint
      items: isWrapped
          ? (json["items"] as List? ?? [])
              .map((i) => SaleItem.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
      payments: isWrapped
          ? (json["payments"] as List? ?? [])
              .map((p) => Payment.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],

      subtotalAmount:
          double.tryParse(saleData["subtotal_amount"]?.toString() ?? "0") ?? 0,
      discountAmount:
          double.tryParse(saleData["discount_amount"]?.toString() ?? "0") ?? 0,
      vatAmount:
          double.tryParse(saleData["vat_amount"]?.toString() ?? "0") ?? 0,
      vatPercentage:
          double.tryParse(saleData["vat_percentage"]?.toString() ?? "15") ?? 15,
      totalAmount:
          double.tryParse(saleData["total_amount"]?.toString() ?? "0") ?? 0,
      paymentStatus: saleData["payment_status"]?.toString() ?? "pending",
      saleDate: DateTime.tryParse(saleData["sale_date"]?.toString() ?? "") ??
          DateTime.now(),
    );
  }

}
