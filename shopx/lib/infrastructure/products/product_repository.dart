
import 'dart:typed_data';

import 'package:shopx/domain/products/product.dart';
import 'package:shopx/infrastructure/products/product_api.dart';

class ProductRepository {
  final ProductApi api;

  ProductRepository(this.api);

  // Add product (admin only)
  // 1️⃣ Create product + upload images (admin)
  // CREATE PRODUCT → return newly created Product
Future<Product> createProduct(Product product, List<Uint8List> images) async {
  // 1️⃣ Create product (backend returns productId)
  final productId = await api.createProduct(product);

  List<String> uploadedUrls = [];

  // 2️⃣ Upload images (optional)
  if (images.isNotEmpty) {
    await api.uploadImages(productId, images);
  }

  // 3️⃣ Build final product object for instant UI update
  return Product(
    id: productId.toString(),
    name: product.name,
    nameAr: product.nameAr,
    price: product.price,
    category: product.category,
    quantity: product.quantity,
    code: product.code,
    vat: product.vat,
    images: uploadedUrls,
  );
}



    // Fetch all products (public)
  Future<List<Product>> getProducts() async {
    final response = await api.getProducts();
    return response
        .map<Product>((json) => Product.fromJson(json))
        .toList();
  }

  // Fetch single product (public)
  Future<Product> getProductById(String id) async {
    final json = await api.getProductById(id);
    return Product.fromJson(json);
  }


// Update product JSON (admin)
Future<Product> updateProduct(
  String id,
  Product updatedProduct,
  List<String> existingUrls,
  List<Uint8List> newImages,
) async {
  // 1️⃣ Get current product from backend (real stock)
  final currentJson = await api.getProductById(id);
  final currentProduct = Product.fromJson(currentJson);

  // 2️⃣ Calculate stock difference
  final double diff =
      updatedProduct.quantity - currentProduct.quantity;

  // 3️⃣ Adjust stock ONLY if quantity changed
  if (diff != 0) {
    await api.adjustStock(
      productId: id,
      quantityChange: diff,
      reason: "admin-update",
    );
  }

  // 4️⃣ Update product metadata (NO quantity)
  final metaJson = updatedProduct.toJson();
  metaJson.remove("quantity");

  await api.updateProduct(id, metaJson);

  // 5️⃣ Upload new images if any
  if (newImages.isNotEmpty) {
    await api.uploadImages(int.parse(id), newImages);
  }

  // 6️⃣ Fetch fresh product (backend truth)
  final freshJson = await api.getProductById(id);
  return Product.fromJson(freshJson);
}




// Delete product (admin)
Future<void> deleteProduct(String id) async {
  await api.deleteProduct(id); 
}





}
