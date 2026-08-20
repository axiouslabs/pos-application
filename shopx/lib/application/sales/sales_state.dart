import 'package:shopx/domain/sales/sale.dart';

class SalesState {
  final bool isLoading;
  final String? error;
  final Sale? sale;
  final List<Sale> sales;

  const SalesState({
    this.isLoading = false,
    this.error,
    this.sale,
    this.sales = const [],
  });

  SalesState copyWith({
    bool? isLoading,
    String? error,
    Sale? sale,
    List<Sale>? sales,
  }) {
    return SalesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sale: sale ?? this.sale,
      sales: sales ?? this.sales,
    );
  }
}

/*Dio (water tap)
    ↓
SalesApi (pipe taking water to kitchen)
    ↓
SalesRepository (filter cleaning the water)
    ↓
SalesNotifier (serves the water to the table)
    ↓
UI widgets (people drink the water)
 */