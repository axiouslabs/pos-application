import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/application/dashboard/admin_dashboard_notifier.dart';
import 'package:shopx/application/payments/payments_state.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/infrastructure/payments/payment_repository.dart';

class PaymentsNotifier extends Notifier<PaymentsState> {
  @override
  PaymentsState build() => const PaymentsState();

  // ✅ Mark pending → paid
  Future<void> markPaymentAsPaid(int saleId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(paymentsRepositoryProvider);

      //   await repo.markPaymentAsPaid(saleId);

      //     // 🔥 FORCE DASHBOARD + TRANSACTIONS TO REFRESH
      // ref.invalidate(adminDashboardNotifierProvider);
      // ref.invalidate(salesNotifierProvider);

      await repo.markPaymentAsPaid(saleId);

      // ✅ Refresh sales properly
      await ref.read(salesNotifierProvider.notifier).fetchAdminSales();
      await ref.read(salesNotifierProvider.notifier).fetchMySales();

      // Optional: refresh dashboard
      ref.invalidate(adminDashboardNotifierProvider);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final paymentsNotifierProvider =
    NotifierProvider<PaymentsNotifier, PaymentsState>(PaymentsNotifier.new);
