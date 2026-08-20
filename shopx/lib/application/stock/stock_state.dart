class StockState {
  final bool isLoading;
  final Map<String, double> stock; // productId → quantity
  final String? error;

  StockState({
    this.isLoading = false,
    this.stock = const {},
    this.error,
  });

  StockState copyWith({
    bool? isLoading,
    Map<String, double>? stock,
    String? error,
  }) {
    return StockState(
      isLoading: isLoading ?? this.isLoading,
      stock: stock ?? this.stock,
      error: error,
    );
  }
}
