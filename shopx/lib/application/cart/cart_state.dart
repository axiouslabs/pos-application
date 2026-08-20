import 'package:shopx/domain/products/product.dart';

class CartItem {
  final Product product;
  final double quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({
    Product? product,
    double? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final bool isProcessing;
  final String? error;

  const CartState({
    required this.items,
    this.isProcessing = false,
    this.error,
  });

  double get totalPrice {
    double sum = 0;
    for (final item in items) {
      sum += item.product.price * item.quantity;
    }
    return sum;
  }

  CartState copyWith({
    List<CartItem>? items,
    bool? isProcessing,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}
