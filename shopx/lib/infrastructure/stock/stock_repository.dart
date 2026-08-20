import 'package:shopx/infrastructure/stock/stock_api.dart';

class StockRepository {
  final StockApi api;

  StockRepository(this.api);

  /// Get stock for one product (allowed for USER)
  Future<double> getStockForProduct(String productId) async {
    return await api.getStock(productId);
  }
  
}
