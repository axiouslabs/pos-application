import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/salesPerformance/sales_performance_notifier.dart';
import 'package:shopx/application/salesPerformance/sales_performance_state.dart';
import 'package:shopx/core/constants.dart';

class SalesPerformancePage extends HookConsumerWidget {
  const SalesPerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -------------------------------------------------------------------------
    // 1. STATE & NOTIFIER
    // -------------------------------------------------------------------------
    final state = ref.watch(salesPerformanceNotifierProvider);
    print(
      "DEBUG UI STATE → loading: ${state.loading}, error: ${state.error}, "
      "summaryKeys: ${state.summary.keys}, summaryEmpty: ${state.summary.isEmpty}",
    );

    print("🔍 UI STATE CHECK:");
    print("   Loading: ${state.loading}");
    print("   Error: ${state.error}");
    print("   Summary: ${state.summary}");
    print("   Salesmen count: ${state.salesmanList.length}");

    final notifier = ref.read(salesPerformanceNotifierProvider.notifier);

    final tabController = useTabController(initialLength: 4);
    final startDateController = useTextEditingController(text: state.startDate);
    final endDateController = useTextEditingController(text: state.endDate);

    // -------------------------------------------------------------------------
    // 3. THEME CONSTANTS
    // -------------------------------------------------------------------------
    const kPrimaryBlue = Color(0xFF1E75D5);
    const kBtnPurple = Color(0xFF5C3DC9);
    const kBtnGreen = Color(0xFF33BE5B);
    const kBgGrey = Color(0xFFF8F9FB);

