import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/customers/customer_notifier.dart';
import 'package:shopx/application/salesman/salesman_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/domain/customers/customer.dart';
import 'package:shopx/domain/salesman/salesman.dart';

class AdminCustomerPage extends HookConsumerWidget {
  final Customer? customer; // If null = Add mode. If not = Edit mode.

  const AdminCustomerPage({super.key, this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = customer != null;

    // FORM KEY
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final customerState = ref.watch(customerNotifierProvider);

    // -----------------------------
    // CONTROLLERS (correct place!)
    // -----------------------------
    final nameController = useTextEditingController(text: customer?.name ?? "");
    final phoneController = useTextEditingController(
      text: customer?.phone ?? "",
    );
    final tinController = useTextEditingController(text: customer?.tin ?? "");
    final addressController = useTextEditingController(
      text: customer?.address ?? "",
    );
    final areaController = useTextEditingController(text: customer?.area ?? "");

    // -----------------------------
    // STATES FOR BUTTON ACTIVATION
    // -----------------------------
    final name = useState(customer?.name ?? "");
    final phone = useState(customer?.phone ?? "");
    final tin = useState(customer?.tin ?? "");
    final address = useState(customer?.address ?? "");
    final area = useState(customer?.area ?? "");

    //new
    final selectedSalesperson = useState<Salesman?>(null);
    final salesmenState = ref.watch(salesmanNotifierProvider);
final salesmen = salesmenState.salesmen;



    // -----------------------------
    // LISTENERS (correct placement!)
    // -----------------------------
    useEffect(() {
      nameController.addListener(() => name.value = nameController.text);
      phoneController.addListener(() => phone.value = phoneController.text);
      tinController.addListener(() => tin.value = tinController.text);
      addressController.addListener(
        () => address.value = addressController.text,
      );
      areaController.addListener(() => area.value = areaController.text);
      return null;
    }, []);

    // BUTTON ENABLED?
    bool isValidPhone(String phone) => RegExp(r'^[0-9]{10}$').hasMatch(phone);

    bool isValidTin(String tin) => tin.length >= 6;
    final isButtonEnabled =
        name.value.trim().isNotEmpty &&
        address.value.trim().isNotEmpty &&
         selectedSalesperson.value != null &&
        (phone.value.trim().isEmpty || isValidPhone(phone.value.trim())) &&
        (tin.value.trim().isEmpty || isValidTin(tin.value.trim()));

    // -----------------------------
    // LISTENER FOR SUCCESS/ERROR
    // -----------------------------
    ref.listen(customerNotifierProvider, (previous, next) {
      if (next.success == true && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? "Customer updated!" : "Customer added!"),
          ),
        );
        Navigator.pop(context);
      }

      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${next.error}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // -----------------------------
    // SAVE CUSTOMER FUNCTION
    // -----------------------------
    void saveCustomer() async {
      if (!formKey.currentState!.validate()) return;

      final updatedCustomer = Customer(
        id: isEditMode ? customer!.id : 0,
        name: nameController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        tin: tinController.text.trim().isEmpty
            ? null
            : tinController.text.trim(),
        address: addressController.text.trim(),
        area: areaController.text.trim().isEmpty
            ? null
            : areaController.text.trim(),
             salespersonId: selectedSalesperson.value!.id,
        createdAt: isEditMode ? customer!.createdAt : DateTime.now(),
      );

      if (isEditMode) {
        await ref
            .read(customerNotifierProvider.notifier)
            .updateCustomer(customer!.id, updatedCustomer);
      } else {
        await ref
            .read(customerNotifierProvider.notifier)
            .createCustomer(updatedCustomer);
      }
    }

    // -----------------------------
    // UI STARTS HERE
    // -----------------------------
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditMode ? "Edit Customer" : "Add Customer",
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Name"),
                      _buildTextField(
                        nameController,
                        "Example: John Doe",
                        required: true,
                      ),

                      const SizedBox(height: 20),

                      _buildLabel("Phone"),
                      _buildTextField(
                        phoneController,
                       "Example: 9876543210 (Optional)",
                        required: false,
                        isPhone: true,
                      ),

                      const SizedBox(height: 20),

                      _buildLabel("Tin"),
                      _buildTextField(tinController,"Example: TIN12345 (Optional)",),

                      const SizedBox(height: 20),

                      _buildLabel("Address"),
                      _buildTextField(
                        addressController,
                        "Example: Bannerghatta Road",
                        required: true,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 20),

                      _buildLabel("Area"),
                      _buildTextField(
                        areaController,
                        "Example: Downtown / Zone A",
                      ),

                      const SizedBox(height: 20),

_buildLabel("Salesperson"),

Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    color: const Color(0xFFF2F2F2),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Autocomplete<Salesman>(
    displayStringForOption: (s) => s.username,
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return salesmen;
      }
      return salesmen.where(
        (s) => s.username
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()),
      );
    },
    onSelected: (Salesman selection) {
      selectedSalesperson.value = selection;
    },
    fieldViewBuilder: (
      context,
      controller,
      focusNode,
      onFieldSubmitted,
    ) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          hintText: "Search salesperson",
          border: InputBorder.none,
        ),
      );
    },
  ),
),


                    ],
                  ),
                ),
              ),
            ),

            // -----------------------------
            //  SAVE BUTTON
            // -----------------------------
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled
                        ? const Color(0xFF1976D2)
                        : const Color(0xFFD1E4FA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (!isButtonEnabled || customerState.isLoading)
                      ? null
                      : saveCustomer,
                  child: customerState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          isEditMode ? "Save changes" : "Save customer",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  // -----------------------------
  // REUSABLE WIDGETS
  // -----------------------------
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool required = false,
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,

        validator: (value) {
          final text = value?.trim() ?? "";

          if (required && text.isEmpty) {
            return "This field is required";
          }
          if (isPhone && text.isNotEmpty) {
            if (!RegExp(r'^[0-9]{10}$').hasMatch(text)) {
              return "Phone number must be exactly 10 digits";
            }
          }

          if (hint.toLowerCase().contains("tin") && text.isNotEmpty) {
            if (text.length < 6) {
              return "TIN must be at least 6 characters";
            }
          }

          return null;
        },

        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
