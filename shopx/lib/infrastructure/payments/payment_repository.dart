import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/infrastructure/core/dio_provider.dart';
import 'package:shopx/infrastructure/payments/payments_api.dart';

class PaymentsRepository {
  final PaymentsApi api;

  PaymentsRepository(this.api);

  Future<void> markPaymentAsPaid(int saleId) async {
    await api.markPaymentAsPaid(saleId);
  }

  Future<Map<String, dynamic>> addPartialPayment({
    required int saleId,
    required int customerId,
    required double amount,
    String method = "cash",
  }) async {
    return await api.addPartialPayment(
      saleId: saleId,
      customerId: customerId,
      amount: amount,
      method: method,
    );
  }

  Future<Map<String, dynamic>> getPaymentSummary(int saleId) async {
    return await api.getPaymentSummary(saleId);
  }

  // paid → pending (removes all payment records for this sale)
  Future<void> markPaymentAsPending(int saleId) async {
    await api.markPaymentAsPending(saleId);
  }

  // paid → partially_paid (retains a specific paid amount, rest becomes balance)
  Future<Map<String, dynamic>> markPaymentAsPartial({
    required int saleId,
    required double paidAmount,
  }) async {
    return await api.markPaymentAsPartial(
      saleId: saleId,
      paidAmount: paidAmount,
    );
  }
}

// 🔌 Providers
final paymentsApiProvider = Provider<PaymentsApi>((ref) {
  return PaymentsApi(ref.read(dioProvider));
});

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.read(paymentsApiProvider));
});
