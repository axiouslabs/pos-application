import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/application/dashboard/admin_dashboard_state.dart';
import 'package:shopx/infrastructure/dashboard/admin_dashboard_api.dart';
import 'package:shopx/infrastructure/dashboard/admin_dashboard_repository.dart';

final adminDashboardRepositoryProvider =
    Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(ref.read(adminDashboardApiProvider));
});

final adminDashboardNotifierProvider =
    NotifierProvider<AdminDashboardNotifier, AdminDashboardState>(
        AdminDashboardNotifier.new);

class AdminDashboardNotifier extends Notifier<AdminDashboardState> {

  // 🔥 STRICT PARSER — Add this
  num parseRequired(dynamic value, String fieldName) {
    final parsed = num.tryParse(value.toString());
    if (parsed == null) {
      throw Exception("Invalid numeric value for $fieldName → Received: $value");
    }
    return parsed;
  }


bool _loaded = false;

@override
AdminDashboardState build() {
  // Only run when user actually enters this screen AND only once
  if (!_loaded) {
    Future.microtask(() => loadDashboard());
    _loaded = true;
  }
  return const AdminDashboardState();
}





  Future<void> loadDashboard() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repo = ref.read(adminDashboardRepositoryProvider);
      final data = await repo.getDashboardData();
      print("ADMIN RAW DATA → $data");    // 🔥 Add this line

      final totals = data['totals'] ?? {};
      final charts = data['charts'] ?? {};
      final tables = data['tables'] ?? {};

      state = state.copyWith(
        loading: false,

        // totals
 grossRevenue: parseRequired(totals['gross_revenue'], "gross_revenue"),
totalSales: parseRequired(totals['total_sales'] ?? 0, "total_sales"),//adjusted 
totalPayments: parseRequired(totals['total_payments'], "total_payments"),
totalCustomers: parseRequired(totals['total_customers'], "total_customers"),
totalDiscount: parseRequired(totals['total_discount'], "total_discount"),
netSales: parseRequired(totals['net_sales'], "net_sales"),



        // charts
       weeklySummary: (charts['weekly_summary'] ?? []).map<Map<String, dynamic>>((row) {
  return {
    "day": row["day"],
    "revenue": parseRequired(row["revenue"], "weekly_summary.revenue"),
    "transactions": parseRequired(row["transactions"], "weekly_summary.transactions"),
  };
}).toList(),

      topProducts: (charts["top_products"] ?? []).map<Map<String, dynamic>>((row) {
  return {
    "name": row["name"],
    "total_qty": parseRequired(row["total_qty"], "top_products.total_qty"),
  };
}).toList(),

    salesBySalesperson: (charts["sales_by_salesperson"] is List)
    ? List<Map<String, dynamic>>.from(charts["sales_by_salesperson"])
    : [],


        // tables
      recentSales: (tables["recent_sales"] ?? []).map<Map<String, dynamic>>((row) {
  return {
    "id": row["id"],
    "customer": row["customer"],
    "sale_date": row["sale_date"],
    "total_amount": parseRequired(row["total_amount"], "recent_sales.total_amount"),
  };
}).toList(),

        lowStock: List<Map<String, dynamic>>.from(tables["low_stock"] ?? []),

      );
    } catch (e) {
      
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchDashboard() async {
  await loadDashboard();
}


}
