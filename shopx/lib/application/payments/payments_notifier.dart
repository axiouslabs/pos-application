import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/application/payments/payments_state.dart';
import 'package:shopx/infrastructure/payments/payment_repository.dart';

class PaymentsNotifier extends Notifier<PaymentsState> {
  @override
  PaymentsState build() => const PaymentsState();

  // ✅ Mark pending/partially_paid → paid
  Future<void> markPaymentAsPaid(int saleId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(paymentsRepositoryProvider);
      await repo.markPaymentAsPaid(saleId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ✅ Add partial payment
  Future<void> addPartialPayment({
    required int saleId,
    required int customerId,
    required double amount,
    String method = "cash",
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(paymentsRepositoryProvider);
      final result = await repo.addPartialPayment(
        saleId: saleId,
        customerId: customerId,
        amount: amount,
        method: method,
      );

      final summary = PaymentSummary.fromJson(result);
      state = state.copyWith(isLoading: false, summary: summary);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ✅ Fetch payment summary
  Future<void> fetchPaymentSummary(int saleId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(paymentsRepositoryProvider);
      final result = await repo.getPaymentSummary(saleId);

      final summary = PaymentSummary.fromJson(result);
      state = state.copyWith(isLoading: false, summary: summary);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ✅ Downgrade paid → pending (clears all payments)
  Future<void> markPaymentAsPending(int saleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(paymentsRepositoryProvider).markPaymentAsPending(saleId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // ✅ Downgrade paid → partially_paid (sets a specific paid amount)
  Future<void> markPaymentAsPartial({
    required int saleId,
    required double paidAmount,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref
          .read(paymentsRepositoryProvider)
          .markPaymentAsPartial(saleId: saleId, paidAmount: paidAmount);
      final summary = PaymentSummary.fromJson(result);
      state = state.copyWith(isLoading: false, summary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final paymentsNotifierProvider =
    NotifierProvider<PaymentsNotifier, PaymentsState>(
  PaymentsNotifier.new,
);
