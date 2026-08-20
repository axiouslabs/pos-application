import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopx/application/products/product_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/domain/products/product.dart';

class AddProductScreen extends HookConsumerWidget {
  final Product? productToEdit;
  const AddProductScreen({super.key, this.productToEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hooks for TextFields
    final nameController = useTextEditingController(
      text: productToEdit?.name ?? "",
    );

    final nameArController = useTextEditingController(
  text: productToEdit?.nameAr ?? "",
);

    final priceController = useTextEditingController(
      text: productToEdit != null ? productToEdit!.price.toString() : "",
    );

    final categoryController = useTextEditingController(
      text: productToEdit?.category ?? "",
    );

    final codeController = useTextEditingController(
      text: productToEdit?.code ?? "",
    );

    final quantityController = useTextEditingController(
      text: "",
      //  productToEdit != null ? productToEdit!.quantity.toString() : "",
    );

    final vatController = useTextEditingController(
      text: productToEdit != null ? productToEdit!.vat.toString() : "",
    );

    final selectedUnit = useState("Kg"); // default

    // Color Constants extracted from the image
    const Color primaryBlue = Color(0xFF1E75D5); // The AppBar and Button blue
    const Color darkBlueButton = Color(
      0xFF2B3A55,
    ); // The "Choose a photo" button
    const Color inputFillColor = Color(
      0xFFF3F4F6,
    ); // Light grey background for inputs
    const Color labelColor = Color(0xFF333333); // Dark text color
    const Color removeRed = Color(0xFFE53935);

    // OLD SERVER IMAGES (URLs)
    final existingImageUrls = useState<List<String>>(
      productToEdit?.images ?? [],
    );

    // NEWLY PICKED IMAGES (bytes)
    final pickedImages = useState<List<Uint8List>>([]);

    Future<void> pickFileOrImage() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: true,
        withData: true, // VERY IMPORTANT FOR WEB
      );

      if (result != null) {
        pickedImages.value = [
          ...pickedImages.value, //keep old image
          ...result.files
              .where((file) => file.bytes != null)
              .map((file) => file.bytes!),
        ];

        print("Picked ${pickedImages.value.length} images");
      }
    }

    useEffect(() {
      if (productToEdit != null) {
        nameController.text = productToEdit!.name;
        priceController.text = productToEdit!.price.toString();
        categoryController.text = productToEdit!.category;
        codeController.text = productToEdit!.code;
        quantityController.text = productToEdit!.quantity.toString();
        vatController.text = productToEdit!.vat.toString();
      }
      return null;
    }, [productToEdit]);

