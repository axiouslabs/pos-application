import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopx/domain/sales/sale.dart';

Widget buildTransactionCard(Sale sale, Color primaryBlue) {
  final timeString = DateFormat('hh:mm a').format(sale.saleDate);
  final trxId = "#TRX${sale.id.toString().padLeft(10, '0')}";

  // ✅ MOVE LOGIC OUTSIDE WIDGET TREE
  late Color statusColor;
  late String statusText;

  switch (sale.paymentStatus.toLowerCase()) {
    case "paid":
      statusColor = const Color(0xFF1D72D6);
      statusText = "PAID";
      break;
    case "pending":
      statusColor = const Color(0xFFF59E0B);
      statusText = "PENDING";
      break;
    case "partially_paid":
      statusColor = const Color(0xFFF97316);
      statusText = "PARTIAL";
      break;
    case "void":
    case "voided":
      statusColor = const Color(0xFF9CA3AF);
      statusText = "VOIDED";
      break;
    default:
      statusColor = const Color(0xFF9CA3AF);
      statusText = sale.paymentStatus.toUpperCase().replaceAll('_', ' ');
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          blurRadius: 20,
          color: Colors.black.withOpacity(0.06),
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LEFT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SAR ${sale.totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$timeString - $trxId",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF536471),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // RIGHT — STATUS BADGE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    ),
  );
}
