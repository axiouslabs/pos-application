import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:shopx/application/salesPerformance/sales_performance_notifier.dart';
import 'package:shopx/application/salesPerformance/sales_performance_state.dart';
import 'package:shopx/application/salesman/salesman_notifier.dart';
import 'package:shopx/presentation/dashboard/admin/pages/productPerformance/product_performance_modal.dart';

class ProductPerformancePage extends HookConsumerWidget {
  const ProductPerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryBlue = const Color(0xFF1D72D6);
    final state = ref.watch(salesPerformanceNotifierProvider);
    useEffect(() {
      Future.microtask(() async {
        // 🔥 THIS WAS MISSING
        await ref.read(salesmanNotifierProvider.notifier).fetchSalesmen();

        // Load product performance
        final notifier = ref.read(salesPerformanceNotifierProvider.notifier);
        final s = ref.read(salesPerformanceNotifierProvider);

        notifier.loadAdminProductPerformance(
          start: s.startDate,
          end: s.endDate,
        );
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Product Performance",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await showDialog<ProductPerformanceFilterResult>(
                context: context,
                barrierDismissible: true,
                builder: (context) {
                  return Dialog(
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 80,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const ProductPerformanceFilterModal(),
                  );
                },
              );

              if (result != null) {
                ref
                    .read(salesPerformanceNotifierProvider.notifier)
                    .loadAdminProductPerformance(
                      start: result.startDate,
                      end: result.endDate,
                      salespersonId: result.salespersonId,
                    );
              }
            },

            icon: Icon(Icons.tune, color: primaryBlue),
            label: Text(
              "Filter",
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(state),
    );
  }

  Widget _buildList(SalesPerformanceState state) {
    final products = List<Map<String, dynamic>>.from(
      state.productSales["list"] ?? [],
    );

    if (products.isEmpty) {
      return const Center(child: Text("No product data available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];

        // return Container(
        //   margin: const EdgeInsets.only(bottom: 14),
        //   padding: const EdgeInsets.all(18),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(16),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.05),
        //         blurRadius: 15,
        //         offset: const Offset(0, 6),
        //       ),
        //     ],
        //   ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               p["product_name"] ?? "",
        //               style: const TextStyle(
        //                 fontSize: 16,
        //                 fontWeight: FontWeight.bold,
        //               ),
        //             ),
        //             const SizedBox(height: 6),
        //             Text(
        //               "Units Sold: ${p["units_sold"]}",
        //               style: const TextStyle(fontSize: 13, color: Colors.grey),
        //             ),
        //           ],
        //         ),
        //       ),
        //       Text(
        //         "SAR ${p["revenue"]}",
        //         style: const TextStyle(
        //           fontSize: 15,
        //           fontWeight: FontWeight.bold,
        //           color: Color(0xFF1D72D6),
        //         ),
        //       ),
        //     ],
        //   ),
        // );

        final revenueText =
            "SAR ${double.tryParse(p["revenue"].toString())?.toStringAsFixed(2) ?? "0.00"}";

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              Text(
                p["product_name"] ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Units
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${p["units_sold"] ?? 0} Units",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Revenue
                  Text(
                    revenueText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D72D6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
