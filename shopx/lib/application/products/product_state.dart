// 📌 Holds the UI state (loading, data, error) for products.

import 'package:shopx/domain/products/product.dart';

class ProductState {
  final bool isLoading;            // true when API call is happening
  final List<Product> products;    // list of products for dashboard
  final String? error;             // error message (if any)
  final bool success;              // true when add/update/delete is successful

  ProductState({
    this.isLoading = false,
    this.products = const [],
    this.error,
    this.success = false,
  });

  // 📌 Helps update state easily
  ProductState copyWith({
    bool? isLoading,
    List<Product>? products,
    String? error,
    bool? success,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      error: error,
      success: success ?? this.success,
    );
  }
}
