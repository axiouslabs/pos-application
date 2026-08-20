import 'package:shopx/domain/customers/customer.dart';

class CustomerState {
  final bool isLoading;
  final String? error;
  final bool success;
  final List<Customer> customers;

  CustomerState({
    this.isLoading = false,
    this.error,
    this.success = false,
    this.customers = const [],
  });

  CustomerState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    List<Customer>? customers,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
      customers: customers ?? this.customers,
    );
  }
}
