/*

 "username": "employee1",
  "email": "employee1@gmail.com",
  "password": "12345678",
  "phone": "9876543210"

*/

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/cart/cart_notifier.dart';
import 'package:shopx/application/products/product_state.dart';
import 'package:shopx/application/stock/stock_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/domain/products/product.dart';
import 'package:shopx/application/auth/auth_notifier.dart'; // Adjust if path differs
// Import your provider file location
import 'package:shopx/application/products/product_notifier.dart';
import 'package:shopx/presentation/cart/add_quantity_dialog.dart';
import 'package:shopx/presentation/cart/cart_screen.dart';
import 'package:shopx/presentation/dashboard/user/pages/bottomnav/manual_entry_page.dart';
import 'package:shopx/presentation/dashboard/user/pages/customers/add_customer_page.dart';
import 'package:shopx/presentation/dashboard/user/pages/customers/customer_list_page.dart';
import 'package:shopx/presentation/dashboard/user/pages/products/products_list_page.dart';
import 'package:shopx/presentation/dashboard/user/pages/transactions/transaction_history_page.dart';
import 'package:shopx/presentation/dashboard/user/user_side_nav.dart'; // Ensure this points to where you defined productNotifierProvider

class UserDashboard extends HookConsumerWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch products on initial load
    useEffect(() {
      Future.microtask(() {
        ref.read(productNotifierProvider.notifier).fetchProducts();
      });
      return null;
    }, []);

    // 2. Watch State
    final productState = ref.watch(productNotifierProvider);
    final user = ref.watch(authNotifierProvider).user;
    final cartState = ref.watch(cartProvider);

    // 3. Local UI State (Hooks)
    final isGridView = useState(true); // Toggle Grid/List
    final isSearchActive = useState(false); // Toggle Search Bar
    final searchQuery = useState(""); // Search Text
    final searchController = useTextEditingController();
    final sortOption = useState("All"); // Sorting: All, LowToHigh, HighToLow

    // 4. Filter & Sort Logic
    List<Product> getProcessedProducts() {
      List<Product> items = List.from(productState.products);

      // Filter by Search
      if (searchQuery.value.isNotEmpty) {
        items = items
            .where(
              (p) =>
                  p.name.toLowerCase().contains(
                    searchQuery.value.toLowerCase(),
                  ) ||
                  p.category.toLowerCase().contains(
                    searchQuery.value.toLowerCase(),
                  ),
            )
            .toList();
      }

      // Sort
      if (sortOption.value == "LowToHigh") {
        items.sort((a, b) => a.price.compareTo(b.price));
      } else if (sortOption.value == "HighToLow") {
        items.sort((a, b) => b.price.compareTo(a.price));
      }

      return items;
    }

    final displayProducts = getProcessedProducts();

    final currentTab = useState(0);
    final showCodes = useState(false); // <-- NEW

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: UserSideNav(
        onChangeTab: (tabIndex) {
          currentTab.value = tabIndex;
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER (Time, Menu, Username) ---
            // Show header ONLY for tabs 0 and 1
            if (currentTab.value == 0 || currentTab.value == 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.blue),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),

                    // ✅ SHOW USERNAME HERE
                    Text(
                      user?.username ?? "UserName",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 40),
                  ],
                ),
              ),

            // --- SHOW CONTROLS ONLY IN PRODUCTS TAB ---
            if (currentTab.value == 0)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: isSearchActive.value
                    ? _buildSearchBar(
                        isSearchActive,
                        searchQuery,
                        searchController,
                      )
                    : _buildControlBar(
                        isSearchActive,
                        isGridView,
                        sortOption,
                        showCodes,
                      ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 24, top: 10, bottom: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manual entry",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

            // --- PRODUCT CONTENT ---
            Expanded(
              child: Builder(
                builder: (context) {
                  if (currentTab.value == 0) {
                    return _buildProductsUI(
                      productState,
                      displayProducts,
                      ref,
                      isGridView,
                      showCodes,
                    );
                  } else if (currentTab.value == 1) {
                    return const ManualEntryPage(); // bottom nav item
                  } else if (currentTab.value == 2) {
                    return const userProductListPage(); // from drawer
                  } else if (currentTab.value == 3) {
                    return const TransactionHistoryPage(); // from drawer
                  } else if (currentTab.value == 4) {
                    return const CustomerListPage(); // from drawer
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),

            // --- BOTTOM CART BAR ---
            if (currentTab.value == 0 && cartState.items.isNotEmpty)
              _buildBottomCartBar(
                context,
                cartState.items.length,
                cartState.totalPrice,
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, currentTab),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildControlBar(
    ValueNotifier<bool> isSearchActive,
    ValueNotifier<bool> isGridView,
    ValueNotifier<String> sortOption,
    ValueNotifier<bool> showCodes,
  ) {
    return Row(
      children: [
        // Sort Dropdown
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              focusColor: Colors.white,
              value:
                  sortOption.value == "All" ||
                      sortOption.value == "LowToHigh" ||
                      sortOption.value == "HighToLow"
                  ? sortOption.value
                  : "All",
              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
              isExpanded: true,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              items: const [
                DropdownMenuItem(value: "All", child: Text("All products")),
                DropdownMenuItem(
                  value: "LowToHigh",
                  child: Text("Price: Low to High"),
                ),
                DropdownMenuItem(
                  value: "HighToLow",
                  child: Text("Price: High to Low"),
                ),
              ],
              onChanged: (val) {
                if (val != null) sortOption.value = val;
              },
            ),
          ),
        ),

        // Vertical Divider
        Container(height: 20, width: 1, color: Colors.grey[300]),
        const SizedBox(width: 8),

        // Search Icon
        IconButton(
          icon: Icon(Icons.search, color: Colors.black),
          onPressed: () => isSearchActive.value = true,
        ),

        // Barcode Icon (Mock)
        IconButton(
          icon: Image.asset(
            "assets/images/bar-code.png",
            width: 20,
            height: 20,
            color: Colors.black,
          ),
          onPressed: () {
            showCodes.value = !showCodes.value; // <-- toggle visibility
          },
        ),

        // View Toggle Icon
        IconButton(
          icon: Icon(
            isGridView.value ? Icons.list : Icons.grid_view,
            color: Colors.black54,
          ),
          onPressed: () => isGridView.value = !isGridView.value,
        ),
      ],
    );
  }

  Widget _buildSearchBar(
    ValueNotifier<bool> isSearchActive,
    ValueNotifier<String> searchQuery,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        const Icon(Icons.search, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Search...",
              border: InputBorder.none,
            ),
            onChanged: (val) => searchQuery.value = val,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            searchQuery.value = "";
            controller.clear();
            isSearchActive.value = false;
          },
        ),
      ],
    );
  }

  // --- GRID VIEW IMPLEMENTATION ---
  Widget _buildGridView(
    List<Product> products,
    WidgetRef ref,
    ValueNotifier<bool> showCodes,
  ) {
    // return GridView.builder(
    //   physics: const AlwaysScrollableScrollPhysics(),
    //   padding: const EdgeInsets.only(top: 10, bottom: 80),
    //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //     crossAxisCount: 2,
    //     childAspectRatio: 0.75, // Adjust height ratio
    //     crossAxisSpacing: 15,
    //     mainAxisSpacing: 15,
    //   ),
    //   itemCount: products.length,
    //   itemBuilder: (context, index) {
    //     final product = products[index];

    return MasonryGridView.count(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),

            // Product Image (Placeholder)
            // Expanded(
            //   child: Center(
            //     child: Container(
            //       decoration: BoxDecoration(
            //         color: Colors.grey[100],
            //         borderRadius: BorderRadius.circular(15),
            //       ),
            //       child: product.images.isEmpty
            //           ? const Icon(
            //               Icons.image_not_supported,
            //               size: 40,
            //               color: Colors.grey,
            //             )
            //           : ClipRRect(
            //               borderRadius: BorderRadius.circular(15),
            //               child: Image.network(
            //                 "http://localhost:5000" + product.images.first,
            //                 fit: BoxFit.cover,
            //                 width: double.infinity,
            //                 height: double.infinity,
            //               ),
            //             ),
            //     ),
            //   ),
            // ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                kHeight10,
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

                if (showCodes.value) // <-- SHOW ONLY WHEN TOGGLED
                  Text(
                    "Code: ${product.code}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                const SizedBox(height: 4),

                Text(
                  product.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SAR ${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        // 1️⃣ Load backend stock BEFORE using dialog
                        await ref
                            .read(stockNotifierProvider.notifier)
                            .loadStockForProduct(product.id!);

                        // 2️⃣ Show dialog WITH real stock
                        showDialog(
                          context: context,
                          builder: (_) => AddQuantityDialog(
                            product: product,
                            onAddToCart: (qty) {
                              // 1️⃣ Add to cart provider
                              ref
                                  .read(cartProvider.notifier)
                                  .addToCart(product, qty);

                              // 2️⃣ Show message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Added to cart"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        );
                      },

                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LIST VIEW IMPLEMENTATION ---
  Widget _buildListView(
    List<Product> products,
    WidgetRef ref,
    ValueNotifier<bool> showCodes,
  ) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemCount: products.length,
      separatorBuilder: (c, i) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          height: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image
              // Container(
              //   width: 80,
              //   height: 80,
              //   decoration: BoxDecoration(
              //     color: Colors.grey[100],
              //     borderRadius: BorderRadius.circular(15),
              //   ),
              //   child: product.images.isEmpty
              //       ? const Icon(
              //           Icons.image_not_supported,
              //           size: 40,
              //           color: Colors.grey,
              //         )
              //       : ClipRRect(
              //           borderRadius: BorderRadius.circular(15),
              //           child: Image.network(
              //             "http://localhost:5000" + product.images.first,
              //             fit: BoxFit.cover,
              //           ),
              //         ),
              // ),

              // const SizedBox(width: 15),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    if (showCodes.value)
                      Text(
                        "Code: ${product.code}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                    Text(
                      product.category,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      "SAR ${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Add Button
              InkWell(
                onTap: () async {
                  // 1️⃣ Load backend stock BEFORE using dialog
                  await ref
                      .read(stockNotifierProvider.notifier)
                      .loadStockForProduct(product.id!);
                  // 2️⃣ Show dialog WITH real stock
                  showDialog(
                    context: context,
                    builder: (_) => AddQuantityDialog(
                      product: product,

                      onAddToCart: (qty) {
                        // 1️⃣ Add to cart provider
                        ref.read(cartProvider.notifier).addToCart(product, qty);

                        // 2️⃣ Show message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Added to cart"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },

                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTTOM CART SUMMARY BAR ---
  Widget _buildBottomCartBar(
    BuildContext context,
    int count,
    double totalPrice,
  ) {
    // Note: 'Total' is hardcoded or sum of displayed items for UI purposes.
    // In real app, connect this to a CartProvider

    // return Container(
    //   margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    //   decoration: BoxDecoration(
    //     color: const Color(0xFF1565C0), // Darker Blue
    //     borderRadius: BorderRadius.circular(15),
    //   ),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //     children: [
    //       GestureDetector(
    //         onTap: () {
    //           Navigator.push(
    //             context,
    //             MaterialPageRoute(builder: (_) => const CartScreen()),
    //           );
    //         },
    //         child: Row(
    //           children: [
    //             const Icon(Icons.shopping_cart_outlined, color: Colors.white),
    //             const SizedBox(width: 10),
    //             Text(
    //               "$count elements",
    //               style: const TextStyle(
    //                 color: Colors.white,
    //                 fontWeight: FontWeight.w500,
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),

    //       Text(
    //         "Total: SAR ${totalPrice.toStringAsFixed(2)}",
    //         style: const TextStyle(
    //           color: Colors.white,
    //           fontWeight: FontWeight.bold,
    //         ),
    //       ),
    //     ],
    //   ),
    // );

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  "$count elements",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              "Total: SAR ${totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavBar(
    BuildContext context,
    ValueNotifier<int> currentTab,
  ) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(
            icon: Icons.grid_view_rounded,
            isActive: currentTab.value == 0,
            onTap: () => currentTab.value = 0,
          ),
          _navIcon(
            icon: Icons.edit_note,
            isActive: currentTab.value == 1,
            onTap: () => currentTab.value = 1,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsUI(
    productState,
    displayProducts,
    WidgetRef ref,
    ValueNotifier<bool> isGridView,
    ValueNotifier<bool> showCodes,
  ) {
    if (productState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (productState.error != null) {
      return Center(child: Text("Error: ${productState.error}"));
    }
    if (displayProducts.isEmpty) {
      return const Center(child: Text("No products found."));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(productNotifierProvider.notifier).fetchProducts();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: isGridView.value
            ? _buildGridView(displayProducts, ref, showCodes)
            : _buildListView(displayProducts, ref, showCodes),
      ),
    );
  }

  //widget same size
  Widget _navIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(
            icon,
            size: 28, // smaller icon, consistent visual weight
            color: isActive ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }
}
