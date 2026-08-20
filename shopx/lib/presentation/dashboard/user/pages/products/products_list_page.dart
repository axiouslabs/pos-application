import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/products/product_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/widget/productlist/product_card.dart';

class userProductListPage extends HookConsumerWidget {
  const userProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Trigger Fetch on Init
    useEffect(() {
      Future.microtask(() {
        ref.read(productNotifierProvider.notifier).fetchProducts();
      });
      return null;
    }, []);

    // 2. Watch Provider State
    final productState = ref.watch(productNotifierProvider);

    // 3. Local Hooks for Filtering
    final searchQuery = useState('');
    final selectedCategory = useState('All Category');

    // 4. Dynamic Categories
    final categories = [
      'All Category',
      ...productState.products.map((p) => p.category).toSet(),
    ];

    // 5. Filter Logic
    final filteredProducts = useMemoized(() {
      return productState.products.where((product) {
        final matchesCategory =
            selectedCategory.value == 'All Category' ||
            product.category == selectedCategory.value;

        final matchesSearch = product.name.toLowerCase().contains(
          searchQuery.value.toLowerCase(),
        );

        return matchesCategory && matchesSearch;
      }).toList();
    }, [productState.products, searchQuery.value, selectedCategory.value]);

    // 6. Limit to 6 products
    final limitedProducts = filteredProducts.length > 6
        ? filteredProducts.take(6).toList()
        : filteredProducts;

    // --- UI CONSTANTS ---
    const primaryBlue = Color(0xFF1976D2);
    const bgColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: primaryBlue,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Product List",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // Spacer to balance back button
                ],
              ),
            ),

            // ================= CONTENT =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. SEARCH BAR ---
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF2F4F7,
                        ), // light grey Figma style
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (val) => searchQuery.value = val,
                        decoration: const InputDecoration(
                          hintText: "Search for a product",
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF), // lighter grey
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF4B5563), // dark grey
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- 2. CATEGORY DROPDOWN (Blue Pill) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Rounded corners
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
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: const Text(
                              "Choose a category",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory.value,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                              ),
                              dropdownColor: primaryBlue,
                              isExpanded: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),

                              // Build category list dynamically from product data
                              items: categories.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),

                              onChanged: (newValue) {
                                if (newValue != null) {
                                  selectedCategory.value = newValue;
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- 3. DYNAMIC PRODUCT LIST ---

                    // A. LOADING STATE
                    if (productState.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: CircularProgressIndicator(color: primaryBlue),
                        ),
                      )
                    // B. ERROR STATE
                    else if (productState.error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            "Error: ${productState.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    // C. EMPTY STATE
                    else if (filteredProducts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text("No products found"),
                        ),
                      )
                    // D. SUCCESS LIST
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: limitedProducts.length,
                        itemBuilder: (context, index) {
                          final product = limitedProducts[index];
                          return buildProductCard(product);
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                      ),

                    kHeight20,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
