import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/core/constants.dart';
import 'package:shopx/presentation/auth/employee/employee_login_screen.dart';
import 'package:shopx/presentation/auth/owner/owner_login_screen.dart';
import 'package:shopx/presentation/auth/selection/widgets/selection_button.dart';

class SelectionScreen extends HookConsumerWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define colors based on the design
    const primaryBlue = Color(
      0xFF1976D2,
    ); // Adjust hex to match exact brand color
    final subtitleColor = Colors.grey[700];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [            
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT: Back Button
                  // InkWell(
                  //   // onTap: () => Navigator.of(context).pop(),
                  //   borderRadius: BorderRadius.circular(12),
                  //   child: Image.asset(
                  //     "assets/images/backbutton.png",
                  //     height: 35,
                  //     width: 35,
                  //     fit: BoxFit.cover,
                  //   ),
                  // ),

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

              // 3. Welcome Text Block
              const Text(
                'Welcome to Joy Brews!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              kHeight10,
              Text(
                'Select I am the owner or I am an\nemployee to begin',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: subtitleColor,
                  fontWeight: FontWeight.w800,
                ),
              ),

              kHeight30,

              Center(
                child: SizedBox(
                  height: 200,
                  child: Image.asset(
                    "assets/images/Group 16.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              kHeight40,

              // 5. "I am the owner" Button
              SelectionButton(
                title: 'I am the owner',
                icon: Icons.person,
                color: primaryBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OwnerLoginScreen(),
                    ),
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Or',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 6. "I am employed" Button
              SelectionButton(
                title: 'I am employed',
                icon: Icons.groups, // Using groups to represent hierarchy/team
                color: primaryBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeLoginScreen(),
                    ),
                  );
                },
              ),

              kHeight40,

              // 7. Footer - Create Account
              // Column(
              //   children: [
              //     Text(
              //       "You don't have an account?",
              //       style: TextStyle(color: subtitleColor, fontSize: 16),
              //     ),
              //     const SizedBox(height: 4),
              //     InkWell(
              //       onTap: () {
              //         // Navigate to Sign Up
              //       },
              //       child: const Text(
              //         'Create a new account',
              //         style: TextStyle(
              //           color: primaryBlue,
              //           fontSize: 16,
              //           fontWeight: FontWeight.bold,
              //           decoration: TextDecoration.underline,
              //           decorationColor: primaryBlue,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),

              kHeight20,
            ],
          ),
        ),
      ),
    );
  }
}
