import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/presentation/dashboard/user/user_dashboard.dart';

class EmployeeLoginScreen extends HookConsumerWidget {
  const EmployeeLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Define Controllers using Hooks
    final employeeIdController = useTextEditingController();
    final passwordController = useTextEditingController();

    final usernameError = useState<String?>(null);
    final passwordError = useState<String?>(null);
    final isPasswordVisible = useState<bool>(false);

    // 2. Define Colors based on design
    const primaryBlue = Color(0xFF1976D2);
    const inputFillColor = Color(0xFFF3F4F6); // Light grey for inputs
    const infoBoxColor = Color(
      0xFFEBF4FF,
    ); // Very light blue for the bottom box
    const textLabelColor = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header (Back Button + Title) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT: Back Button
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/images/backbutton.png",
                      height: 35,
                      width: 35,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // CENTER: Title
                  const Expanded(
                    child: Text(
                      'Log in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // RIGHT: Invisible Box Matching Back Button Size
                  Opacity(
                    opacity: 0,
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              kHeight40,

              // --- Employee ID Input ---
              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textLabelColor,
                ),
              ),
              const SizedBox(height: 8),

              // ORIGINAL INPUT – unchanged
              TextField(
                controller: employeeIdController,
                decoration: InputDecoration(
                  hintText: 'ABC23654',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  filled: true,
                  fillColor: inputFillColor,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // NEW ERROR TEXT (this does not change your design)
              if (usernameError.value != null) ...[
                SizedBox(height: 6),
                Text(
                  usernameError.value!,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              // --- Password Input ---
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textLabelColor,
                ),
              ),
              SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible.value,
                decoration: InputDecoration(
                  hintText: 'Minimum 8 characters',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  filled: true,
                  fillColor: inputFillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      isPasswordVisible.value = !isPasswordVisible.value;
                    },
                  ),
                ),
              ),

              if (passwordError.value != null) ...[
                SizedBox(height: 6),
                Text(
                  passwordError.value!,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              kHeight30,

              // --- Log In Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    usernameError.value = null;
                    passwordError.value = null;

                    if (employeeIdController.text.isEmpty) {
                      usernameError.value = "Username required";
                      return;
                    }

                    if (passwordController.text.isEmpty) {
                      passwordError.value = "Password required";
                      return;
                    }

                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .loginUser(
                            employeeIdController.text.trim(),
                            passwordController.text.trim(),
                          );

                      final auth = ref.read(authNotifierProvider);

                      // Success → go to dashboard
                      if (auth.user != null) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserDashboard(),
                          ),
                          (route) => false, // 🔥 clears entire back stack
                        );

                        return;
                      }

                      // Error handling
                      final message = auth.error?.toLowerCase() ?? "";

                      if (message.contains("wrong password")) {
                        passwordError.value = "Incorrect password";
                      } else if (message.contains("user not found")) {
                        usernameError.value = "Username does not exist";
                      } else {
                        passwordError.value = "Invalid credentials";
                      }
                    } catch (e) {
                      passwordError.value = "Invalid credentials";
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              kHeight30,
              // --- Info Box ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: infoBoxColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Use the employee ID and password that can be created by the owner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF374151), // Dark grey for readability
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
