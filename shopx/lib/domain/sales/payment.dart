// class Payment {
//   final int id;
//   final int saleId;
//   final int customerId;
//   final double amount;
//   final String method;
//   final DateTime createdAt;

//   Payment({
//     required this.id,
//     required this.saleId,
//     required this.customerId,
//     required this.amount,
//     required this.method,
//     required this.createdAt,
//   });

//   factory Payment.fromJson(Map<String, dynamic> json) {
//     return Payment(
//       id: json["id"],
//       saleId: json["sale_id"],
//       customerId: json["customer_id"],
//       amount: (json["amount"] as num).toDouble(),
//       method: json["method"],
//       createdAt: DateTime.parse(json["created_at"]),
//     );
//   }
// }


class Payment {
  final int id;
  final int saleId;
  final int customerId;
  final double amount;
  final String method;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.saleId,
    required this.customerId,
    required this.amount,
    required this.method,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json["id"],
      saleId: json["sale_id"],
      customerId: json["customer_id"],
      amount: double.parse(json["amount"].toString()),
      method: json["method"],
      createdAt: DateTime.parse(json["created_at"]),
    );
  }
}
