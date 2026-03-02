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
    case "pending":
      statusColor = Colors.orange;
      statusText = "PENDING";
      break;
    case "paid":
      statusColor = Colors.green;
      statusText = "PAID";
      break;
    default:
      statusColor = Colors.grey;
      statusText = sale.paymentStatus.toUpperCase();
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
        // Expanded(
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         "SAR ${sale.totalAmount.toStringAsFixed(2)}",
        //         style: const TextStyle(
        //           fontSize: 16,
        //           fontWeight: FontWeight.bold,
        //           color: Color(0xFF1F2937),
        //         ),
        //       ),
        //       const SizedBox(height: 4),
        //       Text(
        //         "$timeString - $trxId",
        //         style: const TextStyle(
        //           fontSize: 12,
        //           color: Color(0xFF536471),
        //         ),
        //         maxLines: 1,
        //         overflow: TextOverflow.ellipsis,
        //       ),
        //     ],
        //   ),
        // ),

        Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 💰 Amount
      Text(
        "SAR ${sale.totalAmount.toStringAsFixed(2)}",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),

      const SizedBox(height: 4),

      // 👤 Customer Name (NEW)
      Text(
        sale.customerName,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      const SizedBox(height: 4),

      // 🕒 Time + TRX
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
