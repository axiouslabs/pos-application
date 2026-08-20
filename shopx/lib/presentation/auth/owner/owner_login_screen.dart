import 'dart:async';
import 'dart:io';
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/application/auth/auth_state.dart';
import 'package:shopx/core/constants.dart';
// Keep your existing imports
import 'package:shopx/presentation/auth/owner/widgets/otp_selection_button.dart';
import 'package:shopx/presentation/auth/owner/forgot_password_screen.dart';
import 'package:shopx/presentation/dashboard/admin/admin_dashboard.dart';

class OwnerLoginScreen extends HookConsumerWidget {
  const OwnerLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Controllers
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    // OTP Controllers (One for each digit)
    final otp1Controller = useTextEditingController();
    final otp2Controller = useTextEditingController();
    final otp3Controller = useTextEditingController();
    final otp4Controller = useTextEditingController();

    // Focus Nodes for OTP auto-focus
    final focus1 = useFocusNode();
    final focus2 = useFocusNode();
    final focus3 = useFocusNode();
    final focus4 = useFocusNode();

    // 2. State
    final selectedOtpMethod = useState<String?>(null);
    // Controls whether we are in "Form" mode or "OTP" mode
    final isOtpSent = useState<bool>(false);
    final secondsLeft = useState(300); // 5 minutes
    final isTimerRunning = useState(false);
    final otpTimer = useRef<Timer?>(null);
    final isPasswordVisible = useState<bool>(false);

    useEffect(() {
      return () {
        otpTimer.value?.cancel(); // NEW CLEANUP
      };
    }, []);

    // 🎯 ADD THIS ONE LINE ONLY
    final authState = ref.watch(authNotifierProvider);

    final usernameError = useState<bool>(false);
    final passwordError = useState<bool>(false);

    // // ⭐ FIX: If login failed, force-reset UI
    // if (authState.error != null) {
    //   otpTimer.value?.cancel();
    //   isTimerRunning.value = false;
    //   isOtpSent.value = false;
    // }

