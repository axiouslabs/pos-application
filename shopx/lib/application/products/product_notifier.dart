import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/application/products/product_state.dart';
import 'package:shopx/domain/products/product.dart';
import 'package:shopx/infrastructure/products/product_repository.dart';
import 'package:shopx/infrastructure/products/product_api.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(productApiProvider));
});

class ProductNotifier extends Notifier<ProductState> {
  @override
  ProductState build() {
    return ProductState();
  }

  // 1️⃣ Create product + upload images
  Future<void> createProduct(Product product, List<Uint8List> images) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Repository now RETURNS new product
      final newProduct = await ref
          .read(productRepositoryProvider)
          .createProduct(product, images);

      // 🔥 Add product instantly to UI list
      final updatedList = [...state.products, newProduct];

      state = state.copyWith(
        isLoading: false,
        success: true,
        products: updatedList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 2️⃣ Fetch all products
  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final products = await ref.read(productRepositoryProvider).getProducts();
      state = state.copyWith(isLoading: false, products: products);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 3️⃣ Update product (no token required)
  Future<void> updateProduct(
    String id,
    Product updatedProduct, {
    required List<String> existingUrls,
    required List<Uint8List> newImages,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final fullUpdatedProduct = await ref
          .read(productRepositoryProvider)
          .updateProduct(id, updatedProduct, existingUrls, newImages);

      final updatedList = state.products.map((p) {
        return p.id == id ? fullUpdatedProduct : p;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        success: true,
        products: updatedList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 4️⃣ Delete product
  // 4️⃣ Delete product (with instant UI update)
  Future<void> deleteProduct(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(productRepositoryProvider).deleteProduct(id);

      // 🔥 Immediately remove product from state (UI updates instantly)
      final updatedList = state.products.where((p) => p.id != id).toList();

      state = state.copyWith(
        isLoading: false,
        success: true,
        products: updatedList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 5️⃣ Fetch SINGLE product (always fresh from backend)
  Future<Product> fetchProductById(String id) async {
    try {
      final product = await ref
          .read(productRepositoryProvider)
          .getProductById(id);

      return product;
    } catch (e) {
      throw Exception(e.toString());
    }
  }


// 6️⃣ Adjust stock only (admin action)
Future<void> adjustStock({
  required String productId,
  required double quantityChange,
}) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    // Call repository → API → backend
    await ref.read(productRepositoryProvider).api.adjustStock(
          productId: productId,
          quantityChange: quantityChange,
        );

    // Fetch fresh product from backend (source of truth)
    final updatedProduct =
        await ref.read(productRepositoryProvider).getProductById(productId);

    // Update product list in state
    final updatedList = state.products.map((p) {
      return p.id == productId ? updatedProduct : p;
    }).toList();

    state = state.copyWith(
      isLoading: false,
      products: updatedList,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}


}

final productNotifierProvider = NotifierProvider<ProductNotifier, ProductState>(
  ProductNotifier.new,
);
