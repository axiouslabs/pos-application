import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/application/sales/sales_state.dart';
import 'package:shopx/domain/sales/sale.dart';
import 'package:shopx/infrastructure/sales/sales_repository.dart';

class SalesNotifier extends Notifier<SalesState> {
  @override
  SalesState build() => const SalesState();

  Future<int> createSale({
    required int customerId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String paymentStatus, // 👈 NEW
    required double discountAmount,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final repo = ref.read(salesRepositoryProvider);

      print("📌 SalesNotifier.createSale called");

      final saleId = await repo.createSale(
        customerId: customerId,
        items: items,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus, // 👈 NEW
        discountAmount: discountAmount,
      );

      state = state.copyWith(isLoading: false);
      return saleId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<Sale> getSale(int id) async {
    final repo = ref.read(salesRepositoryProvider);
    return await repo.getSaleById(id);
  }

  Future<Sale?> fetchSaleById(int id) async {
    try {
      state = state.copyWith(isLoading: true);
      final repo = ref.read(salesRepositoryProvider);
      final sale = await repo.getSaleById(id);
      state = state.copyWith(isLoading: false, sale: sale);
      return sale;
    } catch (e, stack) {
      print("❌ ERROR IN fetchSaleById: $e");
      print("❌ STACKTRACE: $stack");

      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  // ADMIN
  // Future<void> fetchAdminSales() async {
  //   state = state.copyWith(isLoading: true);
  //   try {
  //     final list = await ref.read(salesRepositoryProvider).getAdminSales();
  //     state = state.copyWith(isLoading: false, sales: list);
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //   }
  // }

  Future<void> fetchAdminSales({
  String? from,
  String? to,
  String? salesperson,
  String? status,
}) async {
  state = state.copyWith(isLoading: true);

  try {
    final list = await ref.read(salesRepositoryProvider).getAdminSales(
      from: from,
      to: to,
      salesperson: salesperson,
      status: status,
    );

    state = state.copyWith(isLoading: false, sales: list);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}

  // USER (already correct)
  Future<void> fetchMySales({
  String? from,
  String? to,
}) async {
  state = state.copyWith(isLoading: true);

  try {
    final list = await ref.read(salesRepositoryProvider).getMySales(
      from: from,
      to: to,
    );

    state = state.copyWith(isLoading: false, sales: list);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}
  // Future<void> fetchMySales() async {
  //   state = state.copyWith(isLoading: true);
  //   try {
  //     final list = await ref.read(salesRepositoryProvider).getMySales();
  //     state = state.copyWith(isLoading: false, sales: list);
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //   }
  // }

  

  Future<void> voidSale(int saleId) async {
    try {
      await ref.read(salesRepositoryProvider).voidSale(saleId);

      // ✅ Refresh BOTH datasets
      await fetchAdminSales();
      await fetchMySales();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> refreshAdminSales() async {
    await fetchAdminSales();
  }

  Future<int> reviseSale({
  required int originalSaleId,
  required int customerId,
  required List<Map<String, dynamic>> items,
  required String paymentMethod,
  required String paymentStatus,
  required double discountAmount,
}) async {
  state = state.copyWith(isLoading: true);

  try {
    final repo = ref.read(salesRepositoryProvider);

    final newSaleId = await repo.reviseSale(
      originalSaleId: originalSaleId,
      customerId: customerId,
      items: items,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      discountAmount: discountAmount,
    );

    state = state.copyWith(isLoading: false);
    return newSaleId;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    rethrow;
  }
}
}

final salesNotifierProvider = NotifierProvider<SalesNotifier, SalesState>(
  SalesNotifier.new,
);
