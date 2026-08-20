import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/application/salesPerformance/sales_performance_state.dart';
import 'package:shopx/infrastructure/salesPerformance/sales_performance_api.dart';
import 'package:shopx/infrastructure/salesPerformance/sales_performance_repositary.dart';

final salesPerformanceRepositoryProvider = Provider<SalesPerformanceRepository>(
  (ref) {
    return SalesPerformanceRepository(ref.read(salesPerformanceApiProvider));
  },
);

final salesPerformanceNotifierProvider =
    NotifierProvider<SalesPerformanceNotifier, SalesPerformanceState>(
      SalesPerformanceNotifier.new,
    );

class SalesPerformanceNotifier extends Notifier<SalesPerformanceState> {
  // 🔥 STRICT PARSER — Add this
  // 🔧 FIXED PARSER - handles null and existing numbers
  num parseSafe(dynamic value, String fieldName) {
    print("🔢 Parsing $fieldName → value: $value, type: ${value?.runtimeType}");

    if (value == null) {
      print("⚠️ $fieldName is null, returning 0");
      return 0;
    }

    if (value is num) {
      return value; // Already a number (int/double)
    }

    final parsed = num.tryParse(value.toString());
    if (parsed == null) {
      print("⚠️ $fieldName has invalid format: $value, returning 0");
      return 0;
    }

    return parsed;
  }

  @override
  SalesPerformanceState build() {
    // Default: last 30 days
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));

    final start =
        "${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}-${lastMonth.day.toString().padLeft(2, '0')}";
    final end =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return SalesPerformanceState(startDate: start, endDate: end);
  }

  void updateStartDate(String date) {
    state = state.copyWith(startDate: date);
  }

  void updateEndDate(String date) {
    state = state.copyWith(endDate: date);
  }

  Future<void> loadReport(String start, String end) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repo = ref.read(salesPerformanceRepositoryProvider);

      // final summaryData = await repo.fetchSummary(start, end);
      // print("SUMMARY RAW → $summaryData");

      // final salesmanData = await repo.fetchSalesmanPerformance(start, end);
      // print("SALESMAN RAW → $salesmanData");

      // final productData = await repo.fetchProductSales(start, end);
      // print("PRODUCT RAW → $productData");

      // final customerData = await repo.fetchCustomerPerformance(start, end);
      // print("CUSTOMER RAW → $customerData");

      final summaryData = await repo.fetchSummary(start, end);
      print("🔍 RAW summaryData: $summaryData");
      print("🔍 summaryData['summary']: ${summaryData['summary']}");
      print(
        "🔍 summaryData['summary']['revenue']: ${summaryData['summary']?['revenue']}",
      );
      print("🔍 summaryData['chart']: ${summaryData['chart']}");

      final salesmanData = await repo.fetchSalesmanPerformance(start, end);
      print("🔍 RAW salesmanData: $salesmanData");

      final productData = await repo.fetchProductSales(start, end);
      print("🔍 RAW productData: $productData");

      final customerData = await repo.fetchCustomerPerformance(start, end);
      print("🔍 RAW customerData: $customerData");

      state = state.copyWith(
        loading: false,
        startDate: start,
        endDate: end,

        // SUMMARY FIX
        summary: {
          "summary": {
            "revenue": parseSafe(
              summaryData["summary"]?["revenue"],
              "summary.revenue",
            ),
            "units": parseSafe(
              summaryData["summary"]?["units"],
              "summary.units",
            ),
            "avg_value": parseSafe(
              summaryData["summary"]?["avg_value"],
              "summary.avg_value",
            ),
          },
          "chart": summaryData["chart"] ?? [],
        },

        // SALESMAN FIX
        salesmanList: salesmanData
            .map(
              (e) => {
                "name": e["name"],
                "revenue": parseSafe(e["revenue"], "salesman.revenue"),
                "units": parseSafe(e["units"], "salesman.units"),
              },
            )
            .toList(),

        // CUSTOMER FIX
        customerList: customerData
            .map(
              (e) => {
                "customer": e["customer"],
                "revenue": parseSafe(e["revenue"], "customer.revenue"),
                "orders": parseSafe(e["orders"], "customer.orders"),
              },
            )
            .toList(),

        // PRODUCT FIX
        productSales: {
          "pie": productData.map((e) {
            return {
              "value": parseSafe(e["revenue"], "product.revenue"),
              "color": Colors
                  .primaries[productData.indexOf(e) % Colors.primaries.length],
            };
          }).toList(),
          "list": productData,
        },
      );

      // ADD THIS:
      print(
        "STATE AFTER SET → summary: ${state.summary}, "
        "salesmen: ${state.salesmanList.length}, "
        "products: ${state.productSales['list']?.length}, "
        "customers: ${state.customerList.length}",
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

//   /// ✅ Load Product Performance (NEW)
//   Future<void> loadProductPerformance({
//     required String start,
//     required String end,
//     String? salespersonId,
//   }) async {
//     state = state.copyWith(loading: true, error: null);

//     try {
//       final repo = ref.read(salesPerformanceRepositoryProvider);

//       // final data = await repo.fetchProductPerformance(
//       //   start: start,
//       //   end: end,
//       //   salespersonId: salespersonId,
//       // );

// final data = await repo.fetchMyProductPerformance(
//   start: start,
//   end: end,
// );

//       state = state.copyWith(
//         loading: false,
//         productSales: {
//           "list": data,
//           "pie": data.map((e) {
//             return {
//               "value": parseSafe(e["units_sold"], "product.units"),
//               "label": e["product_name"],
//             };
//           }).toList(),
//         },
//       );
//     } catch (e) {
//       state = state.copyWith(loading: false, error: e.toString());
//     }
//   }


// ADMIN
Future<void> loadAdminProductPerformance({
  required String start,
  required String end,
  String? salespersonId,
}) async {
  final repo = ref.read(salesPerformanceRepositoryProvider);
  final data = await repo.fetchProductPerformance(
    start: start,
    end: end,
    salespersonId: salespersonId,
  );

  state = state.copyWith(productSales: {"list": data});
}

// USER
Future<void> loadUserProductPerformance({
  required String start,
  required String end,
}) async {
  final repo = ref.read(salesPerformanceRepositoryProvider);
  final data = await repo.fetchMyProductPerformance(
    start: start,
    end: end,
  );

  state = state.copyWith(productSales: {"list": data});
}


  /// Called when user presses "Filter"
  Future<void> filter(String start, String end) async {
    await loadReport(start, end);
  }
}
