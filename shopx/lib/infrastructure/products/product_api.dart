import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/domain/products/product.dart';
import 'package:shopx/infrastructure/core/dio_provider.dart';

final productApiProvider = Provider<ProductApi>((ref) {
  // ✔ Inject shared Dio here
  return ProductApi(ref.read(dioProvider));
});

class ProductApi {
  final Dio _dio;

  // ✔ DO NOT create new Dio() here
  ProductApi(this._dio);

  // POST → Add Product
  Future<int> createProduct(Product product) async {
    final res = await _dio.post("/products", data: product.toJson());

    return res.data["id"]; // backend returns product id
  }

  // GET → Fetch All Products
  Future<List<dynamic>> getProducts() async {
    final response = await _dio.get("/products");
    return response.data; // returns a list of JSON objects
  }

  // GET → Fetch single product by ID
  Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _dio.get("/products/$id");
    return response.data;
  }

  // PUT → Update Product  (metadata incl. name_ar)
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _dio.put(
      "/products/$id",
      data: data, // name, price, category, code, vat ONLY
    );
  }

  // POST → Adjust stock for a product
  Future<void> adjustStock({
    required String productId,
    required double quantityChange,
    String reason = "admin-adjust",
  }) async {
    await _dio.post(
      "/products/$productId/adjust-stock",
      data: {"quantity": quantityChange, "reason": reason},
    );
  }

  // DELETE → Remove Product by ID
  Future<void> deleteProduct(String id) async {
    await _dio.delete("/products/$id");
  }

  Future<void> uploadImages(int productId, List<Uint8List> images) async {
    final formData = FormData();

    for (int i = 0; i < images.length; i++) {
      formData.files.add(
        MapEntry(
          "images",
          MultipartFile.fromBytes(images[i], filename: "image_$i.png"),
        ),
      );
    }

    await _dio.post("/products/$productId/images", data: formData);
  }
}
