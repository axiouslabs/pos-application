
import 'package:shopx/infrastructure/salesPerformance/sales_performance_api.dart';

class SalesPerformanceRepository {
  final SalesPerformanceApi api;

  SalesPerformanceRepository(this.api);

  Future<Map<String, dynamic>> fetchSummary(String start, String end) async {
    return await api.getSummary(start, end);
  }

  Future<List<Map<String, dynamic>>> fetchSalesmanPerformance(String start, String end) async {
    final data = await api.getSalesmanPerformance(start, end);
    return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchProductSales(String start, String end) async {
    final data = await api.getProductSales(start, end);
    return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    
  }

   /// ✅ Product Performance Repository (NEW)
   // ADMIN (unchanged)
Future<List<Map<String, dynamic>>> fetchProductPerformance({
  required String start,
  required String end,
  String? salespersonId,
}) async {
  final data = await api.getProductPerformance(
    start: start,
    end: end,
    salespersonId: salespersonId,
  );

  return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
}

// USER (NEW)
Future<List<Map<String, dynamic>>> fetchMyProductPerformance({
  required String start,
  required String end,
}) async {
  final data = await api.getMyProductPerformance(
    start: start,
    end: end,
  );

  return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
}



  Future<List<Map<String, dynamic>>> fetchCustomerPerformance(String start, String end) async {
  final data = await api.getCustomerPerformance(start, end);
  return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
}

}