    void cancelAddProduct() {
      if (productToEdit == null) {
        // Reset only in add mode
        nameController.clear();
        nameArController.clear(); // ✅ FIX
        priceController.clear();
        categoryController.clear();
        codeController.clear();
        quantityController.clear();
        selectedUnit.value = "Kg";
        pickedImages.value = [];
      }

      Navigator.pop(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              // LEFT BACK BUTTON
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Color(0xFF1E75D5),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // TITLE (CENTERED)
              Expanded(
                child: Center(
                  child: Text(
                    productToEdit == null ? 'Add a product' : 'Edit product',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // RIGHT SIDE DUMMY BUTTON (invisible but same size as back button)
              Opacity(
                opacity: 0, // fully invisible
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.transparent,
                    ),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section: Product Details ---
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
            kHeight16,

            // Field: Product Name
            _buildLabel('Product Name'),
            _buildTextField(
              controller: nameController,
              hintText: 'Enter product name',
              fillColor: inputFillColor,
            ),
            kHeight16,

          _buildLabel('Product Name (Arabic)'),
_buildTextField(
  controller: nameArController,
  hintText: 'Enter product name in Arabic',
  fillColor: inputFillColor,
),
kHeight16,



            // Field: Selling Price
            _buildLabel('Selling price'),
            _buildTextField(
              controller: priceController,
              hintText: 'Enter selling price',
              fillColor: inputFillColor,
            ),
            kHeight16,

            // Field: VAT (%)
            _buildLabel('VAT (%)'),
            _buildTextField(
              controller: vatController,
              hintText: 'Enter VAT percentage',
              fillColor: inputFillColor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d*$'),
                ), // only numbers and dot
              ],
            ),
            kHeight16,

            // Field: Categories
            _buildLabel('Categories'),
            _buildTextField(
              controller: categoryController,
              hintText: 'Choose a category',
              fillColor: inputFillColor,
              // In a real app, you might want readOnly: true and onTap to show a modal
            ),
            kHeight16,

            // Field: Quantity (always in KG)
            _buildLabel('Adjust Stock (in Kg)'),
            const SizedBox(height: 6),

            if (productToEdit != null) ...[
              Text(
                'Current Stock: ${productToEdit!.quantity} Kg',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],

            const Text(
              'Enter how much stock to ADD or REMOVE.\n'
              'Use + to add, - to remove.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            _buildTextField(
              controller: quantityController,
              hintText: 'Enter quantity in Kg',
              fillColor: inputFillColor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
            ),

            kHeight16,

            // Field: Code
            _buildLabel('Code'),
            _buildTextField(
              controller: codeController,
              hintText: 'Enter product code',
              fillColor: inputFillColor,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.asset(
                  "assets/images/bar-code.png",
                  height: 20,
                  width: 20,
                  color: Colors.black,
                ),
              ),
            ),
            kHeight24,
            // --- Section: More Details ---
            const Text(
              'More details (optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
            kHeight12,

            // Image Picker Widget
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // ---------- PLACEHOLDER ----------
                  if (existingImageUrls.value.isEmpty &&
                      pickedImages.value.isEmpty)
                    Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: inputFillColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade700,
                          size: 30,
                        ),
                      ),
                    )
                  else
                    // ---------- IMAGE LIST VIEW ----------
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // ========= OLD IMAGES (URLs) =========
                          ...existingImageUrls.value.map(
                            (url) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    "http://localhost:5000" + url,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      final updated = List<String>.from(
                                        existingImageUrls.value,
                                      );
                                      updated.remove(url);
                                      existingImageUrls.value = updated;
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // ========= NEW IMAGES (MEMORY) =========
                          ...pickedImages.value.map(
                            (bytes) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    bytes,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      final updated = List<Uint8List>.from(
                                        pickedImages.value,
                                      );
                                      updated.remove(bytes);
                                      pickedImages.value = updated;
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 10),

                  // ---------- PICK IMAGE BUTTON ----------
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: pickFileOrImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlueButton,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Choose a photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            kHeight40,

            // --- Footer Buttons ---

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final images = pickedImages.value;

                  final product = Product(
                    id: productToEdit?.id, // keep old ID in edit mode
                    name: nameController.text,
                     nameAr: nameArController.text, // ✅ NEW
                    price: double.parse(priceController.text),
                    category: categoryController.text,
                    code: codeController.text,
                    quantity: double.parse(quantityController.text),
                    vat: double.tryParse(vatController.text.trim()) ?? 0.0,
                  );

                  if (productToEdit == null) {
                    // CREATE NEW PRODUCT
                    await ref
                        .read(productNotifierProvider.notifier)
                        .createProduct(product, images);
                  } else {
                    // UPDATE EXISTING PRODUCT

                    // 1️⃣ Parse adjustment value
                    final adjustment =
                        double.tryParse(quantityController.text.trim()) ?? 0.0;

                    // 2️⃣ Update product metadata ONLY (no stock change here)
                    final updatedProduct = Product(
                      id: productToEdit!.id,
                      name: nameController.text,
                        nameAr: nameArController.text, // ✅ NEW
                      price: double.parse(priceController.text),
                      category: categoryController.text,
                      code: codeController.text,
                      quantity: productToEdit!.quantity, // KEEP existing stock
                      vat: double.tryParse(vatController.text.trim()) ?? 0.0,
                    );

                    await ref
                        .read(productNotifierProvider.notifier)
                        .updateProduct(
                          productToEdit!.id!,
                          updatedProduct,
                          existingUrls: existingImageUrls.value,
                          newImages: pickedImages.value,
                        );

                    // 3️⃣ Adjust stock ONLY if admin entered something
                    if (adjustment != 0) {
                      await ref
                          .read(productNotifierProvider.notifier)
                          .adjustStock(
                            productId: productToEdit!.id!,
                            quantityChange: adjustment,
                          );
                    }

                    quantityController.clear();
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  productToEdit == null
                      ? 'Add a new product'
                      : 'Update product',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            kHeight20,
            // Remove Button
            Center(
              child: TextButton.icon(
                onPressed: cancelAddProduct,
                style: TextButton.styleFrom(foregroundColor: removeRed),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text(
                  'Remove product',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            kHeight20,
          ],
        ),
      ),
    );
  }

  // Helper widget for Labels
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4A4A4A),
        ),
      ),
    );
  }

  // Helper widget for TextFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Color fillColor,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF1E75D5), width: 1),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          maxHeight: 24,
          maxWidth: 40,
        ),
      ),
    );
  }
}
