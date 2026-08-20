import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/cart/cart_notifier.dart';
import 'package:shopx/application/customers/customer_notifier.dart';
import 'package:shopx/application/sales/sales_notifier.dart';
import 'package:shopx/application/stock/stock_notifier.dart';
import 'package:shopx/domain/customers/customer.dart';
import 'package:shopx/domain/products/product.dart';
import 'package:shopx/presentation/cart/cart_success_screen.dart'; // Ensure this path matches your project

class CartScreen extends HookConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch Cart State
    final cartState = ref.watch(cartProvider);
    final cartItems = cartState.items;

    final customerState = ref.watch(customerNotifierProvider);
    final customers = customerState.customers; // list from backend

    final selectedCustomer = useState<Customer?>(
      null,
    ); 
    
    //storing selected 
    


// useEffect(() {
//   Future.microtask(() {
//     // 🧾 Cart needs ALL customers
//     ref.read(customerNotifierProvider.notifier).fetchAllCustomers();
//   });
//   return null;
// }, []);

useEffect(() {
  Future.microtask(() {
    final customerState = ref.read(customerNotifierProvider);

    if (customerState.customers.isEmpty) {
      ref.read(customerNotifierProvider.notifier).fetchAllCustomers();
    }
  });
  return null;
}, []);


    // Discount input controller
    final discountController = useTextEditingController();
    final discountAmount = useState<double>(0);

    useEffect(() {
      discountController.text = "0";
      discountController.addListener(() {
        discountAmount.value = double.tryParse(discountController.text) ?? 0.0;
      });
      return null;
    }, []);

    // 2. Text Controllers (Local Hooks)
    final nameCtrl = useTextEditingController();
    final phoneCtrl = useTextEditingController();
    final addressCtrl = useTextEditingController();

    // 3. Payment Method State (Local Hook)
    // Value is 'cash' or 'card'
final paymentMethod = useState<String>("cash");
final paymentStatus = useState<String>("paid"); // 👈 NEW
final hasCustomerError = useState<bool>(false);


    // ================= DISCOUNT + VAT LOGIC =================

    // Subtotal (gross)
    final double subTotal = cartItems.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    // --- LOGIC: Place Order ---
    void handlePlaceOrder() async {
      // 1. Validation
      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cart is empty!")));
        return;
      }

      // if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text("Please fill in Customer Details")),
      //   );
      //   return;
      // }

      if (nameCtrl.text.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Please enter customer name")),
  );
  return;
}


      // 2. Prepare sale items for backend
      final saleItems = cartItems.map((item) {
        return {
          "product_id": item.product.id,
          "quantity": item.quantity,
          "unit_price": item.product.price,
        };
      }).toList();

      final stockMap = ref.read(stockNotifierProvider).stock;

      bool hasBackorder = false;

      for (var item in cartItems) {
        final available = stockMap[item.product.id] ?? 0.0;

        if (available <= 0 || item.quantity > available) {
          hasBackorder = true;
        }
      }

      // 3. Call backend and create sale
      try {
        print("🛒 Creating sale...");

        final saleId = await ref
            .read(salesNotifierProvider.notifier)
            .createSale(
              customerId: selectedCustomer.value?.id ?? 0,
              items: saleItems,
              paymentMethod: paymentMethod.value,
               paymentStatus: paymentStatus.value, // 👈 NEW
              discountAmount: discountAmount.value,
            );

        // OPTIONAL INFO MESSAGE (correct place)
        if (hasBackorder) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Order placed with backordered items"),
              duration: Duration(seconds: 3),
            ),
          );
        }

        // 4. Clear cart
        ref.read(cartProvider.notifier).clearCart();
        print("🟢 SALE CREATED! Sale ID = $saleId");

        // 5. Navigate to success screen (CLEAR STACK – POS SAFE)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(saleId: saleId),
          ),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Order failed: $e")));
      }
    }

    // --- UI HELPERS ---
    const blueColor = Color(0xFF1976D2);
    const bgColor = Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: blueColor,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Cart",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: blueColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // Balance the back button
                ],
              ),
            ),

            // --- Scrollable Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cart Items List
                    if (cartItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("Your cart is currently empty"),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final item = cartItems[index];
                          final product = item.product;
                          final double itemTotal =
                              product.price * item.quantity;

                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Product Image
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[100],
                                    image: product.images.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              "http://localhost:5000${product.images.first}",
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: product.images.isEmpty
                                      ? const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF1F2937),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Qty: ${item.quantity.toInt()} x SAR ${product.price}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "SAR ${itemTotal.toStringAsFixed(2)}", // Item total logic if needed
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Delete Button
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .removeFromCart(product.id ?? "");
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: blueColor.withOpacity(0.2),
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: blueColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // 2. Customer Details Section
                    _buildSectionHeader("Customer Details"),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Autocomplete<Customer>(
                            optionsBuilder: (TextEditingValue textValue) {
                              if (textValue.text.isEmpty)
                                return const Iterable<Customer>.empty();

                              return customers.where(
                                (c) => c.name.toLowerCase().contains(
                                  textValue.text.toLowerCase(),
                                ),
                              );
                            },
                            displayStringForOption: (Customer c) => c.name,

                            // ⭐ ONLY THIS BLOCK ADDED
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  color: Colors.white,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 80, // ⭐ LIMIT HEIGHT
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final Customer c = options.elementAt(
                                          index,
                                        );
                                        return ListTile(
                                          title: Text(c.name),
                                          onTap: () => onSelected(c),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },

                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  // Sync autocomplete value → nameCtrl
                                  controller.addListener(() {
                                    nameCtrl.text = controller.text;
                                  });

                                  return Container(
                                   decoration: BoxDecoration(
  color: const Color(0xFFF3F4F6),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: hasCustomerError.value ? Colors.red : Colors.blue,
    width: 1.5,
  ),
),

                                    child: TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        hintText: "Customer Name",
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      onChanged: (val) {
                                        nameCtrl.text = val;
                                      },
                                    ),
                                  );
                                },
                            onSelected: (Customer selected) {
                              selectedCustomer.value = selected;
                              nameCtrl.text = selected.name;
                              phoneCtrl.text = selected.phone ?? "";
                              addressCtrl.text = selected.address;

                               hasCustomerError.value = false; // ✅ clear red state
                            },
                          ),

                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: phoneCtrl, 

                            hint: "Phone number",
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: addressCtrl,
                            hint: "Address",
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. Payment Method Section
                    _buildSectionHeader("Payment Method"),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Cash Option
                       _buildPaymentOption(
  label: "Cash",
  imageAsset: "assets/images/saudi-arabia-official-riyal-sign.png",
  isSelected: paymentMethod.value == 'cash',
  onTap: () {
    paymentMethod.value = 'cash';
    paymentStatus.value = 'paid'; // 👈 IMPORTANT
  },
  activeColor: blueColor,
),

