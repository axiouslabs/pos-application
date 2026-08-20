import 'package:shopx/domain/salesman/salesman.dart';

class SalesmanState {
  final bool isLoading;
  final String? error;
  final bool success;
  final List<Salesman> salesmen;

  SalesmanState({
    this.isLoading = false,
    this.error,
    this.success = false,
    this.salesmen = const [],
  });

  SalesmanState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    List<Salesman>? salesmen,
  }) {
    return SalesmanState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
      salesmen: salesmen ?? this.salesmen,
    );
  }
}
