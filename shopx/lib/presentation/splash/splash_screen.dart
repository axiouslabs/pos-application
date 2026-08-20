// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:shopx/application/auth/auth_notifier.dart';
// import 'package:shopx/presentation/auth/selection/selection_screen.dart';
// import 'package:shopx/presentation/dashboard/admin/admin_dashboard.dart';
// import 'package:shopx/presentation/dashboard/user/user_dashboard.dart';

// class SplashScreen extends ConsumerStatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   ConsumerState<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends ConsumerState<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();

//     Future.delayed(const Duration(milliseconds: 500), () {
//       final authState = ref.read(authNotifierProvider);

//       if (authState.user == null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const SelectionScreen()),
//         );
//         return;
//       }

//       if (authState.user!.userType == "admin") {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const AdminDashboard()),
//         );
//       } else {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const UserDashboard()),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: Color(0xFF1976D2),
//       body: Center(
//         child: Text(
//           'Sellops',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 36,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1976D2),
      body: Center(
        child: Text(
          'Sellops',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