const SizedBox(height: 12),

_buildPaymentOption(
  label: "Bank / Card",
  icon: Icons.account_balance,
  isSelected: paymentMethod.value == 'card',
  onTap: () {
    paymentMethod.value = 'card';
    paymentStatus.value = 'paid'; // 👈 IMPORTANT
  },
  activeColor: blueColor,
),

const SizedBox(height: 12),

// ✅ NEW: Pending option
_buildPaymentOption(
  label: "Pending",
  icon: Icons.schedule,
  isSelected: paymentStatus.value == 'pending',
  onTap: () {
    paymentMethod.value = 'pending'; // for record
    paymentStatus.value = 'pending'; // 👈 THIS IS THE KEY
  },
  activeColor: Colors.orange,
),

                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. Order Summary Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order summery", // Intentional typo to match design if needed, or fix to 'summary'
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // _buildSummaryRow("Sub total :", subTotal),
                          // _buildSummaryRow("VAT (15%) :", vatAmount),
                          // _buildSummaryRow("Discount :", discount),
                          _buildSummaryRow("Sub total :", subTotal),

                          // DISCOUNT ROW (MATCHES SUMMARY STYLE)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "Discount :",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: discountController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "0.00",
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // VAT is calculated in backend – do NOT calculate here
                          _buildSummaryRow("VAT (15%) :", 0),

                          const Divider(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Total Payable :",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                "Calculated after order",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 5. Place Order Button
      bottomSheet: Container(
        color: bgColor, // Match scaffold background
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
          top: 10,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: handlePlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Place order",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String label,
    IconData? icon,
    String? imageAsset,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(
            0xFFE0E0E0,
          ).withOpacity(0.5), // Grey background from design
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: activeColor, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                shape: BoxShape.circle,
              ),
              // child: Icon(icon, color: Colors.grey[700], size: 20),
              child: imageAsset != null
                  ? Image.asset(imageAsset, height: 18)
                  : Icon(icon, color: Colors.grey[700], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: Colors.grey[800], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "SAR ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
