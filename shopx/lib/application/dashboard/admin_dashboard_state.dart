class AdminDashboardState {
  final bool loading;
  final String? error;
// totals
final num grossRevenue;     // NEW
final num totalSales;       // KEEP (order count)
final num totalPayments;
final num pendingAmount;
final num todaySales;
final num totalCustomers;
final num totalDiscount;    // NEW
final num netSales;         // NEW


  // charts
  final List<Map<String, dynamic>> weeklySummary;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> salesBySalesperson;

  // tables
  final List<Map<String, dynamic>> recentSales;
  final List<Map<String, dynamic>> lowStock;

  const AdminDashboardState({
    this.loading = false,
    this.error,

   this.grossRevenue = 0,      // NEW
this.totalSales = 0,        // KEEP
this.totalPayments = 0,
this.pendingAmount = 0,
this.todaySales = 0,
this.totalCustomers = 0,
this.totalDiscount = 0,     // NEW
this.netSales = 0,          // NEW


    this.weeklySummary = const [],
    this.topProducts = const [],
    this.salesBySalesperson = const [],

    this.recentSales = const [],
    this.lowStock = const [],
  });

  AdminDashboardState copyWith({
    bool? loading,
    String? error,

  num? grossRevenue,       // NEW
num? totalSales,         // KEEP
num? totalPayments,
num? pendingAmount,
num? todaySales,
num? totalCustomers,
num? totalDiscount,      // NEW
num? netSales,           // NEW


    List<Map<String, dynamic>>? weeklySummary,
    List<Map<String, dynamic>>? topProducts,
    List<Map<String, dynamic>>? salesBySalesperson,

    List<Map<String, dynamic>>? recentSales,
    List<Map<String, dynamic>>? lowStock,
  }) {
    return AdminDashboardState(
      loading: loading ?? this.loading,
      error: error,
grossRevenue: grossRevenue ?? this.grossRevenue,
totalSales: totalSales ?? this.totalSales,
totalPayments: totalPayments ?? this.totalPayments,
pendingAmount: pendingAmount ?? this.pendingAmount,
todaySales: todaySales ?? this.todaySales,
totalCustomers: totalCustomers ?? this.totalCustomers,
totalDiscount: totalDiscount ?? this.totalDiscount,
netSales: netSales ?? this.netSales,


      weeklySummary: weeklySummary ?? this.weeklySummary,
      topProducts: topProducts ?? this.topProducts,
      salesBySalesperson: salesBySalesperson ?? this.salesBySalesperson,

      recentSales: recentSales ?? this.recentSales,
      lowStock: lowStock ?? this.lowStock,
    );
  }
}
