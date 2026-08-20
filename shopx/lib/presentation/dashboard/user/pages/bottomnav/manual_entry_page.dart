import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/cart/cart_notifier.dart';
import 'package:shopx/application/products/product_notifier.dart';
import 'package:shopx/domain/products/product.dart';

class ManualEntryPage extends HookConsumerWidget {
  const ManualEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final qtyController = useTextEditingController();

    
    // Currently selected product from DB
    final selectedProduct = useState<Product?>(null);

     // ---- Load products (if not already loaded) ----
    useEffect(() {
      Future.microtask(() {
        ref.read(productNotifierProvider.notifier).fetchProducts();
      });
      return null;
    }, []);

       final productState = ref.watch(productNotifierProvider);
    final products = productState.products; // adjust field name if needed

    void handleAddToCart() {
      final product = selectedProduct.value;

      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select a product from the list")),
        );
        return;
      }

        final enteredPrice =
          double.tryParse(priceController.text.trim()) ?? product.price;
      final qty = double.tryParse(qtyController.text.trim()) ?? 1;

      if (qty <= 0 || enteredPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter valid price and quantity")),
        );
        return;
      } 
       
         // ✅ Use the existing product, but with possibly overridden price
      final productForCart = Product(
        id: product.id,
        name: product.name,
        nameAr: product.nameAr,
        price: enteredPrice,        // <-- salesman’s custom price
        category: product.category,
        quantity: product.quantity, // stock info, if you use it
        code: product.code,
        vat: product.vat,
        images: product.images,
        
      );

      ref.read(cartProvider.notifier).addToCart(productForCart, qty);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to cart")),
      );

      // Optional: clear only qty & price, keep name
      // priceController.clear();
      // qtyController.text = "1";
    }



 return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // ---------- Product Name (search + select) ----------
                  const Text(
                    "Product Name",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Autocomplete<Product>(
                      optionsBuilder: (TextEditingValue textValue) {
                        if (textValue.text.isEmpty) {
                          return const Iterable<Product>.empty();
                        }
                        return products.where((p) => p.name
                            .toLowerCase()
                            .contains(textValue.text.toLowerCase()));
                      },
                      displayStringForOption: (p) => p.name,
                      fieldViewBuilder:
                          (context, textEditingController, focusNode, onSubmit) {
                        // keep internal controller in sync with our nameController
                        textEditingController.text = nameController.text;
                        textEditingController.selection =
                            nameController.selection;

                        textEditingController.addListener(() {
                          nameController.text = textEditingController.text;
                          nameController.selection =
                              textEditingController.selection;
                        });

                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                            hintText: "Search product...",
                          ),
                        );
                      },
                      optionsViewBuilder:
                          (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final p = options.elementAt(index);
                                  return ListTile(
                                    title: Text(p.name),
                                    subtitle: Text(
                                        "₹${p.price.toStringAsFixed(2)} • ${p.category}"),
                                    onTap: () {
                                      onSelected(p);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (product) {
                        selectedProduct.value = product;
                        nameController.text = product.name;
                        priceController.text =
                            product.price.toStringAsFixed(2); // default price
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------- Product Price ----------
                  _inputField(
                    "Product Price",
                    priceController,
                    keyboard: TextInputType.number,
                  ),

                  // ---------- Quantity ----------
                  _inputField(
                    "Qty",
                    qtyController,
                    keyboard: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Fixed "Add to cart" button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: handleAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Add to cart",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _inputField(
    String title,
    TextEditingController controller, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}