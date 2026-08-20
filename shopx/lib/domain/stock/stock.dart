class Stock {
  final String productId;
  final double quantity;

  Stock({
    required this.productId,
    required this.quantity,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      productId: json["product_id"].toString(),
      quantity: double.tryParse(json["quantity"].toString()) ?? 0.0,
    );
  }
}
