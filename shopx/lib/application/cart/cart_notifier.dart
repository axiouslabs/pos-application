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
      list.add(
        CartItem(product: product, quantity: qty, sellingPrice: product.price),
      );
    }

    state = state.copyWith(items: list);
  }

  //New
  void updateSellingPrice(String productId, double newPrice) {
    final list = [...state.items];

    final index = list.indexWhere((i) => i.product.id == productId);
    if (index == -1) return;

    list[index] = list[index].copyWith(sellingPrice: newPrice);

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


  // ================= REVISION SUPPORT =================
// Used when editing an existing sale
void addFromRevision({
  required String productId,
  required String productName,
  required double quantity,
  required double unitPrice,
}) {
  final list = [...state.items];

  // Create lightweight product object
  final product = Product(
    id: productId,
    name: productName,
    nameAr: productName,
    price: unitPrice,
    category: "",
    quantity: 0,
    images: const [],
    code: "",
    vat: 15,
  );

  list.add(
    CartItem(
      product: product,
      quantity: quantity,
      sellingPrice: unitPrice,
    ),
  );

  state = state.copyWith(items: list);
}

}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
