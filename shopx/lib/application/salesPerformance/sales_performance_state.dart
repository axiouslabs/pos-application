class SalesPerformanceState {
  final bool loading;
  final String? error;

  final String startDate;
  final String endDate;

  final Map<String, dynamic> summary; // summary + chart
  final List<Map<String, dynamic>> salesmanList;
final Map<String, dynamic> productSales;
final List<Map<String, dynamic>> customerList;


  const SalesPerformanceState({
    this.loading = false,
    this.error,
    this.startDate = "",
    this.endDate = "",
 this.summary = const {
      "summary": {},
      "chart": [],
    },
        this.salesmanList = const [],
    this.customerList = const [],

 // Provide default structure
    this.productSales = const {
      "pie": [],
      "list": [],
    },  });

  SalesPerformanceState copyWith({
    bool? loading,
    String? error,
    String? startDate,
    String? endDate,
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? salesmanList,
     Map<String, dynamic>? productSales,
     List<Map<String, dynamic>>? customerList,

  }) {
    return SalesPerformanceState(
      loading: loading ?? this.loading,
         error: error ?? this.error, 
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      summary: summary ?? this.summary,
      salesmanList: salesmanList ?? this.salesmanList,
      productSales: productSales ?? this.productSales,
      customerList: customerList ?? this.customerList,

    );
  }
}
