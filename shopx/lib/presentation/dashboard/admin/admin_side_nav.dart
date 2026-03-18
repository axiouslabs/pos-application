import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/presentation/dashboard/admin/admin_dashboard.dart';
import 'package:shopx/presentation/dashboard/admin/pages/bills/admin_customer_bills_selector_page.dart';
import 'package:shopx/presentation/dashboard/admin/pages/customer/admin_customer_list_page.dart';
import 'package:shopx/presentation/dashboard/admin/pages/productPerformance/product_performance.dart';
import 'package:shopx/presentation/dashboard/admin/pages/products/product_list_page.dart';
import 'package:shopx/presentation/dashboard/admin/pages/salesPerformance/sales_performance.dart';
import 'package:shopx/presentation/dashboard/admin/pages/salesperson/salesperson_list_page.dart';
import 'package:shopx/presentation/dashboard/admin/pages/settings/admin_settings_page.dart';
import 'package:shopx/presentation/dashboard/admin/pages/transaction/admin_transaction_history_page.dart';
import 'package:shopx/presentation/dashboard/user/pages/customers/customer_list_page.dart';

final ValueNotifier<int> adminNavIndex = ValueNotifier<int>(0);

class AdminSideNav extends HookConsumerWidget {
  const AdminSideNav({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
      // Watch the provider to get current selected index
final selectedIndex = adminNavIndex.value;
   

    // Menu Data Configuration
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Dashboard',
        'icon': Icons.grid_view, // Matches the 4-square grid
'builder': (BuildContext context) => const AdminDashboard(),

      },
      {
        'title': 'Manage Product',
        'icon': Icons.card_giftcard, // Matches the gift box
'builder': (context) => const adminProductListPage(),
      },
      {
        'title': 'Manage Salesman',
        'icon': Icons.supervised_user_circle_outlined, // Matches the user with badge
    'builder': (context) => const SalespersonListPage(),

      },
      {
        'title': 'Manage Customers',
        'icon': Icons.badge_outlined, // Matches the ID/Wallet card
    'builder': (context) => const AdminCustomerListPage(),
                //this is same for user also 

      },
      {
        'title': 'Reports & Analytics',
        'icon': Icons.bar_chart, // Matches the graph
    'builder': (context) => const SalesPerformancePage(),

      },

      {
  'title': 'Product Performance',
  'icon': Icons.inventory_2_outlined,
  'builder': (context) => const ProductPerformancePage(),
},

{
  'title': 'Bills',
  'icon': Icons.receipt,
  'builder': (context) => const AdminCustomerBillsSelectorPage(),
},


      {
  'title': 'Transactions History',
  'icon': Icons.receipt_long,
  'builder': (context) => const AdminTransactionHistoryPage(),
},


 // ✅ NEW — ADMIN SETTINGS
  {
    'title': 'Settings',
    'icon': Icons.settings,
    'builder': (context) => const AdminSettingsScreen(),
  },
    ];


    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Rectangular drawer as per image
      ),
      child: Column(
        children: [
          // ---------------------------
          // Header Section
          // ---------------------------
          Container(
            height: 100, // Adjust for status bar + header height
            padding: const EdgeInsets.fromLTRB(20, 40, 10, 20),
            color: const Color(0xFF1976D2), // Standard Material Blue
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Admin Menu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close drawer
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

         kHeight20,

          // ---------------------------
          // Menu Items List
          // ---------------------------
         Expanded(
  child: ValueListenableBuilder<int>(
    valueListenable: adminNavIndex,
    builder: (context, selectedIndex, _) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: menuItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final isSelected = selectedIndex == index;

          return InkWell(
            onTap: () {
              adminNavIndex.value = index;
              Navigator.pop(context);
              Navigator.push(
                context,
                  MaterialPageRoute(builder: (_) => item['builder'](context)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    item['icon'],
                    color: isSelected ? const Color(0xFF1976D2) : Colors.grey[600],
                  ),
                  const SizedBox(width: 16),
                  Text(
                    item['title'],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF1976D2) : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ),
),

// LOGOUT BUTTON

Padding(
  padding: const EdgeInsets.all(16),
  child: InkWell(
    onTap: () => _showLogoutDialog(context, ref),
    child: Row(
      children: const [
        Icon(Icons.logout, color: Colors.red),
        SizedBox(width: 12),
        Text(
          "Logout",
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),



        ],
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

