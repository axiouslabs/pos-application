import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/infrastructure/core/dio_provider.dart';

final customerApiProvider = Provider<CustomerApi>((ref) {
  return CustomerApi(ref.read(dioProvider));
});

class CustomerApi {
  final Dio _dio;

  CustomerApi(this._dio);

  // CREATE CUSTOMER
  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    final res = await _dio.post("/customers", data: data);
    return res.data["customer"];
  }

 // GET ALL CUSTOMERS (for Cart)
Future<List<dynamic>> getCustomers() async {
  final res = await _dio.get("/customers");
  return res.data;
}

// GET MY CUSTOMERS (for Manage Customers)
Future<List<dynamic>> getMyCustomers() async {
  final res = await _dio.get("/customers/my");
  return res.data;
}


  // GET CUSTOMER BY ID
  Future<Map<String, dynamic>> getCustomerById(int id) async {
    final res = await _dio.get("/customers/$id");
    return res.data;
  }

  // UPDATE CUSTOMER
  Future<Map<String, dynamic>> updateCustomer(int id, Map<String, dynamic> data) async {
    final res = await _dio.put("/customers/$id", data: data);
    return res.data["customer"];
  }

  // DELETE CUSTOMER
  Future<void> deleteCustomer(int id) async {
    await _dio.delete("/customers/$id");
  }
}
