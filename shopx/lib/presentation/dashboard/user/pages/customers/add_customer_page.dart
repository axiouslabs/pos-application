import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/customers/customer_notifier.dart';
import 'package:shopx/domain/customers/customer.dart';
import 'package:shopx/widget/customers/build_input_group.dart';

class AddCustomerPage extends HookConsumerWidget {
  const AddCustomerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Controllers
    final nameController = useTextEditingController();
    final phoneController = useTextEditingController();
    final tinController = useTextEditingController();
    final addressController = useTextEditingController();
    final areaController = useTextEditingController(); // ✅ NEW

    final nameError = useState<String?>(null);
    final phoneError = useState<String?>(null);
    final tinError = useState<String?>(null);
    final addressError = useState<String?>(null);
    final areaError = useState<String?>(null); // optional, for consistency

    // 2. Form Validity State
    final isFormValid = useState(false);

    bool isValidPhone(String phone) {
      final phoneRegex = RegExp(r'^[0-9]{10}$'); // exactly 10 digits
      return phoneRegex.hasMatch(phone);
    }

    bool isValidTin(String tin) {
      return tin.length >= 6; // you can adjust rule
    }

    // 3. Validation Logic
    void validateForm() {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();
      final tin = tinController.text.trim();
      final address = addressController.text.trim();

      // NAME (required)
      nameError.value = name.isEmpty ? "Name is required" : null;

      // PHONE (optional)
      phoneError.value = phone.isNotEmpty && !isValidPhone(phone)
          ? "Phone must be exactly 10 digits"
          : null;

      // TIN (optional)
      tinError.value = tin.isNotEmpty && !isValidTin(tin)
          ? "Minimum 6 characters required"
          : null;

      // ADDRESS (keep required – business choice)
      addressError.value = address.isEmpty ? "Address is required" : null;

      // AREA (optional → no validation error)
      areaError.value = null;

      isFormValid.value =
          nameError.value == null &&
          phoneError.value == null &&
          tinError.value == null &&
          addressError.value == null;
    }

    // 4. Watch for Loading/Success
    final customerState = ref.watch(customerNotifierProvider);

    // Listen for Success to Pop
    ref.listen(customerNotifierProvider, (previous, next) {
      // SUCCESS MESSAGE
      if (next.success && previous?.success != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Customer added successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context); // Return to customer list
      }

      // ERROR MESSAGE
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    // UI Constants
    const primaryBlue = Color(0xFF1976D2);
    const bgColor = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
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
                      "Adding a customer",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- FORM FIELDS ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    buildInputGroup(
                      "Name",
                      nameController,
                      validateForm,
                      errorText: nameError.value,
                    ),

                    buildInputGroup(
                      "Phone (Optional)",
                      phoneController,
                      validateForm,
                      isPhone: true,
                      errorText: phoneError.value,
                    ),

                    buildInputGroup(
                     "TIN / Tax ID (Optional)",
                      tinController,
                      validateForm,
                      errorText: tinError.value,
                    ),
                    buildInputGroup(
                      "Address",
                      addressController,
                      validateForm,
                      maxLines: 3,
                      errorText: addressError.value,
                    ),

                    buildInputGroup(
                      "Area",
                      areaController,
                      validateForm,
                      errorText: areaError.value,
                    ),
                  ],
                ),
              ),
            ),

            // --- SAVE BUTTON ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (isFormValid.value && !customerState.isLoading)
                      ? () async {
                          // Create Customer Object
                          final newCustomer = Customer(
                            id: 0,
                            name: nameController.text,
                            phone: phoneController.text.isEmpty
                                ? null
                                : phoneController.text,
                            tin: tinController.text.isEmpty
                                ? null
                                : tinController.text,
                            address: addressController.text,
                            area: areaController.text.isEmpty
                                ? null
                                : areaController.text, // ✅ NEW
                            createdAt: DateTime.now(),
                          );

                          // Call Provider
                          await ref
                              .read(customerNotifierProvider.notifier)
                              .createCustomer(newCustomer);
                        }
                      : null, // Disabled if form invalid
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: const Color(
                      0xFFD1D5DB,
                    ), // Grey when disabled
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners like design
                    ),
                    elevation: 0,
                  ),
                  child: customerState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "To safeguard", // Matches design text
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
