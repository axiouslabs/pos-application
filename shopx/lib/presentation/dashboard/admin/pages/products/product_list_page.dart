import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:shopx/application/products/product_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/presentation/products/add_product_screen.dart';

class adminProductListPage extends HookConsumerWidget {
  const adminProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Product State (Loading, List, Error)
    final productState = ref.watch(productNotifierProvider);

    // Fetch products once when page mounts
    useEffect(() {
      Future.microtask(
        () => ref.read(productNotifierProvider.notifier).fetchProducts(),
      );
      return null;
    }, []);

    // Local State for Search
    final searchController = useTextEditingController();
    final searchText = useState("");
    final selectedCategory = useState<String>("All");

    final categories = {
      "All",
      ...productState.products.map((p) => p.category),
    }.toList();

    // Listener for search text changes
    useEffect(() {
      searchController.addListener(() {
        searchText.value = searchController.text;
      });
      return null;
    }, [searchController]);

    // Local State for "Modify Page" View (Expanded Card)
    // If a string ID is stored here, that card shows the Modify/Delete buttons
    final expandedProductId = useState<String?>(null);

    // -------------------------------------------------------------------------
    // 2. STYLES & CONSTANTS
    // -------------------------------------------------------------------------
    const primaryBlue = Color(0xFF1976D2);
    const deleteRed = Color(0xFFEF3838); // Specific red from design
    const bgGrey = Color(0xFFF8F9FB);
    const textDark = Color(0xFF1D1D1D);
    const textGrey = Color(0xFF888888);

    // -------------------------------------------------------------------------
    // 3. FILTER LOGIC
    // -------------------------------------------------------------------------
    final filteredProducts = productState.products.where((product) {
      final matchesSearch =
          searchText.value.isEmpty ||
          product.name.toLowerCase().contains(searchText.value.toLowerCase());

      final matchesCategory =
          selectedCategory.value == "All" ||
          product.category == selectedCategory.value;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: primaryBlue,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Product List",
          style: TextStyle(
            color: primaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // SCROLLABLE CONTENT
          // -------------------------------------------------------------------
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(productNotifierProvider.notifier)
                        .fetchProducts();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),

                        // --- Search Bar ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: "Search for a product",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              suffixIcon: Icon(Icons.search, color: textDark),
                            ),
                          ),
                        ),
                        kHeight20,

                        // --- Blue Category Filter ---
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Choose a Category",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedCategory.value == "All"
                                        ? "All Category"
                                        : selectedCategory.value,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  PopupMenuButton<String>(
                                    color: Colors.white,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                    ),
                                    onSelected: (value) {
                                      selectedCategory.value = value;
                                    },
                                    itemBuilder: (context) {
                                      return categories.map((category) {
                                        return PopupMenuItem<String>(
                                          value: category,
                                          child: Text(category),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        kHeight20,
                        // --- Loading State ---
                        if (productState.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),

                        // --- Error State ---
                        if (productState.error != null &&
                            !productState.isLoading)
                          Center(
                            child: Text(
                              "Error: ${productState.error}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

                        // --- Product List ---
                        if (!productState.isLoading && filteredProducts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: Text("No products found")),
                          ),

                        ...filteredProducts.map((product) {
                          // Determine if this specific card is in "Modify" mode
                          final isExpanded =
                              expandedProductId.value == product.id;

                          return GestureDetector(
                            onTap: () {
                              // Toggle expansion logic
                              if (isExpanded) {
                                expandedProductId.value = null; // Collapse
                              } else {
                                expandedProductId.value =
                                    product.id; // Expand this one
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
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
                                  // Header: Name + Price
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          style: const TextStyle(
                                            color: textDark,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "SAR ${product.price.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: textDark,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Subtitle: Category
                                  Text(
                                    product.category,
                                    style: const TextStyle(
                                      color: textGrey,
                                      fontSize: 13,
                                    ),
                                  ),

                                  // --- EXPANDED SECTION (Modify / Delete) ---
                                  if (isExpanded) ...[
                                    kHeight20,
                                    Row(
                                      children: [
                                        // Modify Button
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: ElevatedButton(
                                              // onPressed: () {
                                              //   Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder: (_) =>
                                              //           AddProductScreen(
                                              //             productToEdit:
                                              //                 product, // <-- IMPORTANT
                                              //           ),
                                              //     ),
                                              //   );
                                              // },
                                              onPressed: () async {
                                                // 1️⃣ Fetch fresh product from backend
                                                final freshProduct = await ref
                                                    .read(
                                                      productNotifierProvider
                                                          .notifier,
                                                    )
                                                    .fetchProductById(
                                                      product.id!,
                                                    );

                                                // 2️⃣ Open edit screen with REAL stock value
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        AddProductScreen(
                                                          productToEdit:
                                                              freshProduct, //fresh product
                                                        ),
                                                  ),
                                                );
                                              },

                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryBlue,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                "Modify",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Delete Button
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                final shouldDelete =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          backgroundColor:
                                                              Colors.white,
                                                          title: const Text(
                                                            "Delete Product",
                                                          ),
                                                          content: Text(
                                                            "Are you sure you want to delete \"${product.name}\"?",
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                "Cancel",
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                "Delete",
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );

                                                if (shouldDelete == true &&
                                                    product.id != null) {
                                                  await ref
                                                      .read(
                                                        productNotifierProvider
                                                            .notifier,
                                                      )
                                                      .deleteProduct(
                                                        product.id!,
                                                      );

                                                  // 🔥 Immediately refresh UI
                                                  await ref
                                                      .read(
                                                        productNotifierProvider
                                                            .notifier,
                                                      )
                                                      .fetchProducts();

                                                  expandedProductId.value =
                                                      null;
                                                }
                                              },

                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: deleteRed,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        // Bottom Spacer to ensure last item isn't covered by the fixed button
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // -------------------------------------------------------------------
          // FIXED BOTTOM BUTTON
          // -------------------------------------------------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: bgGrey, // Blend with background
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Add a new product",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