    // -------------------------------------------------------------------------
    // 4. UI STRUCTURE
    // -------------------------------------------------------------------------
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Sales Performance",
          style: GoogleFonts.poppins(
            color: kPrimaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- FILTER SECTION ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDateRow(
                  context,
                  "Start Date",
                  startDateController,
                  notifier,
                ),
                const SizedBox(height: 12),
                _buildDateRow(context, "End Date", endDateController, notifier),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBtnPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    //                    onPressed: () {
                    //   final start = startDateController.text;
                    //   final end = endDateController.text;

                    //   notifier.filter(start, end);      // update dates in state
                    //   notifier.loadReport(start, end);  // FETCH DATA FROM BACKEND
                    // },
                    onPressed: () {
                      final start = startDateController.text;
                      final end = endDateController.text;

                      notifier.filter(
                        start,
                        end,
                      ); // filter ALREADY loads report.
                    },

                    icon: const Icon(Icons.search, color: Colors.white),
                    label: Text(
                      "Filter",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBtnGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {}, // Callback
                    child: Text(
                      "Download Report",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- TABS ---
          Container(
            color: Colors.white,
            child: TabBar(
              controller: tabController,
              labelColor: kPrimaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPrimaryBlue,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: "Summary\nOverview"),
                Tab(text: "Salesman\nPerformance"),
                Tab(text: "Product\nSales"),
                Tab(text: "Customer\nPerformance"),
              ],
            ),
          ),

          // --- TAB VIEWS ---
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _buildSummaryTab(state),
                _buildSalesmanTab(state),
                _buildProductTab(state),
                _buildCustomerTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🟦 TAB 1: SUMMARY OVERVIEW
  // ===========================================================================
  Widget _buildSummaryTab(SalesPerformanceState state) {
    final chartData = (state.summary['chart'] ?? []) as List;

    final maxRevenue = chartData.isEmpty
        ? 0
        : chartData
              .map((e) => num.tryParse(e['revenue'].toString()) ?? 0)
              .reduce((a, b) => a > b ? a : b);

    // Add 20% headroom (industry standard)
    final maxY = (maxRevenue * 1.2).ceilToDouble();

    final summary = state.summary['summary'];

    if (summary == null || summary['revenue'] == null) {
      return Center(child: Text("No summary data"));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards
          _buildInfoCard(
            title: "TOTAL REVENUE",
            value: "${state.summary['summary']?['revenue']}",
            icon: Icons.calendar_today_outlined,
            accentColor: const Color(0xFF5C3DC9),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            title: "UNITS SOLD",
            value: "${state.summary['summary']?['units']}",
            icon: Icons.inventory_2_outlined,
            accentColor: const Color(0xFF33BE5B),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            title: "AVG. TRANSACTION VALUE",
            value: "${state.summary['summary']?['avg_value']}",
            icon: Icons.people_outline,
            accentColor: const Color(0xFFFF9800),
          ),

          const SizedBox(height: 24),

          // Chart
          Text(
            "Overall Revenue by Salesman",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),

            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY == 0 ? 100 : maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final list = state.summary['chart'] as List;
                        if (value.toInt() >= 0 && value.toInt() < list.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              list[value.toInt()]['name'].toString().split(
                                ' ',
                              )[0],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text("\$0");
                        return Text(
                          "\$${(value / 1000).toInt()}k",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),

                barGroups: ((state.summary['chart'] ?? []) as List)
                    .asMap()
                    .entries
                    .map((e) {
                      final rev =
                          num.tryParse(e.value['revenue'].toString()) ?? 0;

                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: rev.toDouble(),
                            color: const Color(0xFF1E75D5),
                            width: 40,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🟦 TAB 2: SALESMAN PERFORMANCE
  // ===========================================================================
  Widget _buildSalesmanTab(SalesPerformanceState state) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Detailed Salesman Table",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Table Header
          Container(
            color: const Color(0xFFF8F9FB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "SALESMAN",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "TOTAL REVENUE",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "UNITS SOLD",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: state.salesmanList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = state.salesmanList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['name'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${item['revenue']}",

                          style: GoogleFonts.poppins(color: Colors.black54),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${item['units']}",
                          style: GoogleFonts.poppins(color: Colors.black54),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🟦 TAB 3: PRODUCT SALES
  // ===========================================================================
  Widget _buildProductTab(SalesPerformanceState state) {
    final pieData = state.productSales['pie'] as List?;
    final listData = state.productSales['list'] as List?;

    if (pieData == null || listData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Product-wise Sales Analysis",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Donut Chart
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 60,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      sections: pieData.map((e) {
                        return PieChartSectionData(
                          color: e['color'],
                          value: e['value'],
                          title: "",
                          radius: 30,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                  Center(
                    child: Text(
                      "Total",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            kHeight30,

            Text(
              "Product Revenue Breakdown",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Legend List (FIXED)
            ...listData.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color Dot
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Colors.primaries[listData.indexOf(item) %
                                Colors.primaries.length],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Product Details (NO OVERFLOW)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            item['name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Units Sold
                          Text(
                            "Units Sold: ${item['units']}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Revenue
                    Text(
                      "SAR ${item['revenue']}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  //customer
  Widget _buildCustomerTab(SalesPerformanceState state) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Customer Performance",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Table Header
          Container(
            color: const Color(0xFFF8F9FB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text("CUSTOMER", style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "REVENUE",
                    style: _headerStyle(),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "ORDERS",
                    style: _headerStyle(),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: state.customerList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = state.customerList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(item['customer'])),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${item['revenue']}",
                          textAlign: TextAlign.end,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${item['orders'] ?? 0}",
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    );
  }

  // ===========================================================================
  // 🛠 HELPER WIDGETS
  // ===========================================================================

  Widget _buildDateRow(
    BuildContext context,
    String label,
    TextEditingController controller,
    SalesPerformanceNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );

            if (picked != null) {
              final formatted = "${picked.year}-${picked.month}-${picked.day}";
              controller.text = formatted;

              // UPDATE STATE IN RIVERPOD IMMEDIATELY
              if (label == "Start Date") {
                notifier.updateStartDate(formatted);
              } else {
                notifier.updateEndDate(formatted);
              }
            }
          },

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1D1D),
            ),
          ),
        ],
      ),
    );
  }
}
