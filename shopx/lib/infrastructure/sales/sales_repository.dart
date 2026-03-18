import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/infrastructure/sales/sales_api.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/infrastructure/core/dio_provider.dart';

// ----------------------------------------------------------
// REPOSITORY
// ----------------------------------------------------------

class SalesRepository {
  final SalesApi api;

  SalesRepository(this.api);

  Future<int> createSale({
    required int customerId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String paymentStatus, // 👈 ADD THIS
    required double discountAmount,
  }) async {
    final response = await api.createSale({
      "customer_id": customerId,
      "items": items,
      "payment_method": paymentMethod,
      "payment_status": paymentStatus, // 👈 SEND TO BACKEND
      "discount_amount": discountAmount,
    });

    print("🔥 RAW SALE RESPONSE = $response");

    // return response["sale"]["id"];   // <-- backend returns this

    final rawSale = response["sale"];

    if (rawSale == null) {
      throw Exception("Backend did not return sale object");
    }

    final innerSale = rawSale["sale"]; // <-- YOUR BACKEND STRUCTURE

    if (innerSale == null) {
      throw Exception("Inner sale object missing");
    }

    final id = innerSale["id"]; // <-- HERE is your actual sale_id

    if (id == null) {
      throw Exception("Sale ID missing in backend response");
    }

    return id;
  }

  // Future<Sale> getSaleById(int id) async {
  //   final json = await api.getSaleById(id);
  //   print("🔥 RAW JSON FROM BACKEND = $json");

  //   return Sale.fromJson(json);

  // }

  Future<Sale> getSaleById(int id) async {
    final json = await api.getSaleById(id);
    print("🔥 RAW JSON FROM BACKEND = $json");

    try {
      final sale = Sale.fromJson(json);
      print("🔥 PARSED SALE SUCCESSFULLY: $sale");
      return sale;
    } catch (e, stack) {
      print("❌ ERROR PARSING Sale.fromJson: $e");
      print("❌ STACKTRACE: $stack");
      rethrow;
    }
  }

  // ADMIN

  Future<List<Sale>> getAdminSales({
  String? from,
  String? to,
  String? salesperson,
  String? status,
  int? customerId,
}) async {
  final list = await api.getAdminSales(
    from: from,
    to: to,
    salesperson: salesperson,
    status: status,
    customerId: customerId,
  );

  return list.map((e) => Sale.fromJson(e)).toList();
}
  
//   Future<List<Sale>> getAdminSales({
//   String? from,
//   String? to,
//   String? salesperson,
//   String? status,
// }) async {
//   final list = await api.getAdminSales(
//     from: from,
//     to: to,
//     salesperson: salesperson,
//     status: status,
//   );

//   return list.map((e) => Sale.fromJson(e)).toList();
// }



  // USER
 Future<List<Sale>> getMySales({
  String? from,
  String? to,
  String? status,
}) async {
  final list = await api.getMySales(
    from: from,
    to: to,
    status: status,
  );

  return list.map((e) => Sale.fromJson(e)).toList();
}
  // Future<List<Sale>> getMySales() async {
  //   final list = await api.getMySales();
  //   return list.map((e) => Sale.fromJson(e)).toList();
  // }

  Future<void> voidSale(int saleId) async {
    await api.voidSale(saleId);
  }

  Future<int> reviseSale({
  required int originalSaleId,
  required int customerId,
  required List<Map<String, dynamic>> items,
  required String paymentMethod,
  required String paymentStatus,
  required double discountAmount,
}) async {
  final response = await api.reviseSale(
    originalSaleId,
    {
      "customer_id": customerId,
      "items": items,
      "payment_method": paymentMethod,
      "payment_status": paymentStatus,
      "discount_amount": discountAmount,
    },
  );

  final newSale = response["result"];

  if (newSale == null || newSale["id"] == null) {
    throw Exception("Revised sale ID missing");
  }

  return newSale["id"];
}
}

// ----------------------------------------------------------
// PROVIDERS (THE PART YOU MISSED)
// ----------------------------------------------------------

// 1️⃣ Sales API Provider
final salesApiProvider = Provider<SalesApi>((ref) {
  return SalesApi(ref.read(dioProvider));
});

// 2️⃣ Sales Repository Provider  (THIS FIXES YOUR ERROR)
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.read(salesApiProvider));
});
