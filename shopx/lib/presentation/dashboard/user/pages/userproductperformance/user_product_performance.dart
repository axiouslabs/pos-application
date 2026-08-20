import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/application/salesPerformance/sales_performance_notifier.dart';
import 'package:shopx/application/salesPerformance/sales_performance_state.dart';
import 'package:shopx/presentation/dashboard/user/pages/userproductperformance/user_product_performance_modal.dart';

class UserProductPerformancePage extends HookConsumerWidget {
  const UserProductPerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryBlue = const Color(0xFF1D72D6);

    final authState = ref.watch(authNotifierProvider);
    

    final state = ref.watch(salesPerformanceNotifierProvider);

    useEffect(() {
      Future.microtask(() {
        ref.read(salesPerformanceNotifierProvider.notifier)
            .loadUserProductPerformance(
              start: state.startDate,
              end: state.endDate,
            
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
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
           onPressed: () async {
  final result =
      await showDialog<UserProductPerformanceFilterResult>(
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
        child: const UserProductPerformanceModal(),
      );
    },
  );

  if (result != null) {
    ref
        .read(salesPerformanceNotifierProvider.notifier)
        .loadUserProductPerformance(
          start: result.startDate,
          end: result.endDate,
        );
  }
},

            icon: Icon(Icons.tune, color: primaryBlue),
            label: Text(
              "Filter",
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(state),
    );
  }

  Widget _buildList(SalesPerformanceState state) {
    final products =
        List<Map<String, dynamic>>.from(state.productSales["list"] ?? []);

    if (products.isEmpty) {
      return const Center(child: Text("No product data available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p["product_name"] ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Units Sold: ${p["units_sold"]}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "SAR ${p["revenue"]}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D72D6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
