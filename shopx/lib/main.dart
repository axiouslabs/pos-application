import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/application/auth/auth_state.dart';
import 'package:shopx/application/connectivity/app_bootstrap_provider.dart';
import 'package:shopx/application/connectivity/connectivity_provider.dart';
import 'package:shopx/application/dashboard/admin_dashboard_notifier.dart';
import 'package:shopx/presentation/auth/selection/selection_screen.dart';
import 'package:shopx/presentation/dashboard/admin/admin_dashboard.dart';
import 'package:shopx/presentation/dashboard/user/user_dashboard.dart';
import 'package:shopx/presentation/splash/splash_screen.dart';
import 'package:shopx/widget/internet/no_internet_screen.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     // 🔥 ADD THIS LINE: Initialize the auth retry listener
    ref.read(authRetryOnConnectivityProvider);
    final authState = ref.watch(authNotifierProvider);
    // final connectivity = ref.watch(connectivityProvider);
    final bootstrap = ref.watch(appBootstrapProvider);



  Widget home;

if (authState.isInitializing) {
  home = const SplashScreen(); // 🔒 ONLY HERE
} else {
  switch (bootstrap) {
    case AppBootstrapState.offline:
      home = const NoInternetScreen();
      break;

    case AppBootstrapState.ready:
      if (authState.isAuthenticated) {
        home = authState.user!.userType == "admin"
            ? const AdminDashboard()
            : const UserDashboard();
      } else {
        home = const SelectionScreen();
      }
      break;
  }
}


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sellops',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),

      // Register all named routes used in the app
      routes: {"/login": (_) => const SelectionScreen()},

      home: home,

      //     Builder(
      //   builder: (context) {
      //     return Consumer(
      //       builder: (context, ref, _) {
      //         final authState = ref.watch(authNotifierProvider);

      //         if (authState.isLoading) {
      //           return const Scaffold(
      //             body: Center(child: CircularProgressIndicator()),
      //           );
      //         }

      //         // If NOT logged in → show SelectionScreen
      //         if (authState.user == null && authState.token == null) {
      //           return const SelectionScreen();
      //         }

      //         final user = authState.user;

      //         if (user?.userType == "admin") {

      //           return const AdminDashboard();
      //         } else {
      //           return const UserDashboard();
      //         }
      //       },
      //     );

      //   },
      // ),
    );
  }
}
