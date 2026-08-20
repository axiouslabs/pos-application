import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'cart_state.dart';
import 'package:shopx/domain/products/product.dart';

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState(items: []);
  }

  // Add product to cart
  void addToCart(Product product, double qty) {
    final list = [...state.items];

    final index = list.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      // Update quantity if already exists
      final updated = list[index].copyWith(
        quantity: list[index].quantity + qty,
      );
      list[index] = updated;
    } else {
      // Add new item
      list.add(CartItem(product: product, quantity: qty));
    }

    state = state.copyWith(items: list);
  }

  // Remove product
  void removeFromCart(String productId) {
    final list = state.items.where((i) => i.product.id != productId).toList();
    state = state.copyWith(items: list);
  }

  // Clear cart
  void clearCart() {
    state = state.copyWith(items: []);
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
