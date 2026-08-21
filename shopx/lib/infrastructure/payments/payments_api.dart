import 'package:dio/dio.dart';

class PaymentsApi {
  final Dio dio;

  PaymentsApi(this.dio);

  // POST /payments/:saleId/mark-paid
  Future<void> markPaymentAsPaid(int saleId) async {
    await dio.post('payments/$saleId/mark-paid');
  }

  // POST /payments/:saleId/partial-payment
  Future<Map<String, dynamic>> addPartialPayment({
    required int saleId,
    required int customerId,
    required double amount,
    String method = "cash",
  }) async {
    final res = await dio.post(
      'payments/$saleId/partial-payment',
      data: {
        "customerId": customerId,
        "amount": amount,
        "method": method,
      },
    );
    return res.data;
  }

  // GET /payments/:saleId/summary
  Future<Map<String, dynamic>> getPaymentSummary(int saleId) async {
    final res = await dio.get('payments/$saleId/summary');
    return res.data;
  }

  // PATCH /payments/:saleId/mark-pending  →  paid → pending (clears all payments)
  Future<void> markPaymentAsPending(int saleId) async {
    await dio.patch('payments/$saleId/mark-pending');
  }

  // PATCH /payments/:saleId/mark-partial  →  paid → partially_paid (keeps paidAmount)
  Future<Map<String, dynamic>> markPaymentAsPartial({
    required int saleId,
    required double paidAmount,
  }) async {
    final res = await dio.patch(
      'payments/$saleId/mark-partial',
      data: {"paid_amount": paidAmount},
    );
    return res.data;
  }

  // DELETE /payments/:saleId/reverse-partial  →  partially_paid → pending (paid=0)
  Future<Map<String, dynamic>> reversePartialPayment(int saleId) async {
    final res = await dio.delete('payments/$saleId/reverse-partial');
    return res.data;
  }
}
