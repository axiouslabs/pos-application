// class SaleItem {
//   final int productId;
//   final int quantity;
//   final double unitPrice;
//   final double totalPrice;

//   SaleItem({
//     required this.productId,
//     required this.quantity,
//     required this.unitPrice,
//     required this.totalPrice,
//   });

//   factory SaleItem.fromJson(Map<String, dynamic> json) {
//     return SaleItem(
//       productId: json["product_id"],
//       quantity: json["quantity"],
//       unitPrice: (json["unit_price"] as num).toDouble(),
//       totalPrice: (json["total_price"] as num).toDouble(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       "product_id": productId,
//       "quantity": quantity,
//       "unit_price": unitPrice,
//       "total_price": totalPrice,
//     };
//   }
// }


class SaleItem {
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String productName;
   final String productNameAr;

  SaleItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.productName,
    required this.productNameAr
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json["product_id"],
      quantity: int.parse(json["quantity"].toString()),
      unitPrice: double.parse(json["unit_price"].toString()),
      totalPrice: double.parse(json["total_price"].toString()),
      productName: json["product_name"] ?? "",
       productNameAr: json["product_name_ar"], // ✅ THIS WAS MISSING
    );
  }
}
