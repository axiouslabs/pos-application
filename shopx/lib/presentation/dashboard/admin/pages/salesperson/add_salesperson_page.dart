import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/salesman/salesman_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/domain/salesman/salesman.dart';

class AddSalespersonPage extends HookConsumerWidget {
  final Salesman? salesman; // null = Add Mode, !null = Edit Mode

  const AddSalespersonPage({super.key, this.salesman});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -------------------------------------------------------------------------
    // 1. FORM CONTROLLERS (Hooks)
    // -------------------------------------------------------------------------
    final nameController = useTextEditingController(
      text: salesman?.username ?? "",
    );
    final emailController = useTextEditingController(
      text: salesman?.email ?? "",
    );
    final phoneController = useTextEditingController(
      text: salesman?.phone ?? "",
    );

    // Password is empty by default. Required for Add, Optional for Edit.
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    final emailError = useState<String?>(null);
    final phoneError = useState<String?>(null);
    final passwordError = useState<String?>(null);
    final confirmError = useState<String?>(null);

    // -------------------------------------------------------------------------
    // 2. STATE & CONSTANTS
    // -------------------------------------------------------------------------
    final isEditMode = salesman != null;
    const primaryBlue = Color(0xFF1E75D5);
    const deleteRed = Color(0xFFEF3838);
    const bgGrey = Color(0xFFF8F9FB);
    const inputFill = Color(0xFFF0F1F3);
    const textLabel = Color(0xFF2B2B2B);

    // -------------------------------------------------------------------------
    // 3. LOGIC HANDLERS
    // -------------------------------------------------------------------------

    void handleSubmit() {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final password = passwordController.text;
      final confirm = confirmPasswordController.text;

      bool hasError = false;

      // ---------------- EMAIL VALIDATION ----------------
      if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email)) {
        emailError.value = "Invalid email format";
        hasError = true;
      } else {
        emailError.value = null;
      }

      // ---------------- PHONE VALIDATION ----------------
      if (phone.length != 10 || !RegExp(r"^[0-9]+$").hasMatch(phone)) {
        phoneError.value = "Phone must be exactly 10 digits";
        hasError = true;
      } else {
        phoneError.value = null;
      }

      // ---------------- PASSWORD REQUIRED IN ADD MODE ----------------
      if (!isEditMode && password.isEmpty) {
        passwordError.value = "Password is required";
        hasError = true;
      } else {
        passwordError.value = null;
      }

      // ---------------- PASSWORD MATCH ----------------
      if (password.isNotEmpty && password != confirm) {
        confirmError.value = "Passwords do not match";
        hasError = true;
      } else {
        confirmError.value = null;
      }

      // Stop if form invalid
      if (hasError) return;

      // ---------------- CREATE DATA OBJECT ----------------
      final newSalesmanData = Salesman(
        id: salesman?.id,
        username: name,
        email: email,
        phone: phone,
        password: password.isEmpty ? null : password,
      );

      // ---------------- SUBMIT ----------------
      if (isEditMode) {
        ref
            .read(salesmanNotifierProvider.notifier)
            .updateSalesman(salesman!.id!, newSalesmanData);
      } else {
        ref
            .read(salesmanNotifierProvider.notifier)
            .createSalesman(newSalesmanData);
      }

      Navigator.pop(context);
    }

    void handleDelete() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Remove Salesman"),
          content: Text(
            "Are you sure you want to remove ${salesman!.username}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                ref
                    .read(salesmanNotifierProvider.notifier)
                    .deleteSalesman(salesman!.id!);
                Navigator.pop(context); // Close page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Salesman removed.")),
                );
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 4. UI BUILD
    // -------------------------------------------------------------------------
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? "Edit Salesman" : "Add a Salesman",
          style: const TextStyle(
            color: primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            const Text(
              "Salesman Details",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF223263),
              ),
            ),
            const SizedBox(height: 20),

            // Form Fields
            _buildLabel("Salesman Name"),
            _buildTextField(nameController, "Name"),

            const SizedBox(height: 16),
            _buildLabel("Email"),
            _buildTextField(
              emailController,
              "Email",
              keyboardType: TextInputType.emailAddress,
              errorMessage: emailError.value,
            ),

            const SizedBox(height: 16),
            _buildLabel("Phone"),
            _buildTextField(
              phoneController,
              "Phone",
              isPhone: true,
              keyboardType: TextInputType.phone,
              errorMessage: phoneError.value,
            ),

            const SizedBox(height: 16),
            _buildLabel("Password"),
            _buildTextField(
              passwordController,
              isEditMode ? "Leave empty to keep current" : "Password",
              isPassword: true,
              errorMessage: passwordError.value,
            ),

            const SizedBox(height: 16),
            _buildLabel("Confirm Password"),
            _buildTextField(
              confirmPasswordController,
              "Confirm Password",
              isPassword: true,
              errorMessage: confirmError.value,
            ),

            kHeight40,

            // Primary Action Button (Add/Update)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isEditMode ? "Update Salesman" : "Add Salesman",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Delete Button (Only in Edit Mode)
            if (isEditMode) ...[
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: handleDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: deleteRed,
                    size: 20,
                  ),
                  label: const Text(
                    "Remove Salesman",
                    style: TextStyle(
                      color: deleteRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF223263),
        ),
      ),
    );
  }
Widget _buildTextField(
  TextEditingController controller,
  String hint, {
  bool isPassword = false,
  bool isPhone = false, // ⭐ ADD THIS
  TextInputType keyboardType = TextInputType.text,
  String? errorMessage,
})
 {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F1F3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorMessage != null ? Colors.red : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: 
          
       TextField(
  controller: controller,
  obscureText: isPassword,
  keyboardType: keyboardType,
  inputFormatters: isPhone
      ? [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ]
      : null, // ⭐ KEY FIX
  style: const TextStyle(fontSize: 14, color: Colors.black87),
  decoration: InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  ),
)

        ),

        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
