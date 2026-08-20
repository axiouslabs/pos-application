

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shopx/application/dashboard/admin_dashboard_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/presentation/dashboard/admin/admin_side_nav.dart';

class AdminDashboard extends HookConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

  



// Read notifier state
final dashboard = ref.watch(adminDashboardNotifierProvider);


// ADD THIS
if (dashboard.loading) {
  return const Center(child: CircularProgressIndicator());
}

if (dashboard.error != null) {
  return Center(
    child: Text(
      "Error loading dashboard: ${dashboard.error}",
      style: const TextStyle(color: Colors.red),
    ),
  );
}

final weekly = dashboard.weeklySummary;


final totalRevenue = dashboard.grossRevenue;          // Total Revenue
final totalSales = dashboard.totalSales;              // Total Sales (count)
final avgOrder = dashboard.totalSales == 0
    ? 0
    : dashboard.grossRevenue / dashboard.totalSales;  // Avg. Order Value
final totalCustomers = dashboard.totalCustomers;




    // -------------------------------------------------------------------------
    // 2. STYLES & CONSTANTS
    // -------------------------------------------------------------------------
    const kPrimaryBlue = Color(0xFF1E75D5);
    const kBgGrey = Color(0xFFF5F7FA);
    const kTextBlack = Color(0xFF1D1D1D);
    const kTextGrey = Color(0xFF888888);

    // -------------------------------------------------------------------------
    // 3. MAIN UI STRUCTURE
    // -------------------------------------------------------------------------
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AdminSideNav(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
       leading: Builder(
  builder: (context) {
    return IconButton(
      icon: const Icon(Icons.menu, color: kPrimaryBlue),
      onPressed: () {
        Scaffold.of(context).openDrawer(); // Works now
      },
    );
  },
),

        title: Text(
          "Admin",
          style: GoogleFonts.poppins(
            color: kPrimaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      
      ),

      
      body:
      
       RefreshIndicator(
        onRefresh: ()async{
          await ref 
          .read(adminDashboardNotifierProvider.notifier)
        .fetchDashboard();
        },
         child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- METRICS SECTION ---
              _MetricCard(
                title: "Total Revenue",
                value: "\$${totalRevenue.toStringAsFixed(2)}",
                icon: Icons.monetization_on_outlined,
              ),
              const SizedBox(height: 12),
              _MetricCard(
                title: "Total Sales",
                value: "$totalSales",
                icon: Icons.shopping_cart_outlined,
              ),
              const SizedBox(height: 12),
             _MetricCard(
           title: "Avg. Order value",
           value: "\$${avgOrder.toStringAsFixed(2)}",
           icon: Icons.show_chart,
              ),
              const SizedBox(height: 12),
              _MetricCard(
                title: "Total Customers",
                value: "$totalCustomers",
                icon: Icons.people_outline,
              ),
         
              const SizedBox(height: 24),
         
              // --- WEEKLY SUMMARY CHART ---
         _WeeklySummarySection(
           weekly: dashboard.weeklySummary,
           grossRevenue: dashboard.grossRevenue,
           netSales: dashboard.netSales,
           totalDiscount: dashboard.totalDiscount,
         ),
         
         
              const SizedBox(height: 24),
         
              // --- LATEST TRANSACTIONS ---
         _LatestTransactionsSection(recentSales: dashboard.recentSales),
              
              // Bottom padding for scrolling
              const SizedBox(height: 20),
            ],
          ),
               ),
       ),
    );
  }
}

// =============================================================================
// 🧩 SUB-WIDGET: METRIC CARD
// =============================================================================
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D1D1D),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 🧩 SUB-WIDGET: WEEKLY SUMMARY CHART
// =============================================================================

class _WeeklySummarySection extends StatelessWidget {
  final List<dynamic> weekly;
  final num grossRevenue;
  final num netSales;
  final num totalDiscount;

  const _WeeklySummarySection({
    required this.weekly,
    required this.grossRevenue,
    required this.netSales,
    required this.totalDiscount,
  });


  @override
  Widget build(BuildContext context) {


     // 1️⃣ Compute maximum revenue dynamically
  double maxRevenue = 0;

  for (final row in weekly) {
    final value = double.tryParse(row["revenue"].toString()) ?? 0;
    if (value > maxRevenue) maxRevenue = value;
  }

  // 2️⃣ Add padding so chart never touches the box border
  double maxYValue = maxRevenue == 0 ? 100 : maxRevenue * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Weekly Summary",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D1D1D),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
         kHeight20,

          // Chart


          
          SizedBox(
            height: 180,
            child: LineChart(     
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                 leftTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 30,
    interval: maxYValue / 4,   // ⭐ FIXED
    getTitlesWidget: (val, meta) {
      return Text(
        val.toInt().toString(),
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      );
    },
  ),
),

















                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxYValue,
                lineBarsData: [
                  LineChartBarData(
                 spots: weekly.asMap().entries.map((e) {
  final index = e.key;
  final row = e.value;

final revenue = double.tryParse(row["revenue"].toString()) ?? 0.7;

  return FlSpot(index.toDouble(), revenue);
}).toList(),

                    isCurved: true,
                    color: const Color(0xFF1E75D5),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x == 2, // Only show dot on peak
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E75D5).withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                // Tooltip setup to match image (Simplified static look)
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                  getTooltipColor:(spot) => const Color(0xFFE3F2FD),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          '112 Transaction',
                          GoogleFonts.poppins(
                            color: const Color(0xFF1E75D5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Stats Row
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    _buildSummaryStat(
      "Gross Revenue",
      "\$${grossRevenue.toStringAsFixed(2)}",
    ),
    _buildSummaryStat(
      "Net sales",
      "$netSales",
    ),
    _buildSummaryStat(
      "Discount",
      "\$${totalDiscount.toStringAsFixed(2)}",
    ),
  ],
)

        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1D1D),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 🧩 SUB-WIDGET: LATEST TRANSACTIONS LIST
// =============================================================================
class _LatestTransactionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> recentSales;

  const _LatestTransactionsSection({required this.recentSales});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Latest Transactions",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1D1D),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey)),
                    Text(
                      "SAR ${_todayTotal().toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D1D1D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE0E6ED)),

          // 🔥 DYNAMIC LIST
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSales.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF5F7FA)),
            itemBuilder: (context, index) {
              final sale = recentSales[index];
              return _TransactionItem(
                amount: "SAR ${sale['total_amount']}",
                timeId:
                    "${_formatDate(sale['sale_date'])} - #TRX${sale['id']}",
                status: "PAID",
              );
            },
          ),

          const Divider(height: 1, color: Color(0xFFE0E6ED)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "Show more",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E75D5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _todayTotal() {
    return recentSales.fold(
      0,
      (sum, item) => sum + (item['total_amount'] as num),
    );
  }

  String _formatDate(String date) {
    final d = DateTime.parse(date);
    return "${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }
}


class _TransactionItem extends StatelessWidget {
  final String amount;
  final String timeId;
  final String status;

  const _TransactionItem({
    required this.amount,
    required this.timeId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF223263), // Darker text for amount
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeId,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F5), // Light grey badge bg
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
