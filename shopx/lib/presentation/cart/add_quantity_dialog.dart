import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/cart/cart_notifier.dart';
import 'package:shopx/application/stock/stock_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/domain/products/product.dart';

class AddQuantityDialog extends HookConsumerWidget {
  final Product product;
  final Function(double quantity) onAddToCart;

  const AddQuantityDialog({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load stock AFTER the dialog finishes building

    // useEffect(() {
    //   if (product.id != null) {
    //     ref.read(stockNotifierProvider.notifier)
    //        .loadStockForProduct(product.id!);
    //   }
    //   return null; // runs only once when dialog opens
    // }, []);

    useEffect(() {
      if (product.id != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(stockNotifierProvider.notifier)
              .loadStockForProduct(product.id!);
        });
      }
      return null;
    }, []);

    // Hooks
    final quantityController = useTextEditingController();

    // We listen to the controller changes to update UI state for validation
    final textValue = useValueListenable(quantityController).text;

    // Logic
    final double enteredQty = double.tryParse(textValue) ?? 0.0;
    final stockState = ref.watch(stockNotifierProvider);

    //     if (stockState.isLoading) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    final availableStock = stockState.stock[product.id] ?? 0.0;
    // final bool isOverStock = enteredQty > availableStock;
    // final bool isValid = enteredQty > 0 && !isOverStock;


    final bool isBackorder =
    availableStock <= 0 || enteredQty > availableStock;

final bool isValid = enteredQty > 0;



    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: Colors.grey,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Select the Qty",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),

            // Product Details
            _buildInfoRow("Product Name", product.name),
            const SizedBox(height: 8),
            _buildInfoRow("Product Code", product.code),
            const SizedBox(height: 8),

            // Available Stock Row (Dynamic)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Available Stock :",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "$availableStock Kg", // always KG now
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: availableStock > 0 ? Colors.green[700] : Colors.orange,
                  ),
                ),
              ],
            ),

            kHeight20,

            // Quantity Input Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  // Allow only numbers and dots
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: TextStyle(
                  color: isBackorder ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  // Error styling
                  enabledBorder: isBackorder
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        )
                      : InputBorder.none,
                  focusedBorder: isBackorder
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        )
                      : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.5,
                          ),
                        ),

                  hintText: "Enter Quantity",
                  // Dynamic Unit Suffix (KG / Nos)
                  suffixText: "Kg",
                  suffixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // Validation Error Message
            if (isBackorder)
  Padding(
    padding: const EdgeInsets.only(top: 8.0, left: 5),
    child: Text(
      availableStock <= 0
          ? "Out of stock. This order will be placed as backorder."
          : "Only $availableStock Kg available. Remaining quantity will be backordered.",
      style: TextStyle(
        color: Colors.orange,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),


            // if (isOverStock)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 8.0, left: 5),
            //     child: Text(
            //       "Quantity cannot exceed available stock!",
            //       style: TextStyle(color: Colors.red[700], fontSize: 12),
            //     ),
            //   ),

            const SizedBox(height: 25),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
              onPressed: isValid
    ? () {
        ref
            .read(cartProvider.notifier)
            .addToCart(product, enteredQty);

        Navigator.of(context).pop();

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //       isBackorder
        //           ? "Added to cart as backorder"
        //           : "Added to cart",
        //     ),
        //     duration: const Duration(seconds: 2),
        //   ),
        // );
      }
    : null,


                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Add to cart",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to display Label : Value
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            "$label :",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
