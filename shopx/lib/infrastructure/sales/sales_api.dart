import 'package:dio/dio.dart';

class SalesApi {
  final Dio _dio;

  SalesApi(this._dio);

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) async {
    final res = await _dio.post("/sales", data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getSaleById(int id) async {
    final res = await _dio.get("/sales/$id");
    return res.data;
  }
// ADMIN ONLY
Future<List<dynamic>> getAdminSales() async {
  final res = await _dio.get("/sales");
  return res.data;
}

// USER ONLY
Future<List<dynamic>> getMySales() async {
  final res = await _dio.get("/sales/my");
  return res.data;
}

// ADMIN ONLY — void / cancel a sale regardless of status
Future<void> voidSale(int saleId) async {
  await _dio.patch("/sales/$saleId/void");
}

// ADMIN — get all sales for a specific customer
Future<List<dynamic>> getSalesByCustomer(int customerId) async {
  final res = await _dio.get("/sales/customer/$customerId");
  return res.data;
}

}
