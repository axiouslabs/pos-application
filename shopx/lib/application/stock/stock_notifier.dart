import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/stock/stock_state.dart';
import 'package:shopx/infrastructure/stock/stock_api.dart';
import 'package:shopx/infrastructure/stock/stock_repository.dart';

/// ⭐ You MUST restore the provider here
final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(ref.read(stockApiProvider));
});

class StockNotifier extends Notifier<StockState> {
  @override
  StockState build() {
    return StockState();
  }

  /// Load stock ONLY for a single product
  Future<void> loadStockForProduct(String productId) async {
    state = state.copyWith(isLoading: true);

    try {
      final repo = ref.read(stockRepositoryProvider);
      final qty = await repo.getStockForProduct(productId);

      state = state.copyWith(
        isLoading: false,
        stock: { productId: qty }, // store only one value
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  double getStockForProduct(String productId) {
    return state.stock[productId] ?? 0.0;
  }
}

/// ⭐ Provider for your Notifier
final stockNotifierProvider =
    NotifierProvider<StockNotifier, StockState>(StockNotifier.new);
