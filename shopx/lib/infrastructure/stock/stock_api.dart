import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/infrastructure/core/dio_provider.dart';

final stockApiProvider = Provider<StockApi>((ref) {
  return StockApi(ref.read(dioProvider));
});

class StockApi {
  final Dio _dio;

  StockApi(this._dio);

  // GET stock for a single product
  Future<double> getStock(String productId) async {
    final res = await _dio.get("/stock/$productId");
    return double.tryParse(res.data["quantity"].toString()) ?? 0.0;
  }

  // GET stock list for all products
  Future<List<dynamic>> getAllStock() async {
    final res = await _dio.get("/stock");
    return res.data; // list of JSON objects
  }
}
