import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/presentation/dashboard/user/pages/customers/customer_list_page.dart';
import 'package:shopx/presentation/dashboard/user/pages/products/products_list_page.dart';
import 'package:shopx/presentation/dashboard/user/pages/transactions/transaction_history_page.dart';
import 'package:shopx/presentation/dashboard/user/pages/userproductperformance/user_product_performance.dart';
import 'package:shopx/widget/usersidenav/drawer_menu_item.dart';

class UserSideNav extends HookConsumerWidget {
  final Function(int) onChangeTab;
  const UserSideNav({super.key,
  required this.onChangeTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    // Define the primary blue color from the design
    const Color primaryBlue = Color(0xFF1976D2);

    // Dynamic Date
    final now = DateTime.now();
    final lastConnectionDate =
        DateFormat("MMMM d, yyyy").format(now) +
        "\n(${DateFormat('hh:mm a').format(now)})";

    return Drawer(
      width: 280, // Fixed width panel
      backgroundColor: primaryBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP HEADER SECTION ---
              Row(
                children: [
                  // Logo Box
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_cafe, // Coffee cup icon
                      color: primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Brand Title
                  const Text(
                    "Joy Brews",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Username
              Text(
                user?.username ?? "User",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              kHeight40,

              // --- MENU ITEMS SECTION ---
          DrawerMenuItem(
  label: "Products",
  icon: Icons.point_of_sale_outlined,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const userProductListPage()),
    );
  },
),


              const SizedBox(height: 24),
DrawerMenuItem(
  label: "Transaction History",
  icon: Icons.monetization_on_outlined,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionHistoryPage()),
    );
  },
),

const SizedBox(height: 24),

DrawerMenuItem(
  label: "Product Performance",
  icon: Icons.bar_chart_outlined,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserProductPerformancePage(),
      ),
    );
  },
),



              const SizedBox(height: 24),

            DrawerMenuItem(
  label: "Manage the customer",
  icon: Icons.storefront_outlined,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerListPage()),
    );
  },
),


              // --- BOTTOM SPACER ---
              const Spacer(),

           

              // LOGOUT BUTTON
              InkWell(
  onTap: () => _showLogoutDialog(context, ref),
  child: Row(
    children: const [
      Icon(Icons.logout, color: Colors.white),
      SizedBox(width: 12),
      Text(
        "Logout",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),
kHeight20,

   // --- BOTTOM "Last Connection" SECTION ---
            //   Row(
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     children: [
            //       // Refresh/Sync Icon Box
            //       Container(
            //         width: 45,
            //         height: 45,
            //         decoration: BoxDecoration(
            //           color: Colors.white.withOpacity(0.2),
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: const Icon(
            //           Icons.sync,
            //           color: Colors.white,
            //           size: 24,
            //         ),
            //       ),
            //       const SizedBox(width: 16),

            //       // Text Info
            //       Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Text(
            //             "Last connection:",
            //             style: TextStyle(
            //               color: Colors.white,
            //               fontSize: 12,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //           const SizedBox(height: 4),
            //           Text(
            //             lastConnectionDate,
            //             style: TextStyle(
            //               color: Colors.white.withOpacity(0.8),
            //               fontSize: 10,
            //               height: 1.2,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            //  kHeight10,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );

  if (shouldLogout == true) {
    ref.read(authNotifierProvider.notifier).logout();
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }
}

}
