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
  

//  Future<List<dynamic>> getAdminSales({
//   String? from,
//   String? to,
//   String? salesperson,
//   String? status,
// }) async {
//   final res = await _dio.get(
//     "/sales",
//     queryParameters: {
//       if (from != null) "from": from,
//       if (to != null) "to": to,
//       if (salesperson != null) "salesperson": salesperson,
//       if (status != null) "status": status,
//     },
//   );

//   return res.data;
// }

Future<List<dynamic>> getAdminSales({
  String? from,
  String? to,
  String? salesperson,
  String? status,
  int? customerId,
}) async {
  final res = await _dio.get(
    "/sales",
    queryParameters: {
      if (from != null) "from": from,
      if (to != null) "to": to,
      if (salesperson != null) "salesperson": salesperson,
      if (status != null) "status": status,
      if (customerId != null) "customerId": customerId,
    },
  );

  return res.data;
}



  // USER ONLY
  Future<List<dynamic>> getMySales({
  String? from,
  String? to,
  String? status,
}) async {
  final res = await _dio.get(
    "/sales/my",
    queryParameters: {
      if (from != null) "from": from,
      if (to != null) "to": to,
      if (status != null) "status": status,
    },
  );

  return res.data;
}
  // Future<List<dynamic>> getMySales() async {
  //   final res = await _dio.get("/sales/my");
  //   return res.data;
  // }

  Future<void> voidSale(int saleId) async {
    await _dio.post("/sales/$saleId/void");
  }

  Future<Map<String, dynamic>> reviseSale(
  int saleId,
  Map<String, dynamic> data,
) async {
  final res = await _dio.post(
    "/sales/$saleId/revise",
    data: data,
  );

  return res.data;
}
}
