import 'package:equatable/equatable.dart';

class PaymentsState extends Equatable {
  final bool isLoading;
  final String? error;
  final PaymentSummary? summary;

  const PaymentsState({
    this.isLoading = false,
    this.error,
    this.summary,
  });

  PaymentsState copyWith({
    bool? isLoading,
    String? error,
    PaymentSummary? summary,
  }) {
    return PaymentsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, summary];
}

class PaymentSummary extends Equatable {
  final int saleId;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final String paymentStatus;

  const PaymentSummary({
    required this.saleId,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.paymentStatus,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      saleId: json['sale_id'] ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0,
      paidAmount: double.tryParse(json['paid_amount'].toString()) ?? 0,
      balance: double.tryParse(json['balance'].toString()) ?? 0,
      paymentStatus: json['payment_status'] ?? 'pending',
    );
  }

  @override
  List<Object?> get props =>
      [saleId, totalAmount, paidAmount, balance, paymentStatus];
}