    Future<bool> hasRealInternet() async {
      try {
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }

    // 3. Theme Colors
    const primaryBlue = Color(0xFF1976D2);
    const inputFillColor = Color(0xFFF3F4F6);
    const textLabelColor = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 40, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER (Back Button & Title) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (isOtpSent.value) {
                        otpTimer.value?.cancel(); // ⭐ STOP TIMER
                        isTimerRunning.value = false; // ⭐ RESET
                        secondsLeft.value = 300; // ⭐ RESET
                        isOtpSent.value = false; // ⭐ HIDE OTP UI
                      } else {
                        Navigator.of(context).pop();
                      }
                    },

                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/images/backbutton.png",
                      height: 35,
                      width: 35,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) =>
                          const Icon(Icons.arrow_back_ios),
                    ),
                  ),
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
                  const SizedBox(width: 35), // Balance the header
                ],
              ),

              const SizedBox(height: 55),

              // --- TOP SECTION: BLURRED WHEN OTP IS SENT ---
              // AbsorbPointer prevents clicking when blurred
              AbsorbPointer(
                absorbing: isOtpSent.value,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: isOtpSent.value
                        ? 2.0
                        : 0.0, // Horizontal blur amount
                    sigmaY: isOtpSent.value ? 2.0 : 0.0, // Vertical blur amount
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Input
                      const Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textLabelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
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
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Password Input
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textLabelColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible.value,
                        decoration: InputDecoration(
                          hintText: 'Minimum 8 characters',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
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
                              isPasswordVisible.value =
                                  !isPasswordVisible.value;
                            },
                          ),
                        ),
                      ),

                      kHeight30,

                      // Send OTP Selection
                      const Text(
                        'send an OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OtpSelectionButton(
                                  label: 'Email',
                                  icon: Icons.email,
                                  isSelected:
                                      selectedOtpMethod.value == 'Email',
                                  onTap: () {
                                    // ❗ Block click when username or password is empty
                                    if (emailController.text.isEmpty ||
                                        passwordController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please enter username and password first",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    // Otherwise allow selection
                                    selectedOtpMethod.value = 'Email';
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OtpSelectionButton(
                                  label: 'WhatsApp',
                                  // Handling missing asset locally for safety
                                  icon: Image.asset(
                                    "assets/images/WhatsApp.png",
                                    errorBuilder: (c, o, s) =>
                                        const Icon(Icons.chat),
                                  ),
                                  isSelected:
                                      selectedOtpMethod.value == 'WhatsApp',

                                  onTap: () {
                                    if (emailController.text.isEmpty ||
                                        passwordController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please enter username and password first",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Select WhatsApp method
                                    selectedOtpMethod.value = "WhatsApp";
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OtpSelectionButton(
                                  label: 'SMS',
                                  icon: Icons.sms,
                                  isSelected: selectedOtpMethod.value == 'SMS',

                                  onTap: () {
                                    // Block click when username or password is empty
                                    if (emailController.text.isEmpty ||
                                        passwordController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please enter username and password first",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Allow selection
                                    selectedOtpMethod.value = "SMS";

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "SMS OTP is not available yet",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OtpSelectionButton(
                                  label: 'Missed call',
                                  icon: Icons.phone_missed,
                                  isSelected:
                                      selectedOtpMethod.value == 'Missed call',

                                  onTap: () {
                                    // Block click when username or password is empty
                                    if (emailController.text.isEmpty ||
                                        passwordController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please enter username and password first",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Allow selection
                                    selectedOtpMethod.value = "Missed call";

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Missed call verification coming soon",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- ENTER OTP SECTION (Only Visible if isOtpSent == true) ---
              if (isOtpSent.value) ...[
                const Text(
                  'Enter OTP:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textLabelColor,
                  ),
                ),
                const SizedBox(height: 16),

                // OTP Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOtpDigitBox(context, otp1Controller, focus1, focus2),
                    _buildOtpDigitBox(context, otp2Controller, focus2, focus3),
                    _buildOtpDigitBox(context, otp3Controller, focus3, focus4),
                    _buildOtpDigitBox(context, otp4Controller, focus4, null),
                  ],
                ),

                kHeight20,

                // Resend OTP Link
                // --- RESEND OTP SECTION (Only visible after OTP is sent) ---
                Center(
                  child: isTimerRunning.value
                      ? Text(
                          "Resend OTP in ${_formatTime(secondsLeft.value)}",
                          style: const TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : InkWell(
                          onTap: () async {
                            // Send OTP again
                            await ref
                                .read(authNotifierProvider.notifier)
                                .sendOTP(
                                  selectedOtpMethod.value!.toLowerCase(),
                                );

                            // Restart 5-minute timer
                            secondsLeft.value = 300;
                            isTimerRunning.value = true;
                            otpTimer.value = Timer.periodic(
                              const Duration(seconds: 1),
                              (timer) {
                                if (secondsLeft.value == 0) {
                                  timer.cancel();
                                  isTimerRunning.value = false;
                                } else {
                                  secondsLeft.value--;
                                }
                              },
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("OTP Resent!")),
                            );
                          },
                          child: const Text(
                            "Resend OTP",
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: primaryBlue,
                            ),
                          ),
                        ),
                ),
                kHeight20,
              ] else ...[
                // Extra spacing when OTP is not visible to match layout
                const SizedBox(height: 60),
              ],

              // --- ACTION BUTTON (GET OTP / LOG IN) ---
              // --- ACTION BUTTON (GET OTP / LOG IN) ---
              // --- ACTION BUTTON (GET OTP / LOG IN) ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // =========================
                    // CHECK INTERNET FIRST (FOR BOTH STATES)
                    //       // =========================
                    //      final hasInternet = await hasRealInternet();
                    // if (!hasInternet) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text(
                    //         "No internet connection. Please switch on mobile data or Wi-Fi.",
                    //       ),
                    //     ),
                    //   );
                    //   return; // ❌ STOP HERE — OTP WILL NOT APPEAR
                    // }this is ansil comenting because need to use later

                    // =========================
                    // STATE 1: GET OTP
                    // =========================
                    if (!isOtpSent.value) {
                      // ✅ VALIDATE INPUTS
                      if (emailController.text.isEmpty ||
                          passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter email and password"),
                          ),
                        );
                        return;
                      }

                      if (selectedOtpMethod.value == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select an OTP method"),
                          ),
                        );
                        return;
                      }

                      // ⭐ SHOW LOADING
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      //   try {
                      //     // 🔐 LOGIN
                      //     await ref
                      //         .read(authNotifierProvider.notifier)
                      //         .loginOwner(
                      //           emailController.text.trim(),
                      //           passwordController.text.trim(),
                      //         );

                      //     // 📩 SEND OTP
                      //     await ref
                      //         .read(authNotifierProvider.notifier)
                      //         .sendOTP(selectedOtpMethod.value!.toLowerCase());

                      //     // ⭐ CLOSE LOADING
                      //     if (context.mounted) Navigator.of(context).pop();

                      //     // ✅ CHANGE UI ONLY AFTER SUCCESS
                      //     isOtpSent.value = true;

                      //     secondsLeft.value = 300;
                      //     isTimerRunning.value = true;

                      //     otpTimer.value = Timer.periodic(
                      //       const Duration(seconds: 1),
                      //       (timer) {
                      //         if (secondsLeft.value == 0) {
                      //           timer.cancel();
                      //           isTimerRunning.value = false;
                      //         } else {
                      //           secondsLeft.value--;
                      //         }
                      //       },
                      //     );

                      //     final method = selectedOtpMethod.value!.toLowerCase();

                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       SnackBar(
                      //         content: Text(
                      //           method == "whatsapp"
                      //               ? "OTP sent to your WhatsApp"
                      //               : "OTP sent to your email",
                      //         ),
                      //       ),
                      //     );
                      //   } catch (e) {
                      //     // ⭐ CLOSE LOADING IF OPEN
                      //     if (context.mounted) {
                      //       Navigator.of(context, rootNavigator: true).pop();
                      //     }

                      //     // 🔁 RESET STATE
                      //     otpTimer.value?.cancel();
                      //     isTimerRunning.value = false;
                      //     isOtpSent.value = false;

                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(
                      //         content: Text(
                      //           "Something went wrong. Please check your internet connection.",
                      //         ),
                      //       ),
                      //     );
                      //   }
                      // }

                      try {
                        // 🔐 STEP 1: LOGIN OWNER (MUST SUCCEED)
                        await ref
                            .read(authNotifierProvider.notifier)
                            .loginOwner(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );

                        // 📩 STEP 2: SEND OTP (ONLY AFTER LOGIN SUCCESS)
                        await ref
                            .read(authNotifierProvider.notifier)
                            .sendOTP(selectedOtpMethod.value!.toLowerCase());

                        // ⭐ CLOSE LOADING
                        if (context.mounted) Navigator.of(context).pop();

                        // ✅ STEP 3: CHANGE UI STATE (SAFE NOW)
                        isOtpSent.value = true;
                        secondsLeft.value = 300;
                        isTimerRunning.value = true;

                        otpTimer.value = Timer.periodic(
                          const Duration(seconds: 1),
                          (timer) {
                            if (secondsLeft.value == 0) {
                              timer.cancel();
                              isTimerRunning.value = false;
                            } else {
                              secondsLeft.value--;
                            }
                          },
                        );

                        final method = selectedOtpMethod.value!.toLowerCase();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              method == "whatsapp"
                                  ? "OTP sent to your WhatsApp"
                                  : "OTP sent to your email",
                            ),
                          ),
                        );
                      } catch (e) {
                        // ⭐ CLOSE LOADING
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        // ❌ DO NOT CHANGE UI STATE
                        otpTimer.value?.cancel();
                        isTimerRunning.value = false;
                        isOtpSent.value = false;

                        final error = e.toString().toLowerCase();

                        String message = "Login failed";

                        if (error.contains("invalid credentials")) {
                          message = "Invalid username or password";
                        } else if (error.contains("not authorized")) {
                          message = "You are not allowed to login as admin";
                        } else if (error.contains("user not found")) {
                          message = "User not found";
                        } else if (error.contains("connection") ||
                            error.contains("timeout") ||
                            error.contains("socketexception")) {
                          message =
                              "Cannot connect to server. Check your internet connection.";
                        }

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    }
                    // =========================
                    // STATE 2: VERIFY OTP
                    // =========================
                    else {
                      final otp =
                          otp1Controller.text +
                          otp2Controller.text +
                          otp3Controller.text +
                          otp4Controller.text;

                      if (otp.length != 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter 4-digit OTP"),
                          ),
                        );
                        return;
                      }

                      // ⭐ SHOW LOADING FOR OTP VERIFICATION TOO
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final success = await ref
                            .read(authNotifierProvider.notifier)
                            .verifyOTP(otp);

                        // ⭐ CLOSE LOADING
                        if (context.mounted) Navigator.of(context).pop();

                        if (!success) {
                          otp1Controller.clear();
                          otp2Controller.clear();
                          otp3Controller.clear();
                          otp4Controller.clear();
                          FocusScope.of(context).requestFocus(focus1);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Incorrect OTP. Please try again."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // ✅ LOGIN SUCCESS (CLEAR BACK STACK)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboard(),
                          ),
                          (route) => false, // 🔥 removes ALL previous routes
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Login successful!")),
                        );
                      } catch (e) {
                        // ⭐ CLOSE LOADING IF OPEN
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Failed to verify OTP. Check your internet connection.",
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isOtpSent.value ? 'Log in' : 'Get OTP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // SizedBox(
              //   width: double.infinity,
              //   height: 56,
              //   child: ElevatedButton(
              //     onPressed: () async {
              //       if (!isOtpSent.value) {
              //         // ✅ STEP 0: CHECK INTERNET FIRST
              //         final connectivityResult = await Connectivity()
              //             .checkConnectivity();

              //         if (connectivityResult == ConnectivityResult.none) {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //               content: Text(
              //                 "No internet connection. Please switch on mobile data or Wi-Fi.",
              //               ),
              //             ),
              //           );
              //           return; // ❌ STOP HERE
              //         }

              //         // STATE 1: GET OTP

              //         // ✅ 1. Validate inputs
              //         if (emailController.text.isEmpty ||
              //             passwordController.text.isEmpty) {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //               content: Text("Please enter email and password"),
              //             ),
              //           );
              //           return;
              //         }

              //         if (selectedOtpMethod.value == null) {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //               content: Text("Please select an OTP method"),
              //             ),
              //           );
              //           return;
              //         }

              //         // ⭐ SHOW LOADING
              //         showDialog(
              //           context: context,
              //           barrierDismissible: false,
              //           builder: (_) =>
              //               const Center(child: CircularProgressIndicator()),
              //         );

              //         try {
              //           // Step 1: Login owner
              //           await ref
              //               .read(authNotifierProvider.notifier)
              //               .loginOwner(
              //                 emailController.text.trim(),
              //                 passwordController.text.trim(),
              //               );

              //           // Step 2: Send OTP
              //           await ref
              //               .read(authNotifierProvider.notifier)
              //               .sendOTP(selectedOtpMethod.value!.toLowerCase());

              //           // ⭐ CLOSE LOADING
              //           if (context.mounted) Navigator.of(context).pop();
              //           if (!context.mounted) return;

              //           // ✅ SHOW OTP UI (THIS WILL NOW STICK)
              //           isOtpSent.value = true;

              //           // Start timer
              //           secondsLeft.value = 300;
              //           isTimerRunning.value = true;

              //           otpTimer.value = Timer.periodic(
              //             const Duration(seconds: 1),
              //             (timer) {
              //               if (secondsLeft.value == 0) {
              //                 timer.cancel();
              //                 isTimerRunning.value = false;
              //               } else {
              //                 secondsLeft.value--;
              //               }
              //             },
              //           );

              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //               content: Text("OTP sent to your email"),
              //             ),
              //           );
              //         } catch (e) {
              //           // ⭐ CLOSE LOADING ON ERROR
              //           if (context.mounted) Navigator.of(context).pop();

              //           // Reset ONLY on login failure
              //           otpTimer.value?.cancel();
              //           isTimerRunning.value = false;
              //           isOtpSent.value = false;

              //           final msg = e.toString().toLowerCase();

              //           if (msg.contains("wrong password")) {
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               const SnackBar(content: Text("Incorrect password")),
              //             );
              //           } else if (msg.contains("user not found")) {
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               const SnackBar(
              //                 content: Text("Username does not exist"),
              //               ),
              //             );
              //           } else {
              //             ScaffoldMessenger.of(
              //               context,
              //             ).showSnackBar(SnackBar(content: Text(msg)));
              //           }
              //         }
              //       } else {
              //         // STATE 2: VERIFY OTP
              //         final otp =
              //             otp1Controller.text +
              //             otp2Controller.text +
              //             otp3Controller.text +
              //             otp4Controller.text;

              //         if (otp.length == 4) {
              //           final success = await ref
              //               .read(authNotifierProvider.notifier)
              //               .verifyOTP(otp);

              //           if (!success) {
              //             // ❌ WRONG OTP → DO NOT NAVIGATE

              //             otp1Controller.clear();
              //             otp2Controller.clear();
              //             otp3Controller.clear();
              //             otp4Controller.clear();
              //             FocusScope.of(context).requestFocus(focus1);

              //             ScaffoldMessenger.of(context).showSnackBar(
              //               const SnackBar(
              //                 content: Text("Incorrect OTP. Please try again."),
              //                 backgroundColor: Colors.red,
              //               ),
              //             );
              //             return;
              //           }

              //           // ✅ ONLY ON SUCCESS
              //           Navigator.pushReplacement(
              //             context,
              //             MaterialPageRoute(
              //               builder: (context) => AdminDashboard(),
              //             ),
              //           );

              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(content: Text("Login successful!")),
              //           );
              //         } else {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //               content: Text("Please enter 4-digit OTP"),
              //             ),
              //           );
              //         }
              //       }
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: primaryBlue,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(16),
              //       ),
              //       elevation: 0,
              //     ),
              //     child: Text(
              //       isOtpSent.value ? 'Log in' : 'Get OTP',
              //       style: const TextStyle(
              //         color: Colors.white,
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ),
              // ),
              kHeight20,

              // --- FORGOT PASSWORD (Only visible in State 1) ---
              if (!isOtpSent.value)
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot your password?',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: primaryBlue,
                      ),
                    ),
                  ),
                ),

              kHeight20,
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the gray OTP boxes
  Widget _buildOtpDigitBox(
    BuildContext context,
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
  ) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        focusNode: currentFocus,
        autofocus: false,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "", // Hides the "0/1" counter
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
